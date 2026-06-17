import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Imports de tus repos y modelos
import 'package:vive_core/core/local_storage/local_db_service.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/home/data/models/product_model.dart';
import 'package:vive_core/features/home/data/repositories/establishment_repository.dart';
import 'package:vive_core/features/home/data/repositories/product_repository.dart';
import 'package:vive_core/features/home/data/repositories/sponsor_repository.dart';
import 'package:vive_core/features/scan/data/repositories/passport_repository.dart';
import 'package:vive_core/features/home/data/models/event_model.dart';
import 'package:vive_core/features/home/data/models/sponsor_model.dart';

// 🔥 NUEVO: Importamos el repositorio que conecta con FastAPI
import 'package:vive_core/features/home/data/repositories/event_repository.dart';

part 'home_providers.g.dart';

// --- ESTADOS GLOBALES ---
final currentEventIdProvider = StateProvider<int>((ref) => 1);
final hubFilterProvider = StateProvider<String>((ref) => 'active');
final currentCityIdProvider = StateProvider<int>((ref) => 1);

// 2. Repositorios
@riverpod
EstablishmentRepository establishmentRepository(EstablishmentRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbServiceProvider); 
  return EstablishmentRepository(supabase, localDb);
}

@riverpod
PassportRepository passportRepository(PassportRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbServiceProvider);
  return PassportRepository(supabase, localDb);
}

// 3. Establecimientos (Usuario)
// 3. Establecimientos (Usuario) - VERSIÓN FILTRADA POR EVENTO
@riverpod
Future<List<EstablishmentModel>> establishmentsList(EstablishmentsListRef ref) async {
  final repository = ref.watch(establishmentRepositoryProvider);
  final cityId = ref.watch(currentCityIdProvider); 
  
  // 1. Descargamos TODOS los establecimientos de la ciudad actual (Ej: Nerja)
  final allCityEstablishments = await repository.getEstablishments(cityId: cityId);
  
  // 2. Descargamos los productos del EVENTO ACTUAL (Ej: Ruta de la Tapa)
  // Usamos .future para esperar a que la lista de productos termine de cargar
  final eventProducts = await ref.watch(productsListProvider.future);
  
  // 3. Extraemos solo los IDs de los bares que SÍ tienen tapa en este evento
  final participatingEstablishmentIds = eventProducts.map((p) => p.establishmentId).toSet();
  
  // 4. Filtramos la lista maestra de la ciudad:
  // Si la lista de productos está vacía (evento nuevo), mostramos todos por defecto.
  // Si hay productos, mostramos SOLO los bares que participan.
  if (participatingEstablishmentIds.isEmpty) {
     return allCityEstablishments;
  } else {
     return allCityEstablishments.where((bar) => participatingEstablishmentIds.contains(bar.id)).toList();
  }
}

// 4. Conectividad
@riverpod
Stream<List<ConnectivityResult>> connectivityStream(ConnectivityStreamRef ref) {
  return Connectivity().onConnectivityChanged;
}

// 5. Productos (Usuario)
@riverpod
Future<List<ProductModel>> productsList(ProductsListRef ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final event = await ref.watch(currentEventProvider.future);
  return repository.getProductsByEvent(event.id);
}

// =========================================================================
// 🔥 PROVIDERS CONVERTIDOS EN FAMILIAS (Reciben el cityId de la interfaz)
// =========================================================================

@riverpod
Future<EventModel> currentEvent(CurrentEventRef ref) async {
  final id = ref.watch(currentEventIdProvider);
  final repo = ref.watch(eventRepositoryProvider); // Usamos el Repo de FastAPI
  final localDb = ref.watch(localDbServiceProvider); 
  final cityId = ref.watch(currentCityIdProvider);

  try {
    // Pedimos a FastAPI los eventos del pueblo y filtramos por el ID actual
    final events = await repo.getAllEvents(cityId);
    return events.firstWhere((e) => e.id == id);
  } catch (e) {
    // Si falla internet, tiramos de caché
    final cachedEvents = localDb.getCachedEvents();
    if (cachedEvents.isNotEmpty) {
      try {
        final found = cachedEvents.firstWhere((element) => element['id'] == id);
        return EventModel.fromJson(found);
      } catch (_) {}
    }
    rethrow;
  }
}

// 8. LISTA DE EVENTOS (Admin/Hub) (🔥 AHORA CONECTADA A FASTAPI)
@riverpod
Future<List<EventModel>> adminEventsList(AdminEventsListRef ref) async {
  final repo = ref.watch(eventRepositoryProvider); // Usamos el Repo de FastAPI
  final localDb = ref.watch(localDbServiceProvider);
  final cityId = ref.watch(currentCityIdProvider);

  try {
    // Llamada a FastAPI
    final events = await repo.getAllEvents(cityId); //Inyección
    
    // Guardamos en caché local para el modo offline
    final dataList = events.map((e) => e.toJson()).toList();
    await localDb.cacheEvents(dataList);

    return events;
  } catch (e) {
    // Si falla internet, tiramos de caché
    final cachedData = localDb.getCachedEvents();
    if (cachedData.isNotEmpty) {
      return cachedData.map((e) => EventModel.fromJson(e)).toList();
    }
    rethrow;
  }
}

// 9. Lista MAESTRA (Sigue directa a Supabase temporalmente)
@riverpod
Future<List<EstablishmentModel>> allEstablishmentsList(AllEstablishmentsListRef ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('establishments').select().order('name', ascending: true);
  return response.map((e) => EstablishmentModel.fromJson(e)).toList();
}

// 10. Detalle Admin (Sigue directo a Supabase temporalmente)
@riverpod
Future<EventModel> eventDetails(EventDetailsRef ref, int eventId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('events').select().eq('id', eventId).single();
  return EventModel.fromJson(response);
}

// 11. PATROCINADORES
@riverpod
Future<List<SponsorModel>> sponsorsList(SponsorsListRef ref) async {
  final repo = ref.watch(sponsorRepositoryProvider);
  final localDb = ref.watch(localDbServiceProvider);
  final cityId = ref.watch(currentCityIdProvider);
  
  try {
    final sponsors = await repo.getActiveSponsors(cityId); //Inyección
    final jsonList = sponsors.map((e) => e.toJson()).toList();
    await localDb.cacheSponsors(jsonList);
    return sponsors;
  } catch (e) {
    final cached = localDb.getCachedSponsors();
    if (cached.isNotEmpty) {
      return cached.map((e) => SponsorModel.fromJson(e)).toList();
    }
    rethrow;
  }
}