import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:latlong2/latlong.dart';
import 'package:vive_core/core/utils/geocoding_helper.dart';
import 'package:vive_core/core/utils/logger_service.dart'; 

import 'package:vive_core/features/home/presentation/providers/home_providers.dart';
import 'package:vive_core/core/widgets/error_view.dart';
import 'package:vive_core/features/home/presentation/widgets/establishment_card.dart';
import 'package:vive_core/features/hub/presentation/providers/city_config_provider.dart'; 
import 'providers/navigation_provider.dart';

// CAMBIO 1: Cambiamos a ConsumerStatefulWidget para manejar el estado local del GPS
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // Variable local para saber si estamos esperando al GPS
  bool _isLocating = false;
  final MapController _mapController = MapController(); // Añadimos controlador
  bool _hasCenteredOnCity = false; // Para centrar solo una vez al cargar la ciudad

  // FUNCIÓN GPS COMPATIBLE CON HUAWEI
  Future<LatLng?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Activa el GPS para calcular la ruta.")));
         return null;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      // 🔥 LEGACY MODE PARA HONOR/HUAWEI 🔥
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true, 
      );
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) { 
      Logger.error("Error GPS: $e", "MAP_SCREEN");
      return null; 
    }
  }

  // Lógica combinada al pulsar el botón
  Future<void> _handleGetDirections() async {
    // 1. Activamos carga visual INMEDIATAMENTE
    setState(() => _isLocating = true);

    // 2. Obtenemos GPS (Esto es lo que tardaba y congelaba la UI visualmente)
    final userLoc = await _getCurrentLocation();

    // 3. Si tenemos ubicación, llamamos al provider
    if (userLoc != null) {
      // El provider se encargará de poner su propio estado de carga (isLoadingRoute)
      // pero mantenemos _isLocating en false porque ya pasamos la bola al provider
      await ref.read(navigationProvider.notifier).calculateRouteToTarget(userLoc);
    }
    
    // 4. Desactivamos la carga local del GPS
    if (mounted) {
      _mapController.move(userLoc!, 16.0);
    }
    if (mounted) setState(() => _isLocating = false);

  }

@override
  Widget build(BuildContext context) {
    final establishmentsAsync = ref.watch(establishmentsListProvider);
    final navState = ref.watch(navigationProvider); 
    
    // 1. Obtenemos el nombre real de la franquicia actual (Ej: "Nerja", "Madrid")
    final config = ref.watch(cityConfigProvider).valueOrNull;
    final cityName = config?['resolved_city_name'] ?? 'Málaga';

    final bool isBusy = _isLocating || navState.isLoadingRoute;

    return Scaffold(
      body: establishmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorView(
          error: err,
          onRetry: () => ref.invalidate(establishmentsListProvider)
        ),
        data: (establishments) {
          final validEst = establishments.where((e) => e.latitude != null && e.longitude != null).toList();
          
          // Coordenada inicial de seguridad para que FlutterMap no pete al construirse
          LatLng initialCenter = const LatLng(36.741, -4.093);

          if (navState.userLocation != null) {
            // Prioridad 1: Centrar en el usuario
            initialCenter = navState.userLocation!;
          } else if (validEst.isNotEmpty) {
            // Prioridad 2: Centrar en el primer bar disponible
            initialCenter = LatLng(validEst.first.latitude!, validEst.first.longitude!);
          } else {
            // 🚀 PRIORIDAD 3: Centrar de forma inteligente
            if (!_hasCenteredOnCity) {
              _hasCenteredOnCity = true;
              
              // 3.A Intentamos leer las coordenadas de la base de datos (App Config)
              final double? cityLat = config?['gps_lat'];
              final double? cityLng = config?['gps_lng'];
              
              if (cityLat != null && cityLng != null) {
                // Si la DB las tiene, nos movemos ahí inmediatamente
                Future.microtask(() => _mapController.move(LatLng(cityLat, cityLng), 14.0));
              } else {
                // 3.B Si la DB NO las tiene (Ej: franquicia antigua), buscamos en vivo por el nombre
                GeocodingHelper.getCoordinatesFromAddress("$cityName, España").then((coords) {
                  if (coords != null && mounted) {
                    _mapController.move(LatLng(coords[0], coords[1]), 14.0);
                  }
                });
              }
            }
          }

          return Stack(
            children: [
              // 1. MAPA
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter, // Usamos la variable calculada
                  initialZoom: 15.0,
                  onTap: (_, _) => ref.read(navigationProvider.notifier).clearSelection(),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'es.sietefinn.appvivetorredelmar', 
                  ),
                  
                  // RUTA
                  if (navState.routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: navState.routePoints,
                          strokeWidth: 5.0,
                          color: Colors.blueAccent,
                        ),
                      ],
                    ),

                  // MARCADORES
                  MarkerLayer(
                    markers: establishments.map((e) {
                      if (e.latitude == null || e.longitude == null) return null;
                      
                      final isSelected = navState.targetEstablishment?.id == e.id;

                      return Marker(
                        point: LatLng(e.latitude!, e.longitude!),
                        width: isSelected ? 60 : 40, 
                        height: isSelected ? 60 : 40,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(navigationProvider.notifier).selectOnly(e);
                          },
                          child: Icon(
                            Icons.location_on, 
                            color: isSelected ? Colors.red : Colors.red.shade300, 
                            size: isSelected ? 60 : 40,
                            shadows: const [Shadow(blurRadius: 5, color: Colors.black45)],
                          ),
                        ),
                      );
                    }).whereType<Marker>().toList(),
                  ),
                  
                  // USUARIO
                  if (navState.userLocation != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: navState.userLocation!,
                        width: 20, height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)]
                          ),
                        ),
                      )
                    ]),
                ],
              ),

              // 2. UI FLOTANTE (BOTÓN + TARJETA)
              if (navState.targetEstablishment != null)
                Positioned(
                  bottom: 20, left: 16, right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      
                      // 🔥 BOTÓN "CÓMO LLEGAR" MEJORADO 🔥
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FloatingActionButton.extended(
                          heroTag: "btn_calc_ruta",
                          // Si está ocupado, deshabilitamos el botón (null) o lo dejamos sin acción
                          onPressed: isBusy ? null : _handleGetDirections,
                          backgroundColor: Colors.blue[800],
                          // CAMBIO 3: Usamos la variable combinada 'isBusy'
                          icon: isBusy 
                             ? const SizedBox(
                                 width: 20, 
                                 height: 20, 
                                 child: CircularProgressIndicator(
                                   color: Colors.white, 
                                   strokeWidth: 2
                                 )
                               )
                             : const Icon(Icons.directions, color: Colors.white),
                          label: Text(
                            isBusy ? "CALCULANDO..." : "CÓMO LLEGAR",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // MENSAJES DE ERROR
                      if (navState.isOfflineMode)
                         Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                          child: const Text("Error al calcular ruta. Revisa tu conexión.", style: TextStyle(color: Colors.white)),
                        ),

                      // TARJETA DEL ESTABLECIMIENTO
                      SizedBox(
                        height: 125,
                        width: double.infinity,
                        child: EstablishmentCard(establishment: navState.targetEstablishment!),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}