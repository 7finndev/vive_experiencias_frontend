import 'dart:typed_data'; // Para manejar bytes de imagen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- NECESARIO
import 'package:image_picker/image_picker.dart'; // <--- USAMOS EL PAQUETE ESTÁNDAR
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/utils/image_helper.dart';
import 'package:uuid/uuid.dart'; // Para generar nombres de archivo
import 'package:vive_core/features/home/data/models/event_model.dart';
import 'package:vive_core/features/home/data/repositories/event_repository.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';

// LISTA CURADA DE FUENTES DE GOOGLE (Para no saturar al usuario)
const List<String> _googleFontsList = [
  'Roboto',
  'Open Sans',
  'Lato',
  'Montserrat',
  'Oswald',
  'Raleway',
  'Poppins',
  'Ubuntu',
  'Merriweather',
  'Playfair Display',
  'Nunito',
  'Rubik',
  'Work Sans',
  'Quicksand',
  'Karla',
  'Lobster',
  'Pacifico',
  'Dancing Script',
  'Shadows Into Light',
  'Indie Flower',
];

const Map<String, String> _statusMap = {
  'upcoming': '🔜 Próximamente',
  'active': '🟢 Activo',
  'archived': '🔴 Finalizado',
};

class EventFormScreen extends ConsumerStatefulWidget {
  final EventModel? eventToEdit;
  const EventFormScreen({super.key, this.eventToEdit});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _themeColorController = TextEditingController(text: '#FF5733');
  final _navColorController = TextEditingController(text: '#FFFFFF');
  final _bgColorController = TextEditingController(text: '#F5F5F5');
  final _textColorController = TextEditingController(text: '#000000');

  // YA NO USAMOS CONTROLADOR PARA FUENTE, USAMOS VARIABLE DE ESTADO
  String _selectedFont = 'Roboto';

  // CONTROLADORES DE URL (Para mostrar lo que hay guardado)
  final _logoUrlController = TextEditingController();
  final _bgImageUrlController = TextEditingController();

  // VARIABLES PARA IMÁGENES NUEVAS (EN MEMORIA)
  Uint8List? _newLogoBytes;
  Uint8List? _newBgBytes;

  final _priceController = TextEditingController(text: '0.0');

  String _selectedType = 'gastronomic';
  String _selectedStatus = 'upcoming';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _nameController.text = e.name;
      _themeColorController.text = e.themeColorHex;
      _bgColorController.text = e.bgColorHex ?? '#F5F5F5';
      _navColorController.text = e.navColorHex ?? '#FFFFFF';
      _textColorController.text = e.textColorHex ?? '#000000';
      _priceController.text = e.basePrice?.toString() ?? '0.0';

      _logoUrlController.text = e.logoUrl ?? '';
      _bgImageUrlController.text = e.bgImageUrl ?? '';

      // Cargar fuente guardada o defecto
      if (_googleFontsList.contains(e.fontFamily)) {
        _selectedFont = e.fontFamily ?? 'Roboto';
      } else {
        _selectedFont = 'Roboto';
      }

      // Normalización de Estado
      String incomingStatus = e.status.toLowerCase().trim();
      if (_statusMap.containsKey(incomingStatus)) {
        _selectedStatus = incomingStatus;
      } else {
        _selectedStatus = incomingStatus == 'activo' ? 'active' : 'upcoming';
      }

      // Normalización de Tipo
      const validTypes = ['gastronomic', 'drinks', 'shopping', 'menu'];
      _selectedType = validTypes.contains(e.type) ? e.type : 'gastronomic';

      _startDate = e.startDate;
      _endDate = e.endDate;
    }
  }

  // --- SELECCIÓN DE IMÁGENES (Clean Architecture) ---
  Future<void> _pickImage(bool isLogo) async {
    // Definimos reglas estrictas según si es Logo o Fondo
    // Logo: Pequeño (300x300), Calidad Media
    // Fondo: Grande (1280x720), Calidad Alta

    final compressedBytes = await ImageHelper.pickAndCompress(
      source: ImageSource.gallery,
      maxWidth: isLogo ? 300 : 1280,
      maxHeight: isLogo ? 300 : 720,
      quality: isLogo ? 85 : 75, // Los fondos pueden comprimirse más
    );

    if (compressedBytes != null) {
      setState(() {
        if (isLogo) {
          _newLogoBytes = compressedBytes;
        } else {
          _newBgBytes = compressedBytes;
        }
      });
    }
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.eventToEdit != null ? 'Personalizar Evento' : 'Nuevo Evento',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- SECCIÓN 1: DATOS ---
              const Text(
                'Información General',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Evento',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'gastronomic',
                          child: Text('🥘 Tapas'),
                        ),
                        DropdownMenuItem(
                          value: 'menu',
                          child: Text('🍽️ Menú'),
                        ),
                        DropdownMenuItem(
                          value: 'drinks',
                          child: Text('🍹 Cócteles'),
                        ),
                        DropdownMenuItem(
                          value: 'shopping',
                          child: Text('🛍️ Tiendas'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _statusMap.containsKey(_selectedStatus)
                          ? _selectedStatus
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusMap.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- SECCIÓN 2: IMÁGENES (Clean) ---
              const Text(
                'Imágenes del Evento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),

              // LOGO
              _buildImagePickerZone(
                "Logotipo (Icono)",
                true,
                _newLogoBytes,
                _logoUrlController.text,
              ),
              const SizedBox(height: 20),
              // FONDO
              _buildImagePickerZone(
                "Fondo / Cartel",
                false,
                _newBgBytes,
                _bgImageUrlController.text,
              ),

              const SizedBox(height: 32),

              // --- SECCIÓN 3: DISEÑO Y FUENTES ---
              const Text(
                'Diseño y Branding',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _ColorInput(
                label: 'Color Principal',
                controller: _themeColorController,
              ),
              const SizedBox(height: 10),
              _ColorInput(label: 'Color Fondo', controller: _bgColorController),
              const SizedBox(height: 10),
              _ColorInput(
                label: 'Color Texto',
                controller: _textColorController,
              ),
              const SizedBox(height: 16),

              // >>>>> EL DROPDOWN DE FUENTES <<<<<
              const Text(
                "Tipografía",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedFont,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _googleFontsList.map((font) {
                  return DropdownMenuItem(
                    value: font,
                    child: Text(
                      font,
                      style: GoogleFonts.getFont(font),
                    ), // Previsualización
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedFont = val!),
              ),
              // Preview del nombre con la fuente
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _nameController.text.isEmpty
                      ? "Ejemplo de Título"
                      : _nameController.text,
                  style: GoogleFonts.getFont(
                    _selectedFont,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // --- SECCIÓN 4: FECHAS ---
              const Text(
                'Configuración',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text('Inicio: ${_formatDate(_startDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(true),
              ),
              ListTile(
                title: Text('Fin: ${_formatDate(_endDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(false),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Base',
                        border: OutlineInputBorder(),
                        suffixText: '€',
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Precio oreintativo para listados",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isLoading ? 'Guardando...' : 'GUARDAR EVENTO'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET AUXILIAR PARA SELECCIONAR IMAGEN
  /*
  Widget _buildImagePickerZone(String title, bool isLogo, Uint8List? newBytes, String currentUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: newBytes != null
              ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(newBytes, fit: BoxFit.cover))
              : (currentUrl.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(currentUrl, fit: BoxFit.cover))
                  : Center(child: Icon(isLogo ? Icons.emoji_events : Icons.image, size: 40, color: Colors.grey))),
        ),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          onPressed: () => _pickImage(isLogo),
          icon: const Icon(Icons.upload_file, size: 18),
          label: Text(newBytes != null ? "Cambiar Selección" : "Seleccionar Imagen"),
        ),
      ],
    );
  }
  */
  // WIDGET AUXILIAR PARA SELECCIONAR IMAGEN
  Widget _buildImagePickerZone(
    String title,
    bool isLogo,
    Uint8List? newBytes,
    String currentUrl,
  ) {
    // Texto de ayuda dinámico según el tipo
    final helperText = isLogo
        ? "💡 Recomendado: Logo cuadrado (300x300 px), Calidad 80%."
        : "💡 Recomendado: Fondo panorámico (1280x720 px), Calidad 75%.";

    // Lógica de ajuste: Logo se ve entero (contain), Fondo rellena el hueco (cover)
    final BoxFit fitType = isLogo ? BoxFit.contain : BoxFit.cover;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: newBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  // Muestra la imagen nueva que acabamos de seleccionar
                  child: Image.memory(newBytes, fit: fitType),
                )
              : (currentUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        // Muestra la imagen que viene de la base de datos (si existe)
                        child: Image.network(
                          currentUrl,
                          fit: fitType,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          isLogo ? Icons.emoji_events : Icons.image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )),
        ),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          onPressed: () => _pickImage(isLogo),
          icon: const Icon(Icons.upload_file, size: 18),
          label: Text(
            newBytes != null ? "Cambiar Selección" : "Seleccionar Imagen",
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _ColorInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hexToColor(controller.text),
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String code) {
    try {
      if (code.isEmpty) return Colors.transparent;
      String clean = code.replaceAll('#', '');
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse(clean, radix: 16));
    } catch (e) {
      return Colors.white;
    }
  }

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'), // <--- FUERZA ESPAÑOL (Lunes primero)
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black, // Color del selector
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    // --- VALIDACIÓN DE FECHAS ---
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ La fecha de fin no puede ser anterior al inicio."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(eventRepositoryProvider);
      final generatedSlug = _generateSlug(_nameController.text);
      final price = double.tryParse(_priceController.text) ?? 0.0;

      // 🔥 1. OBTENER LA CIUDAD REAL DEL ADMIN AUTENTICADO
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final profile = await supabase
          .from('profiles')
          .select('city_id')
          .eq('id', user!.id)
          .single();
      final adminCityId = profile['city_id'];

      String? finalLogoUrl = _logoUrlController.text.isNotEmpty
          ? _logoUrlController.text
          : null;
      String? finalBgUrl = _bgImageUrlController.text.isNotEmpty
          ? _bgImageUrlController.text
          : null;

      // 2. GESTIÓN LOGO
      if (_newLogoBytes != null) {
        if (widget.eventToEdit != null && widget.eventToEdit!.logoUrl != null) {
          await repo.deleteEventImage(widget.eventToEdit!.logoUrl!);
        }
        final name = 'logo_${const Uuid().v4()}.jpg';
        finalLogoUrl = await repo.uploadEventImage(name, _newLogoBytes!);
      }

      // 3. GESTIÓN FONDO
      if (_newBgBytes != null) {
        if (widget.eventToEdit != null &&
            widget.eventToEdit!.bgImageUrl != null) {
          await repo.deleteEventImage(widget.eventToEdit!.bgImageUrl!);
        }
        final name = 'bg_${const Uuid().v4()}.jpg';
        finalBgUrl = await repo.uploadEventImage(name, _newBgBytes!);
      }

      // 4. CONSTRUCCIÓN BLINDADA DEL EVENTO
      final newEvent = EventModel(
        id: widget.eventToEdit?.id ?? 0,
        cityId: adminCityId, // 🔥 INYECCIÓN DE SEGURIDAD B2B
        name: _nameController.text,
        slug: generatedSlug,
        themeColorHex: _themeColorController.text,
        bgColorHex: _bgColorController.text,
        navColorHex: _navColorController.text,
        textColorHex: _textColorController.text,
        fontFamily: _selectedFont,
        type: _selectedType,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        basePrice: price,
        logoUrl: finalLogoUrl,
        bgImageUrl: finalBgUrl,
      );

      if (widget.eventToEdit == null) {
        await repo.createEvent(newEvent);
      } else {
        await repo.updateEvent(newEvent);
      }

      if (mounted) {
        // Usa ref.invalidate para forzar la recarga de los proveedores afectados
        ref.invalidate(
          adminEventsListProvider,
        ); // 🔥 Corregido al provider correcto        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ Evento Guardado")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
