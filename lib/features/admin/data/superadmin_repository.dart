import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vive_core/core/constants/app_data.dart';
import 'package:vive_core/core/utils/logger_service.dart';

part 'superadmin_repository.g.dart';

class SuperadminRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> getGlobalStats() async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión activa.');

    final url = Uri.parse('${AppData.apiUrl}/api/v1/superadmin/dashboard');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data']; // Devuelve el mapa con los totales
    } else {
      throw Exception('Error cargando métricas globales: ${response.statusCode}');
    }
  }

  // Obtener todas las ciudades (Franquicias)
  Future<List<Map<String, dynamic>>> getCities() async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión activa.');

    final url = Uri.parse('${AppData.apiUrl}/api/v1/superadmin/cities');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(jsonResponse['data']);
    } else {
      throw Exception('Error cargando ciudades desde FastAPI');
    }
  }

  // 🗑️ SOFT DELETE (Desactivar/Activar Ciudad)
  Future<void> toggleCityStatus(int cityId, bool isActive) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión activa.');

    final url = Uri.parse('${AppData.apiUrl}/api/v1/superadmin/cities/$cityId/status');
    
    // Como en FastAPI usamos Form(...), enviamos los datos como formulario urlencoded
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'is_active': isActive.toString(),
      },
    );

    if (response.statusCode != 200) {
      Logger.error("Error FastAPI: ${response.body}", "SUPERADMIN");
      throw Exception('Error al cambiar el estado de la franquicia');
    }
  }

  // ✏️ ACTUALIZAR CIUDAD (Con o sin imagen)
  Future<void> updateCity({
    required int cityId,
    required String name,
    required bool isActive,
    required String primaryColor,
    Uint8List? newLogoBytes,
    Map<String, dynamic>? configData, // 🔥 AÑADIDO
  }) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión activa.');

    final url = Uri.parse('${AppData.apiUrl}/api/v1/superadmin/cities/$cityId');
    var request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['is_active'] = isActive.toString();
    request.fields['primary_color'] = primaryColor;

    // 🔥 INYECTAMOS LA CONFIGURACIÓN (Convirtiendo números a String)
    if (configData != null) {
      configData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });
    }

    if (newLogoBytes != null) {
      final multipartFile = http.MultipartFile.fromBytes(
        'logo',
        newLogoBytes,
        filename: 'logo_updated.jpg',
      );
      request.files.add(multipartFile);
    }

    final response = await request.send();
    if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      Logger.error("Error FastAPI Update: $respStr", "SUPERADMIN");
      throw Exception('Error al actualizar la franquicia.');
    }
  }

  // ➕ CREAR CIUDAD
  Future<void> createCityWithBranding({
    required String name,
    required bool isActive,
    required String primaryColor,
    required Uint8List logoBytes, // Corregido de List<int> a Uint8List
    Map<String, dynamic>? configData, // 🔥 AÑADIDO (dynamic para aceptar doubles)
  }) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Sesión expirada o no válida.');

    final url = Uri.parse('${AppData.apiUrl}/api/v1/superadmin/cities');
    
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = name
      ..fields['is_active'] = isActive.toString()
      ..fields['primary_color'] = primaryColor;

    // 🔥 INYECTAMOS LA CONFIGURACIÓN (Convirtiendo números a String)
    if (configData != null) {
      configData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'logo',
        logoBytes,
        filename: 'franchise_logo.jpg', 
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('FastAPI rechazó la solicitud: ${response.body}');
    }
  }
  // 🔥 Haz lo mismo para el método updateCity si quieres que el superadmin pueda editarlas después

  // =====================================================================
  // 👥 CREAR GESTOR (ADMIN DE FRANQUICIA)
  // =====================================================================
  Future<void> createManager({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
  }) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión activa.');

    final url = Uri.parse('${AppData.apiUrl}/api/v1/superadmin/managers');
    
    // Usamos x-www-form-urlencoded porque en FastAPI pusimos Form(...)
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'city_id': cityId.toString(),
      },
    );

    if (response.statusCode != 200) {
      Logger.error("Error creando gestor: ${response.body}", "SUPERADMIN");
      // Intentamos extraer el mensaje de error de FastAPI si existe
      String errorMsg = 'Error al crear la cuenta del gestor.';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['detail'] != null) errorMsg = errorData['detail'];
      } catch (_) {}
      
      throw Exception(errorMsg);
    }
  }
  // =====================================================================
  // 📋 LISTAR GESTORES
  // =====================================================================
  Future<List<Map<String, dynamic>>> getManagers() async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión activa.');

    final url = Uri.parse('${AppData.apiUrl}/api/v1/superadmin/managers');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(jsonResponse['data']);
    } else {
      throw Exception('Error cargando gestores desde FastAPI');
    }
  }
  // =====================================================================
  // ✏️ ACTUALIZAR GESTOR
  // =====================================================================
  Future<void> updateManager({
    required String managerId,
    required String email,
    required String fullName,
    required int cityId,
    String? newPassword,
  }) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión activa.');

    final url = Uri.parse('${AppData.apiUrl}/api/v1/superadmin/managers/$managerId');
    
    final Map<String, String> body = {
      'email': email.trim(),
      'full_name': fullName.trim(),
      'city_id': cityId.toString(),
    };
    // Si han escrito algo en contraseña, lo mandamos
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      body['password'] = newPassword.trim();
    }

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      Logger.error("Error actualizando gestor: ${response.body}", "SUPERADMIN");
      throw Exception('Error al actualizar la cuenta del gestor.');
    }
  }
}

@riverpod
SuperadminRepository superadminRepository(SuperadminRepositoryRef ref) {
  return SuperadminRepository();
}

@riverpod
Future<Map<String, dynamic>> superadminDashboardStats(SuperadminDashboardStatsRef ref) {
  return ref.watch(superadminRepositoryProvider).getGlobalStats();
}

@riverpod
Future<List<Map<String, dynamic>>> superadminCities(SuperadminCitiesRef ref) {
  final repository = ref.watch(superadminRepositoryProvider);
  return repository.getCities();
}