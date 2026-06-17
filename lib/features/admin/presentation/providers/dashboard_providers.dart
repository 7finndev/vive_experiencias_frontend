import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vive_core/features/admin/data/dashboard_repository.dart';
import 'package:vive_core/features/home/data/models/event_model.dart';

// -----------------------------------------------------------------------------
// 1. PROVIDER DE ESTADO (UI): ¿Qué evento está seleccionado en el dropdown?
// -----------------------------------------------------------------------------
// null significa "Ninguno seleccionado" o "Modo Global" (según tu lógica)
final dashboardSelectedEventProvider = StateProvider<EventModel?>((ref) => null);

// -----------------------------------------------------------------------------
// 2. PROVIDER DE DATOS (LÓGICA): Estadísticas Reactivas
// -----------------------------------------------------------------------------
// Este provider es "inteligente":
// - Escucha cambios en 'dashboardSelectedEventProvider'.
// - Cuando el usuario cambia el dropdown, este se ejecuta de nuevo automáticamente.
// - Llama al repositorio pasando el ID (o null).
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  
  // A. Observamos el filtro (Dropdown)
  final selectedEvent = ref.watch(dashboardSelectedEventProvider);
  
  // B. Llamamos al repositorio
  final repository = ref.read(dashboardRepositoryProvider);
  
  // C. Pedimos las stats filtradas por el ID del evento (si existe)
  return repository.getStats(eventId: selectedEvent?.id);
});