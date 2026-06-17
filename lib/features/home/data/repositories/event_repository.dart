import 'dart:convert'; // NUEVO: Para procesar el JSON de FastAPI
import 'dart:typed_data';
import 'package:http/http.dart'
    as http; // NUEVO: Para hacer la petición a tu servidor
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vive_core/core/constants/app_data.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/features/home/data/models/event_model.dart';

part 'event_repository.g.dart';

class EventRepository {
  final SupabaseClient _client;

  EventRepository(this._client);

  // ==========================================================
  //  MÉTODOS STORAGE (Se quedan directos a Supabase por ahora)
  // ==========================================================
  Future<String> uploadEventImage(String fileName, Uint8List fileBytes) async {
    try {
      final path = 'events/$fileName';
      await _client.storage
          .from('events')
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from('events').getPublicUrl(path);
    } catch (e) {
      Logger.error("⚠️ Error subiendo imagen evento: $e", "EVENT_REPOSITORY");
      throw Exception("Error subiendo imagen: $e");
    }
  }

  Future<void> deleteEventImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      await _client.storage.from('events').remove([fileName]);
      Logger.info("🗑️ Imagen evento eliminada: $fileName", "EVENT_REPOSITORY");
    } catch (e) {
      Logger.error("⚠️ No se pudo borrar imagen antigua: $e", "EVENT_REPOSITORY");
    }
  }

  // ==========================================================
  // 📖 MÉTODOS DE LECTURA (AHORA CONECTADOS A FASTAPI 🚀)
  // ==========================================================

  // --- READ: Obtener todos desde tu backend Python ---
  Future<List<EventModel>> getAllEvents(int cityId) async {
    try {
      // Montamos la URL dinámica según la ciudad que toque
      final url = Uri.parse(
        '${AppData.apiUrl}/api/v1/events/$cityId', //{AppData.cityId}',
      );
      //final cityId = dotenv.env['CITY_ID'] ?? '1';
      //final url = Uri.parse(
      //  '${AppData.apiUrl}/api/v1/events/$cityId',
      //);
  
      Logger.warning(
        "📞 [DEBUG] Intentando llamar a FastAPI en: $url",
        "EVENT_REPOSITORY",
      ); 


      // Hacemos la petición a FastAPI
      final response = await http.get(url);

      Logger.warning(
        "📞 [DEBUG] Respuesta de FastAPI: ${response.statusCode}",
        "EVENT_REPOSITORY",
      ); 

      if (response.statusCode == 200) {
        // Desempaquetamos el JSON que vimos antes en tu móvil
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw Exception('Error de FastAPI: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error("💀 ERROR CONECTANDO CON FASTAPI: $e", "EVENT_REPOSITORY");
      rethrow;
    }
  }

  // Obtener activo
  Future<EventModel?> getActiveEvent(int cityId) async {
    // Reutilizamos el método de arriba para ahorrar peticiones a la red
    final events = await getAllEvents(cityId);
    try {
      // En tu código antiguo buscabas 'active', en el nuevo SQL pusimos 'published'.
      // Cambiamos a 'published' o buscamos cualquiera que no sea 'draft'.
      return events.firstWhere((e) => e.status != 'draft');
    } catch (e) {
      Logger.warning("📭 No se encontró un evento activo.", "EVENT_REPOSITORY");
      return null;
    }
  }

  // ==========================================================
  // ✍️ MÉTODOS DE ESCRITURA (Panel Admin) - ¡AHORA POR FASTAPI! 🚀
  // ==========================================================

  Future<void> createEvent(EventModel event) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión de administrador activa.');

    final data = event.toJson();
    data.remove('id');
    
    // 🔥 CORRECCIÓN: Usamos el cityId que viene del formulario, 
    // y solo si es nulo (por seguridad) recurrimos al de AppData.
    data['city_id'] = event.cityId ?? AppData.cityId; 

    final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/events');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al crear evento en el servidor: ${response.body}');
    }
  }

  Future<void> updateEvent(EventModel event) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión de administrador activa.');

    final data = event.toJson();
    final eventId = event.id;
    data.remove('id');
    
    // 🔥 CORRECCIÓN: Igual aquí, respetamos el ID del modelo
    data['city_id'] = event.cityId ?? AppData.cityId;

    final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/events/$eventId');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar evento en el servidor: ${response.body}');
    }
  }

  Future<void> deleteEvent(int id) async {
    await _client.from('events').delete().eq('id', id);
  }
}

@riverpod
EventRepository eventRepository(EventRepositoryRef ref) {
  return EventRepository(Supabase.instance.client);
}
