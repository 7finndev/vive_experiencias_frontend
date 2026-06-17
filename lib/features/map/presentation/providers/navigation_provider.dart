import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/map/data/datasources/osm_service.dart';

// ESTADO (Sin cambios)
class NavigationState {
  final EstablishmentModel? targetEstablishment;
  final LatLng? userLocation;
  final List<LatLng> routePoints; 
  final bool isLoadingRoute;      
  final bool isOfflineMode;       
  final bool shouldRecalculate; 

  NavigationState({
    this.targetEstablishment,
    this.userLocation,
    this.routePoints = const [],
    this.isLoadingRoute = false,
    this.isOfflineMode = false,
    this.shouldRecalculate = false,
  });

  NavigationState copyWith({
    EstablishmentModel? targetEstablishment,
    LatLng? userLocation,
    List<LatLng>? routePoints,
    bool? isLoadingRoute,
    bool? isOfflineMode,
    bool? shouldRecalculate,
  }) {
    return NavigationState(
      targetEstablishment: targetEstablishment ?? this.targetEstablishment,
      userLocation: userLocation ?? this.userLocation,
      routePoints: routePoints ?? this.routePoints,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      shouldRecalculate: shouldRecalculate ?? this.shouldRecalculate,
    );
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  final OsrmService _osrmService = OsrmService();

  NavigationNotifier() : super(NavigationState());

  // --- 1. MÉTODO NUEVO: SOLO SELECCIONAR (Instantáneo) ---
  // Muestra la tarjeta del bar sin pedir GPS ni calcular nada.
  void selectOnly(EstablishmentModel establishment) {
    state = state.copyWith(
      targetEstablishment: establishment,
      routePoints: [], // Limpiamos la ruta anterior para no confundir
      isLoadingRoute: false,
      isOfflineMode: false,
      // No tocamos userLocation (si ya la teníamos, se queda; si no, null)
    );
  }

  // --- 2. MÉTODO NUEVO: CALCULAR RUTA (Bajo demanda) ---
  // Se llama cuando el usuario pulsa el botón "CÓMO LLEGAR"
  Future<void> calculateRouteToTarget(LatLng userLocation) async {
    final target = state.targetEstablishment;
    
    // Si no hay local seleccionado o le faltan coordenadas, no hacemos nada
    if (target == null || target.latitude == null || target.longitude == null) return;

    // Activamos spinner y guardamos la ubicación actual del usuario
    state = state.copyWith(
      userLocation: userLocation,
      isLoadingRoute: true, 
      isOfflineMode: false,
    );

    try {
      final targetLoc = LatLng(target.latitude!, target.longitude!);
      
      // Llamada a la API de rutas (OSM/OSRM)
      final points = await _osrmService.getWalkingRoute(userLocation, targetLoc);
      
      if (mounted) {
        state = state.copyWith(
          routePoints: points,
          isLoadingRoute: false, // Apagamos spinner
          isOfflineMode: points.isEmpty, // Si viene vacío, asumimos error de red
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoadingRoute: false,
          isOfflineMode: true,
        );
      }
    }
  }

  void clearSelection() {
    state = NavigationState(userLocation: state.userLocation); 
  }
  
  void updateUserLocation(LatLng loc) {
    state = state.copyWith(userLocation: loc);
  }
}

// (MEJORADO) Limpia el proveedor cuando no se usa:
final navigationProvider = StateNotifierProvider.autoDispose<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});
//final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
//  return NavigationNotifier();
//});