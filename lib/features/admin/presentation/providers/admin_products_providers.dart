import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/home/data/models/event_model.dart';
import 'package:vive_core/features/home/data/models/product_model.dart';
import 'package:vive_core/features/home/data/repositories/establishment_repository.dart';
import 'package:vive_core/features/home/data/repositories/product_repository.dart';


// 1. Estado del filtro: ¿Qué evento tenemos seleccionado en el dropdown?
// Usamos StateProvider para poder cambiarlo desde la UI.
final selectedEventFilterProvider = StateProvider<EventModel?>((ref) => null);

// 2. Lista de productos filtrada
// Escucha cambios en el filtro y pide los datos al repositorio.
// Usamos autoDispose para que al salir de la pantalla se limpie la memoria.
final adminProductsByEventProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  // a. Obtenemos el evento seleccionado
  final selectedEvent = ref.watch(selectedEventFilterProvider);
  
  // b. Si no hay evento seleccionado, devolvemos lista vacía y no llamamos a la DB
  if (selectedEvent == null) return [];

  // c. Si hay evento, pedimos sus productos al repositorio
  final repo = ref.read(productRepositoryProvider);
  
  // Nota: Asegúrate de haber añadido el método 'getProductsByEvent' 
  // en tu ProductRepository como vimos en el paso anterior.
  return repo.getProductsByEvent(selectedEvent.id);
});

// Este provider trae TODOS los bares, sin importar eventos activos/inactivos
final adminAllEstablishmentsProvider = FutureProvider<List<EstablishmentModel>>((ref) async {
  final repo = ref.watch(establishmentRepositoryProvider);
  return repo.getAllEstablishments();
});