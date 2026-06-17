import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/utils/logger_service.dart';

class CitySelectorModal extends ConsumerStatefulWidget {
  const CitySelectorModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CitySelectorModal(),
    );
  }

  @override
  ConsumerState<CitySelectorModal> createState() => _CitySelectorModalState();
}

class _CitySelectorModalState extends ConsumerState<CitySelectorModal> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allCities = [];
  
  // 🔥 VARIABLES PARA EL BUSCADOR
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final response = await Supabase.instance.client
          .from('cities')
          .select('id, name, app_config(primary_color, logo_url)')
          .eq('is_active', true)
          .order('name'); 

      if (mounted) {
        setState(() {
          _allCities = (response as List).map((city) {
            String color = '#808080';
            String logo = '';
            
            final config = city['app_config'];
            if (config != null) {
              if (config is List && config.isNotEmpty) {
                color = config[0]['primary_color'] ?? color;
                logo = config[0]['logo_url'] ?? logo;
              } else if (config is Map) {
                color = config['primary_color'] ?? color;
                logo = config['logo_url'] ?? logo;
              }
            }

            return {
              'id': city['id'],
              'name': city['name'],
              'primary_color': color,
              'logo_url': logo,
            };
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error("Error al cargar localidades desde BD: $e", "CITY_SELECTOR_MODAL");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 LÓGICA DE FILTRADO
    final filteredCities = _allCities.where((city) {
      final cityName = city['name'].toString().toLowerCase();
      return cityName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), 
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85, // Un poco más alto para dar espacio al buscador
        maxWidth: 600, 
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Selecciona tu destino', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Elige la localidad que quieres explorar para ver sus rutas y eventos activos.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),

          // 🔥 WIDGET DEL BUSCADOR
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Buscar ciudad...",
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = "");
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 20),

          // Lista de Ciudades Filtrada
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCities.isEmpty
                    ? const Center(child: Text("No se encontraron ciudades", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = filteredCities[index];
                          Color dotColor;
                          try {
                            String hexColor = city['primary_color']?.replaceAll('#', '') ?? '808080';
                            if (hexColor.length == 6) hexColor = 'FF$hexColor'; 
                            dotColor = Color(int.parse('0x$hexColor'));
                          } catch (e) {
                             dotColor = Colors.grey;
                          }

                          return Card(
                            color: Colors.white.withValues(alpha: 0.05),
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                              title: Text(city['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/city/${city['id']}');
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}