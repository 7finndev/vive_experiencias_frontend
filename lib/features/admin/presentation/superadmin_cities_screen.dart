import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/core/widgets/error_view.dart';
import 'package:vive_core/features/admin/data/superadmin_repository.dart';

class SuperadminCitiesScreen extends ConsumerWidget {
  const SuperadminCitiesScreen({super.key});

  // FUNCIÓN PARA CAMBIAR EL ESTADO (Soft Delete)
  Future<void> _toggleStatus(BuildContext context, WidgetRef ref, int cityId, bool currentStatus, String cityName) async {
    try {
      final repo = ref.read(superadminRepositoryProvider);
      await repo.toggleCityStatus(cityId, !currentStatus); // Llama a FastAPI
      
      ref.invalidate(superadminCitiesProvider); // Recarga la lista
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? "🔴 Franquicia '$cityName' desactivada" : "🟢 Franquicia '$cityName' activada"),
            backgroundColor: currentStatus ? Colors.orange : Colors.green,
          )
        );
      }
    } catch (e) {
      Logger.error("Error cambiando estado de ciudad: $e", "SUPERADMIN");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(superadminCitiesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestión de Franquicias', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_city', // Evita conflictos si hay varios FAB
        onPressed: () async {
          await context.push('/superadmin/cities/new'); // Crear (sin extra)
          ref.invalidate(superadminCitiesProvider);
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nueva Franquicia", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
      ),
      body: citiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(error: err, onRetry: () => ref.invalidate(superadminCitiesProvider)),
        data: (cities) {
          if (cities.isEmpty) return const Center(child: Text("No hay franquicias registradas."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              final int cityId = city['id'];
              final String name = city['name'] ?? 'Sin nombre';
              final bool isActive = city['is_active'] ?? false;
              
              // 🎨 Extraemos Configuración de la Marca Blanca
              String colorHex = '#808080';
              String logoUrl = '';
              final config = city['app_config'];
              if (config != null) {
                if (config is List && config.isNotEmpty) {
                  colorHex = config[0]['primary_color'] ?? colorHex;
                  logoUrl = config[0]['logo_url'] ?? logoUrl;
                } else if (config is Map) {
                  colorHex = config['primary_color'] ?? colorHex;
                  logoUrl = config['logo_url'] ?? logoUrl;
                }
              }

              Color primaryColor;
              try {
                String cleanHex = colorHex.replaceAll('#', '');
                if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
                primaryColor = Color(int.parse(cleanHex, radix: 16));
              } catch (_) { primaryColor = Colors.grey; }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // LOGO
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: logoUrl.isNotEmpty
                              ? Image.network(logoUrl, fit: BoxFit.contain, errorBuilder: (_,_,_) => const Icon(Icons.location_city))
                              : const Icon(Icons.location_city, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold,
                                color: isActive ? Colors.black : Colors.grey,
                                decoration: isActive ? null : TextDecoration.lineThrough
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text("ID BD: $cityId", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // BOTONES DE ACCIÓN
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            children: [
                              Switch(
                                value: isActive,
                                activeThumbColor: Colors.green,
                                onChanged: (val) => _toggleStatus(context, ref, cityId, isActive, name),
                              ),
                              Text(isActive ? "ACTIVA" : "INACTIVA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red))
                            ],
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              await context.push('/superadmin/cities/new', extra: city); // Editar (pasa el mapa)
                              ref.invalidate(superadminCitiesProvider);
                            },
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}