import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vive_core/core/utils/geocoding_helper.dart';
import 'package:vive_core/core/utils/image_helper.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/features/admin/data/superadmin_repository.dart';

class SuperadminCityFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? cityToEdit;
  const SuperadminCityFormScreen({super.key, this.cityToEdit});

  @override
  ConsumerState<SuperadminCityFormScreen> createState() => _SuperadminCityFormScreenState();
}

class _SuperadminCityFormScreenState extends ConsumerState<SuperadminCityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _colorCtrl = TextEditingController(text: '#121212');
  
  // 🔥 NUEVOS CONTROLADORES PARA LA MARCA BLANCA
  final _orgNameCtrl = TextEditingController();
  final _webCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();
  final _igCtrl = TextEditingController();
  final _xCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;
  Uint8List? _newLogoBytes;
  String _currentLogoUrl = '';

  @override
  void initState() {
    super.initState();
    if (widget.cityToEdit != null) {
      _nameCtrl.text = widget.cityToEdit!['name'] ?? '';
      _isActive = widget.cityToEdit!['is_active'] ?? true;
      
      final config = widget.cityToEdit!['app_config'];
      if (config != null) {
        final Map<String, dynamic> cfg = (config is List && config.isNotEmpty) ? config[0] : (config is Map ? config : {});
        
        _colorCtrl.text = cfg['primary_color'] ?? '#121212';
        _currentLogoUrl = cfg['logo_url'] ?? '';
        
        // Rellenamos los datos extra
        _orgNameCtrl.text = cfg['org_name'] ?? '';
        _webCtrl.text = cfg['website_url'] ?? '';
        _emailCtrl.text = cfg['contact_email'] ?? '';
        _fbCtrl.text = cfg['facebook_url'] ?? '';
        _igCtrl.text = cfg['instagram_url'] ?? '';
        _xCtrl.text = cfg['x_url'] ?? '';
        _tiktokCtrl.text = cfg['tiktok_url'] ?? '';
      }
    }
  }

  Future<void> _pickLogo() async {
    final bytes = await ImageHelper.pickAndCompress(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, quality: 85);
    if (bytes != null) setState(() => _newLogoBytes = bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newLogoBytes == null && _currentLogoUrl.isEmpty && widget.cityToEdit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Se requiere un logo corporativo.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(superadminRepositoryProvider);
      
      final cityName = _nameCtrl.text.trim();

      // 🔥 1. GEOLOCALIZACIÓN AUTOMÁTICA DE LA FRANQUICIA
      double? cityLat;
      double? cityLng;
      
      // Buscamos las coordenadas. Le añadimos "España" para evitar que el GPS se vaya a otro continente.
      final coords = await GeocodingHelper.getCoordinatesFromAddress("$cityName, España");
      if (coords != null) {
        cityLat = coords[0];
        cityLng = coords[1];
        Logger.info("Coordenadas de $cityName encontradas: $cityLat, $cityLng", "SUPERADMIN");
      } else {
        // Si no las encuentra (ej: ciudad inventada), podemos dejar null o poner unas por defecto.
        Logger.warning("No se encontraron coordenadas para $cityName", "SUPERADMIN");
      }

      // 2. Preparamos los datos extra de configuración
      final extraConfig = {
        'org_name': _orgNameCtrl.text.trim(),
        'website_url': _webCtrl.text.trim(),
        'contact_email': _emailCtrl.text.trim(),
        'facebook_url': _fbCtrl.text.trim(),
        'instagram_url': _igCtrl.text.trim(),
        'x_url': _xCtrl.text.trim(),
        'tiktok_url': _tiktokCtrl.text.trim(),
        // 🔥 3. INYECTAMOS LAS COORDENADAS AQUÍ (Se guardarán en app_config)
        'gps_lat': cityLat,
        'gps_lng': cityLng,
      };

      if (widget.cityToEdit == null) {
        await repo.createCityWithBranding(
          name: cityName,
          isActive: _isActive,
          primaryColor: _colorCtrl.text.trim(),
          logoBytes: _newLogoBytes!,
          configData: extraConfig, // 👈 Pasamos el configData
        );
      } else {
        await repo.updateCity(
          cityId: widget.cityToEdit!['id'],
          name: cityName,
          isActive: _isActive,
          primaryColor: _colorCtrl.text.trim(),
          newLogoBytes: _newLogoBytes,
          configData: extraConfig, // 👈 Pasamos el configData
        );
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Franquicia guardada correctamente.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      Logger.error("Error guardando franquicia: $e", "SUPERADMIN");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cityToEdit != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: Text(isEditing ? 'Editar Franquicia' : 'Alta de Franquicia'), backgroundColor: Colors.white),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Datos Básicos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del Municipio / Marca', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _colorCtrl, decoration: const InputDecoration(labelText: 'Color Principal (Hexadecimal)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty || !v.startsWith('#') ? 'Usa formato #RRGGBB' : null),
                  const SizedBox(height: 16),
                  SwitchListTile(title: const Text("Estado Operativo"), value: _isActive, activeThumbColor: Colors.green, onChanged: (val) => setState(() => _isActive = val)),
                  const SizedBox(height: 24),
                  
                  const Text("Logotipo Corporativo", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity, height: 150,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: _newLogoBytes != null ? Image.memory(_newLogoBytes!, fit: BoxFit.contain) : (_currentLogoUrl.isNotEmpty ? Image.network(_currentLogoUrl, fit: BoxFit.contain) : const Center(child: Icon(Icons.image, size: 50))),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: const Icon(Icons.upload), label: const Text("Seleccionar Imagen"), onPressed: _isLoading ? null : _pickLogo)),
                  
                  const SizedBox(height: 40),
                  
                  // 🔥 SECCIÓN DE MARCA BLANCA
                  const Text("Marca Blanca: Redes y Contacto", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text("Estos datos se mostrarán en el menú lateral de los turistas.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(controller: _orgNameCtrl, decoration: const InputDecoration(labelText: 'Nombre Entidad (Ej. Ayuntamiento de Nerja)', prefixIcon: Icon(Icons.account_balance), border: OutlineInputBorder())),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: TextFormField(controller: _webCtrl, decoration: const InputDecoration(labelText: 'Web Oficial (https://...)', prefixIcon: Icon(Icons.language), border: OutlineInputBorder()))),
                              const SizedBox(width: 16),
                              Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Público', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()))),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              Expanded(child: TextFormField(controller: _fbCtrl, decoration: const InputDecoration(labelText: 'Facebook URL', prefixIcon: Icon(Icons.facebook), border: OutlineInputBorder()))),
                              const SizedBox(width: 16),
                              Expanded(child: TextFormField(controller: _igCtrl, decoration: const InputDecoration(labelText: 'Instagram URL', prefixIcon: Icon(Icons.camera_alt), border: OutlineInputBorder()))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: TextFormField(controller: _xCtrl, decoration: const InputDecoration(labelText: 'X (Twitter) URL', prefixIcon: Icon(Icons.alternate_email), border: OutlineInputBorder()))),
                              const SizedBox(width: 16),
                              Expanded(child: TextFormField(controller: _tiktokCtrl, decoration: const InputDecoration(labelText: 'TikTok URL', prefixIcon: Icon(Icons.music_note), border: OutlineInputBorder()))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                      child: Text(_isLoading ? 'PROCESANDO...' : 'GUARDAR FRANQUICIA', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}