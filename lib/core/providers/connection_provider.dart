import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Escucha cambios en tiempo real (Wifi <-> Datos <-> Nada)
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Si hay internet o no
final hasInternetProvider = Provider<bool>((ref) {
  final statusAsync = ref.watch(connectivityStreamProvider);
  
  return statusAsync.when(
    data: (results) {
        // Si la lista contiene 'none' o está vacía, no hay internet
        if (results.contains(ConnectivityResult.none) || results.isEmpty) {
            return false;
        }
        return true; 
    },
    // Por defecto, asumimos que sí mientras carga para no asustar
    loading: () => true, 
    error: (_, _) => true,
  );
});