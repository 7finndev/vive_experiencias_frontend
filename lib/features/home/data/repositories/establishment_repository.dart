import 'dart:convert'; // NUEVO: Para procesar el JSON de FastAPI
import 'dart:typed_data'; 
import 'package:http/http.dart' as http; // NUEVO: Para conectar a FastAPI
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart'; 
import 'package:vive_core/core/local_storage/local_db_service.dart';
import 'package:vive_core/core/constants/app_data.dart'; // NUEVO: Para la URL de FastAPI
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';

part 'establishment_repository.g.dart';

class EstablishmentRepository {
  final SupabaseClient _supabase;
  final LocalDbService _localDb;

  EstablishmentRepository(this._supabase, this._localDb);

  // ====================================================================
  // 📸 MÉTODOS STORAGE (Se quedan en Supabase temporalmente)
  // ====================================================================
  
  Future<String> uploadEstablishmentImage(String fileName, Uint8List fileBytes) async {
    try {
      final path = 'establishments/$fileName'; 
      await _supabase.storage.from('establishment').uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _supabase.storage.from('establishment').getPublicUrl(path);
    } catch (e) {
      throw Exception("Error al subir la imagen al servidor: $e");
    }
  }

  Future<void> deleteEstablishmentImage(String imageUrl) async {
    try{
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      await _supabase.storage.from('establishment').remove([fileName]);
    } catch (e) {
      Logger.error("⚠️ Error borrando imagen establecimiento:$e", "ESTABLISHMENT_REPOSITORY");
    }
  }

  // ====================================================================
  // 📱 MÉTODOS DE LECTURA (APP) - 🔥 AHORA CONECTADOS A FASTAPI
  // ====================================================================

  /// 1. READ (APP): Obtiene la lista de bares activos para la CIUDAD DINÁMICA.
  Future<List<EstablishmentModel>> getEstablishments({required int cityId}) async { // 🔥 CAMBIO: Recibe cityId
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      try {
        Logger.info('🏘️ Bajando Bares de la Ciudad $cityId desde FastAPI...', "ESTABLISHMENT_REPOSITORY");
        
        // 🔥 CAMBIO VITAL: Usamos la variable $cityId, ya NO usamos AppData.cityId
        final url = Uri.parse('${AppData.apiUrl}/api/v1/establishments/$cityId');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final List<dynamic> data = jsonResponse['data']; 
          
          final list = data.map((e) => EstablishmentModel.fromJson(e)).toList();

          if (list.isNotEmpty) {
             await _localDb.establishmentsBox.clear();
             await _localDb.establishmentsBox.addAll(list);
          }
          return list;
        } else {
           throw Exception('Error de FastAPI: ${response.statusCode}');
        }
      } catch (e) {
        Logger.error('⚠️ ERROR REMOTO (Bares): $e. Intentando usar caché...', "ESTABLISHMENT_REPOSITORY");
        return _getLocalEstablishments();
      }
    } else {
      Logger.warning('📵 OFFLINE: Cargando Bares desde el móvil.', "ESTABLISHMENT_REPOSITORY");
      return _getLocalEstablishments();
    }
  }

  // --- HELPERS LOCALES ---
  List<EstablishmentModel> _getLocalEstablishments() {
    try {
      final box = _localDb.establishmentsBox;
      if (box.isEmpty) return [];
      return box.values.cast<EstablishmentModel>().toList();
    } catch (e) {
      _localDb.establishmentsBox.clear(); 
      return [];
    }
  }

  // ====================================================================
  // 🛠️ MÉTODOS DE ADMINISTRACIÓN (CRUD) - AHORA CONECTADOS A FASTAPI
  // ====================================================================

  /// 3. READ ALL (ADMIN): Obtiene todos los locales de la ciudad actual vía FastAPI
  Future<List<EstablishmentModel>> getAllEstablishments() async {
    try {
      // 1. Conseguimos el DNI (Token) de la sesión activa
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('No hay sesión de administrador activa.');

      Logger.info('🏘️ Admin: Pidiendo lista maestra de locales a FastAPI...', "ESTABLISHMENT_REPOSITORY");
      
      // 🔥 LA CLAVE: Llamamos a la ruta /admin/ (que Python ya filtra por ti basándose en el Token)
      final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/establishments');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // 🛡️ Nuestro escudo de seguridad
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data']; 
        
        return data.map((e) => EstablishmentModel.fromJson(e)).toList();
      } else {
        throw Exception('Error de FastAPI: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('⚠️ Error cargando lista admin: $e', "ESTABLISHMENT_REPOSITORY");
      throw Exception('No se pudieron cargar los establecimientos');
    }
  }

  /// 4. CREATE (ADMIN): Crea un nuevo establecimiento en FastAPI
  Future<void> createEstablishment(EstablishmentModel establishment) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión de administrador activa.');

    final data = establishment.toJson();
    data.remove('id'); 
    data['city_id'] = establishment.cityId ?? AppData.cityId; 

    // 🔥 EL HACK DEFINITIVO: Enviamos ambos nombres para que FastAPI no tenga escapatoria
    data['gps_lat'] = establishment.latitude;
    data['gps_lng'] = establishment.longitude;
    data['latitude'] = establishment.latitude;
    data['longitude'] = establishment.longitude;

    final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/establishments');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error del servidor: ${response.body}');
    }
  }

  /// 5. UPDATE (ADMIN): Actualiza un establecimiento vía FastAPI
  Future<void> updateEstablishment(EstablishmentModel establishment) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión de administrador activa.');

    final data = establishment.toJson();
    final estId = data['id']; 
    data.remove('id'); 
    data['city_id'] = establishment.cityId ?? AppData.cityId; 

    // 🔥 EL HACK DEFINITIVO: Hacemos lo mismo en la actualización
    data['gps_lat'] = establishment.latitude;
    data['gps_lng'] = establishment.longitude;
    data['latitude'] = establishment.latitude;
    data['longitude'] = establishment.longitude;

    final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/establishments/$estId');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Error del servidor: ${response.body}');
    }
  }

  Future<void> deleteEstablishment(int id) async {
    await _supabase.from('establishments').delete().eq('id', id);
  }
}

@riverpod
EstablishmentRepository establishmentRepository(EstablishmentRepositoryRef ref) {
  final supabase = Supabase.instance.client;
  final localDb = ref.watch(localDbServiceProvider);
  return EstablishmentRepository(supabase, localDb);
}