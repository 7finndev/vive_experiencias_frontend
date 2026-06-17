import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vive_core/core/constants/app_data.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/features/home/data/models/sponsor_model.dart';
import 'package:vive_core/core/local_storage/local_db_service.dart';

part 'sponsor_repository.g.dart';

class SponsorRepository {
  final SupabaseClient _client;
  final LocalDbService _localDb;

  SponsorRepository(this._client, this._localDb);

  // --- SUBIDA DE IMAGEN (OPTIMIZADA) ---
  Future<String> uploadSponsorLogo(String fileName, Uint8List imageBytes) async {
    try {
      final path = 'logos/$fileName'; 

      await _client.storage.from('logos').uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return _client.storage.from('logos').getPublicUrl(path);
    } catch (e) {
      throw Exception("Error subiendo logo: $e");
    }
  }

  // --- BORRAR IMAGEN ---
  Future<void> deleteSponsorLogo(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      await _client.storage.from('logos').remove([fileName]);
    } catch (e) {
      Logger.error("⚠️ Error borrando logo antiguo: $e", "SPONSOR_REPOSITORY");
    }
  }

  // --- CRUD BÁSICO ---
  Future<List<SponsorModel>> getActiveSponsors(int cityId) async {
    // Aquí podrías meter lógica de caché igual que en Eventos, 
    // pero de momento replicamos lo básico.
    final response = await _client
        .from('sponsors')
        .select()
        .eq('city_id', cityId)
        .eq('is_active', true)
        .order('priority', ascending: false);
    
    return (response as List).map((e) => SponsorModel.fromJson(e)).toList();
  }
  
  // Usado por Admin (trae activos e inactivos)
  Future<List<SponsorModel>> getAllSponsors(int cityId) async {
    final response = await _client
        .from('sponsors')
        .select()
        .eq('city_id', cityId)
        .order('priority', ascending: false);
    
    return (response as List).map((e) => SponsorModel.fromJson(e)).toList();
  }

  Future<void> createSponsor(Map<String, dynamic> data) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión activa.');

    // No necesitamos borrar el 'id' porque el Map del formulario no lo tiene.
    // Tampoco el 'city_id' porque FastAPI lo pone por seguridad.

    final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/sponsors');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al crear patrocinador en el servidor: ${response.body}');
    }
  }

  Future<void> updateSponsor(int id, Map<String, dynamic> data) async {
    await _client.from('sponsors').update(data).eq('id', id);
  }

  Future<void> deleteSponsor(int id) async {
    await _client.from('sponsors').delete().eq('id', id);
  }
}

@riverpod
SponsorRepository sponsorRepository(SponsorRepositoryRef ref) {
  final db = ref.watch(localDbServiceProvider);
  return SponsorRepository(Supabase.instance.client, db);
}