import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/utils/image_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/home/data/repositories/establishment_repository.dart';
import 'package:vive_core/core/utils/geocoding_helper.dart';

class EstablishmentFormScreen extends ConsumerStatefulWidget {
  final EstablishmentModel? establishmentToEdit;
  const EstablishmentFormScreen({super.key, this.establishmentToEdit});

  @override
  ConsumerState<EstablishmentFormScreen> createState() =>
      _EstablishmentFormScreenState();
}

class _EstablishmentFormScreenState
    extends ConsumerState<EstablishmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isGeocoding = false;

  // Controladores Generales
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController(); // Teléfono Público
  final _scheduleController = TextEditingController();
  final _imageController = TextEditingController();

  // Controladores Gerencia (NUEVOS)
  final _ownerController = TextEditingController(); // Nombre Gerente
  final _ownerPhoneController = TextEditingController(); // Teléfono Gerente
  final _ownerEmailController = TextEditingController(); // Email Gerente

  // Controladores Redes Sociales
  final _webCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();

  // GPS
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final MapController _mapController = MapController();

  // PIN
  final _pinController = TextEditingController();

  bool _isPartner = true;
  bool _isActive = true;
  bool _useImageUpload = true;

  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.establishmentToEdit != null) {
      final e = widget.establishmentToEdit!;
      _nameController.text = e.name;
      _addressController.text = e.address ?? '';
      _descController.text = e.description ?? '';
      _phoneController.text = e.phone ?? ''; // Público
      _scheduleController.text = e.schedule ?? '';
      _imageController.text = e.coverImage ?? '';

      // Gerencia
      _ownerController.text = e.ownerName ?? '';
      _ownerPhoneController.text = e.ownerPhone ?? ''; // Privado
      _ownerEmailController.text = e.ownerEmail ?? ''; // Privado

      // Redes
      _webCtrl.text = e.website ?? '';
      _facebookCtrl.text = e.facebook ?? '';
      _instagramCtrl.text = e.instagram ?? '';
      _tiktokCtrl.text = e.socialTiktok ?? '';

      _isPartner = e.isPartner;
      _isActive = e.isActive;
      _pinController.text = e.waiterPin ?? '';

      if (e.latitude != null) _latController.text = e.latitude.toString();
      if (e.longitude != null) _lngController.text = e.longitude.toString();
    }
  }

  @override
  void dispose() {
    // Limpieza de controladores
    _nameController.dispose();
    _addressController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _scheduleController.dispose();
    _imageController.dispose();
    _ownerController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _webCtrl.dispose();
    _facebookCtrl.dispose();
    _instagramCtrl.dispose();
    _tiktokCtrl.dispose();
    _pinController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _findCoordinates() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escribe una dirección primero (Ej: Calle Sol 4, Nerja)")),
      );
      return;
    }
    setState(() => _isGeocoding = true);

    String query = _addressController.text.trim();
    // 🔥 CORRECCIÓN: Solo añadimos España para no confundir al GPS con la provincia
    if (!query.toLowerCase().contains("españa")) {
      query = "$query, España";
    }

    final coords = await GeocodingHelper.getCoordinatesFromAddress(query);

    if (mounted) {
      setState(() => _isGeocoding = false);
      if (coords != null) {
        final lat = coords[0];
        final lng = coords[1];
        _latController.text = lat.toString();
        _lngController.text = lng.toString();
        _mapController.move(LatLng(lat, lng), 17.0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📍 Ubicación encontrada"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ No encontrada. Revisa la ciudad.")));
      }
    }
  }

  Future<void> _pickImage() async {
    final bytes = await ImageHelper.pickAndCompress(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 768,
      quality: 80,
    );
    if (bytes != null) {
      setState(() => _selectedImageBytes = bytes);
    }
  }

  // WIDGET AUXILIAR PARA INPUTS CON ICONO
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.establishmentToEdit != null ? "Editar Socio" : "Nuevo Socio",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- DATOS BÁSICOS ---
              const Text(
                "🏢 Datos del Establecimiento",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre Comercial *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _phoneController,
                label: "Teléfono Público (Reservas)",
                icon: Icons.phone,
                type: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              // 🔥 CAMPO AÑADIDO: Horario
              TextFormField(
                controller: _scheduleController,
                decoration: const InputDecoration(
                  labelText: "Horarios de Apertura (Texto libre)",
                  hintText: "Ej: L a J: 12-16h / V y S: 12-23h / D: Cerrado",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time, color: Colors.grey),
                ),
                maxLines: 2, // Le damos 2 líneas para que se pueda explayar
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 25),

              // --- DIRECCIÓN Y MAPA ---
              const Text(
                "📍 Ubicación",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: "Dirección",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isGeocoding ? null : _findCoordinates,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          padding: EdgeInsets.zero,
                        ),
                        child: _isGeocoding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search),
                                  Text("GPS", style: TextStyle(fontSize: 10)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _latController,
                      label: "Latitud",
                      icon: Icons.north,
                      type: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _lngController,
                      label: "Longitud",
                      icon: Icons.east,
                      type: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _latController.text.isNotEmpty
                          ? LatLng(
                              double.parse(_latController.text),
                              double.parse(_lngController.text),
                            )
                          : const LatLng(36.741, -4.093),
                      initialZoom: 15.0,
                      // Al toca, buscamos la calle
                      onTap: (tapPosition, point) async {
                        //.-Actualizamos visualmente las coordenadas
                        setState(() {
                          _latController.text = point.latitude.toStringAsFixed(6);
                          _lngController.text = point.longitude.toStringAsFixed(6);
                          _isGeocoding = true; //Spinner del botón
                        });
                        //.-Pedimos la dirección al servidor
                        final foundAddress = await GeocodingHelper.getAddressFromCoordinates(
                          point.latitude, 
                          point.longitude
                        );
                        //.-Si encontramos dirección, actualizamos la caja del texto
                        if(mounted){
                          setState(() {
                            _isGeocoding = false; //Quitamos spinner
                            if(foundAddress != null && foundAddress.isNotEmpty) {
                              _addressController.text = foundAddress;

                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("📍 Dirección detectada: $foundAddress"),
                                  duration: const Duration(milliseconds: 1500),
                                  behavior: SnackBarBehavior.floating,
                                )
                              );
                            }
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.torredelmar.admin',
                      ),
                      MarkerLayer(
                        markers: [
                          if (_latController.text.isNotEmpty)
                            Marker(
                              point: LatLng(
                                double.tryParse(_latController.text) ?? 0,
                                double.tryParse(_lngController.text) ?? 0,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- REDES SOCIALES ---
              const Text(
                "🌍 Redes Sociales",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _webCtrl,
                label: "Web Oficial",
                icon: Icons.language,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _facebookCtrl,
                      label: "Facebook",
                      icon: Icons.facebook,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _instagramCtrl,
                      label: "Instagram",
                      icon: Icons.camera_alt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _tiktokCtrl,
                label: "TikTok (URL)",
                icon: Icons.music_note,
              ),

              const SizedBox(height: 30),

              // --- DATOS GERENCIA ---
              const Text(
                "👨‍💼 Datos Privados (Gerencia)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _ownerController,
                label: "Nombre Gerente",
                icon: Icons.person,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ownerPhoneController,
                      label: "Móvil Gerente",
                      icon: Icons.phone_iphone,
                      type: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _ownerEmailController,
                      label: "Email Gerente",
                      icon: Icons.email,
                      type: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- SEGURIDAD (PIN) ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "🛡️ Seguridad (PIN Camarero)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pinController,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "PIN (4 dígitos)",
                              filled: true,
                              fillColor: Colors.white,
                              border: const OutlineInputBorder(),
                              counterText: "",
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.orange,
                                ),
                                onPressed: () {
                                  final randomPin =
                                      (1000 +
                                              DateTime.now()
                                                      .millisecondsSinceEpoch %
                                                  9000)
                                          .toString();
                                  setState(
                                    () => _pinController.text = randomPin,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text(
                            "Código manual para validar votos cuando falla el GPS.",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- ESTADO Y SOCIO ---
              const Text(
                "⚙️ Estado y Configuración",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    //1.-Switch: Socio ACET
                    SwitchListTile(
                      title: const Text(
                        "Participación Activa",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        "Activa este switch para que el local aparezca en la ruta.",
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _isPartner,
                      activeThumbColor: Colors.blue,
                      secondary: const Icon(Icons.verified_user, color: Colors.blue),
                      onChanged: (val) => setState(() => _isPartner = val),
                    ),
                    
                    const Divider(height: 1),

                    //2.-Switch: Acivo en el evento.
                    SwitchListTile(
                      title: const Text(
                        "Activo / Disponible",
                        style: TextStyle(fontWeight: FontWeight.bold),

                      ),
                      subtitle: const Text(
                        "Desmarca esta casilla si el local cierra por vacaciones o deja de participar. Desaparecerá del mapa y no se podrá escanear.",
                        style: TextStyle(fontSize: 12),

                      ),
                      value: _isActive,
                      activeThumbColor: Colors.green,
                      secondary: Icon(
                        Icons.store,
                        color: _isActive ? Colors.green : Colors.grey
                      ),
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              
              // --- IMAGEN ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Foto de Portada',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _useImageUpload,
                    onChanged: (v) => setState(() => _useImageUpload = v),
                  ),
                ],
              ),
              if (_useImageUpload)
                Column(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (_imageController.text.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      _imageController.text,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const Icon(Icons.broken_image),
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey,
                                  )),
                    ),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text("Seleccionar Imagen"),
                    ),
                  ],
                )
              else
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(
                    labelText: "URL Manual",
                    border: OutlineInputBorder(),
                  ),
                ),

              const SizedBox(height: 40),

              // BOTÓN GUARDAR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(_isLoading ? "GUARDANDO..." : "GUARDAR DATOS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(establishmentRepositoryProvider);

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final profile = await supabase.from('profiles').select('city_id').eq('id', user!.id).single();
      final adminCityId = profile['city_id'];

      String? finalImageUrl = _imageController.text.isNotEmpty
          ? _imageController.text
          : null;

      if (_useImageUpload && _selectedImageBytes != null) {
        if (widget.establishmentToEdit != null &&
            widget.establishmentToEdit!.coverImage != null) {
          await repo.deleteEstablishmentImage(
            widget.establishmentToEdit!.coverImage!,
          );
        }
        final fileName = '${const Uuid().v4()}.jpg';
        finalImageUrl = await repo.uploadEstablishmentImage(
          fileName,
          _selectedImageBytes!,
        );
      }

      double? lat;
      double? lng;
      if (_latController.text.isNotEmpty) {
        lat = double.tryParse(_latController.text.replaceAll(',', '.'));
      }
      if (_lngController.text.isNotEmpty) {
        lng = double.tryParse(_lngController.text.replaceAll(',', '.'));
      }

      final establishment = EstablishmentModel(
        id: widget.establishmentToEdit?.id ?? 0,
        cityId: adminCityId, // Asignamos la ciudad del admin
        name: _nameController.text,
        address: _addressController.text,
        description: _descController.text,
        phone: _phoneController.text, // Público
        schedule: _scheduleController.text,
        coverImage: finalImageUrl,
        isPartner: _isPartner,
        isActive: _isActive,
        qrUuid: widget.establishmentToEdit?.qrUuid ?? const Uuid().v4(),
        latitude: lat,
        longitude: lng,
        // CAMPOS NUEVOS
        ownerName: _ownerController.text,
        ownerPhone: _ownerPhoneController.text, // Privado
        ownerEmail: _ownerEmailController.text, // Privado
        website: _webCtrl.text,
        facebook: _facebookCtrl.text,
        instagram: _instagramCtrl.text,
        socialTiktok: _tiktokCtrl.text,
        waiterPin: _pinController.text.trim().isEmpty
            ? null
            : _pinController.text.trim(),
      );

      if (widget.establishmentToEdit == null) {
        await repo.createEstablishment(establishment);
      } else {
        await repo.updateEstablishment(establishment);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Guardado correctamente")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
