import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/utils/logger_service.dart'; 

import 'package:vive_core/features/home/data/models/event_model.dart';
import 'package:vive_core/core/constants/app_data.dart'; // NUEVO: URL de FastAPI

part 'dashboard_repository.g.dart';

class DashboardStats {
  final int totalScans;
  final int totalUsers;
  final int activeProducts;
  final int activeEstablishments;
  final Map<String, int> languages; 
  final int countProducts; 
  final int countDrinks;   
  final int countShopping; 
  final int deviceAndroid;
  final int deviceIOS;
  final int deviceDesktop; 
  final int deviceWeb;

  DashboardStats({
    required this.totalScans,
    required this.totalUsers,
    required this.activeProducts,
    required this.activeEstablishments,
    required this.countProducts,
    required this.countDrinks,
    required this.countShopping,
    required this.deviceAndroid,
    required this.deviceIOS,
    required this.deviceDesktop, 
    required this.deviceWeb,
    required this.languages,
  });

  // NUEVO: Factory para crear el objeto desde el JSON que manda FastAPI
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalScans: json['totalScans'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      activeEstablishments: json['activeEstablishments'] ?? 0,
      countProducts: json['countProducts'] ?? 0,
      countDrinks: json['countDrinks'] ?? 0,
      countShopping: json['countShopping'] ?? 0,
      deviceAndroid: json['deviceAndroid'] ?? 0,
      deviceIOS: json['deviceIOS'] ?? 0,
      deviceDesktop: json['deviceDesktop'] ?? 0,
      deviceWeb: json['deviceWeb'] ?? 0,
      languages: Map<String, int>.from(json['languages'] ?? {}),
    );
  }
}

class DashboardRepository {
  DashboardRepository();

  Future<DashboardStats> getStats({int? eventId}) async {
    try {
      // 1. EXTRAEMOS EL TOKEN DE SEGURIDAD
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) throw Exception('No hay sesión activa.');

      // 2. Montamos la URL
      String urlString = '${AppData.apiUrl}/api/v1/admin/dashboard';
      if (eventId != null) {
        urlString += '?event_id=$eventId';
      }

      Logger.info('📊 Pidiendo estadísticas a FastAPI: $urlString', 'DASHBOARD_REPOSITORY');
      final url = Uri.parse(urlString);
      
      // 3. ENVIAMOS LA PETICIÓN CON EL TOKEN EN LA CABECERA
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // 🔥 EL PASAPORTE DEL USUARIO
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return DashboardStats.fromJson(jsonResponse);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error("❌ Error cargando el dashboard B2B: $e", "DASHBOARD_REPOSITORY");
      return DashboardStats(
        totalScans: 0, totalUsers: 0, activeProducts: 0, activeEstablishments: 0,
        countProducts: 0, countDrinks: 0, countShopping: 0, deviceAndroid: 0,
        deviceIOS: 0, deviceDesktop: 0, deviceWeb: 0, languages: {},
      );
    }
  }
}

// --- PROVIDERS ---

@riverpod
DashboardRepository dashboardRepository(DashboardRepositoryRef ref) {
  return DashboardRepository(); // Ya no necesita Supabase directo
}

final dashboardSelectedEventProvider = StateProvider<EventModel?>((ref) => null);

@riverpod
Future<DashboardStats> dashboardStats(DashboardStatsRef ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final selectedEvent = ref.watch(dashboardSelectedEventProvider);
  return repo.getStats(eventId: selectedEvent?.id);
}