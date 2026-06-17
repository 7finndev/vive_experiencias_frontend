import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';
import 'package:vive_core/features/scan/presentation/providers/scan_status_provider.dart';

// Modelo de retorno simple
class NearestBarResult {
  final EstablishmentModel? bar;
  final double distance;
  NearestBarResult({this.bar, required this.distance});
}

// 1. Provider de Ubicación (Seguro y con Timeout)
final userLocationProvider = FutureProvider.autoDispose<Position?>((ref) async {
  // Verificamos servicios
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    return null; 
  }

  // Timeout de 5 segundos
  try {
    return await Geolocator.getCurrentPosition(
      timeLimit: const Duration(seconds: 5), 
    );
  } catch (e) {
    return null; 
  }
});

// 2. Provider que calcula el bar más cercano
final nearestBarProvider = FutureProvider.autoDispose.family<NearestBarResult?, int>((ref, eventId) async {
  
  // A. Obtenemos ubicación
  final position = await ref.watch(userLocationProvider.future);
  if (position == null) return null; // Sin GPS no hay cálculo

  final userLatLng = LatLng(position.latitude, position.longitude);

  // B. Obtenemos la lista de bares (CORREGIDO)
  // Simplemente esperamos a que el provider de la lista resuelva los datos.
  final establishments = await ref.watch(establishmentsListProvider.future);
  
  // C. Lógica de cálculo
  EstablishmentModel? closest;
  double minDistance = double.infinity;
  final Distance distanceCalc = const Distance();

  for (var bar in establishments) {
    // Protección contra datos nulos
    if (bar.latitude == null || bar.longitude == null) continue;

    // Verificar si ya está visitado
    // (Asegúrate de que hasStampProvider existe en scan_status_provider.dart)
    final isVisited = ref.read(hasStampProvider(
      establishmentId: bar.id, 
      eventId: eventId
    ));

    if (isVisited) continue;

    final double dist = distanceCalc.as(
      LengthUnit.Meter,
      userLatLng,
      LatLng(bar.latitude!, bar.longitude!),
    );

    if (dist < minDistance) {
      minDistance = dist;
      closest = bar;
    }
  }

  // Si no encontramos ninguno (ej: todos visitados), devolvemos null
  if (closest == null) return null;

  return NearestBarResult(bar: closest, distance: minDistance);
});