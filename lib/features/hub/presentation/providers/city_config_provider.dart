import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';

part 'city_config_provider.g.dart';

// 📱 1. PROVIDER PARA EL TURISTA (Reacciona al Hub público)
@riverpod
Future<Map<String, dynamic>> cityConfig(CityConfigRef ref) async {
  final cityId = ref.watch(currentCityIdProvider); 
  return _fetchConfigData(cityId);
}

// 👑 2. PROVIDER PARA EL ADMINISTRADOR (Aislado de la navegación del turista)
@riverpod
Future<Map<String, dynamic>> adminCityConfig(AdminCityConfigRef ref) async {
  try {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return {};

    // Buscamos directamente la franquicia asignada al perfil del administrador
    final profile = await supabase.from('profiles').select('city_id').eq('id', user.id).maybeSingle();
    final adminCityId = profile?['city_id'] ?? 1;

    return _fetchConfigData(adminCityId);
  } catch (e) {
    Logger.error("Error en adminCityConfig: $e", "CITY_CONFIG");
    return {};
  }
}

// 🌐 HELPER PRIVADO COMPARTIDO (Crea copias mutables a prueba de fallos)
Future<Map<String, dynamic>> _fetchConfigData(int cityId) async {
  try {
    final supabase = Supabase.instance.client;
    // 1. Intentamos traer la configuración completa
    final data = await supabase.from('app_config').select('*, cities(name)').eq('city_id', cityId).maybeSingle();

    if (data != null) {
      final mutableMap = Map<String, dynamic>.from(data);
      String resolvedName = 'Experiencias';
      if (mutableMap['cities'] != null && mutableMap['cities'] is Map) {
        resolvedName = mutableMap['cities']['name']?.toString() ?? 'Experiencias';
      } else if (mutableMap['org_name'] != null) {
        resolvedName = mutableMap['org_name'].toString();
      }
      mutableMap['resolved_city_name'] = resolvedName;
      return mutableMap;
    }

    // 2. SALVAVIDAS EXTREMO: Si no hay config, al menos sacamos el nombre de la tabla cities
    final fallbackCity = await supabase.from('cities').select('name').eq('id', cityId).maybeSingle();
    final fallbackName = fallbackCity?['name'] ?? 'Experiencias';
    
    return {
      'primary_color': '#121212',
      'logo_url': '',
      'resolved_city_name': fallbackName, // Ahora sí dirá "Nerja" aunque no tenga configuración!
    };
  } catch (e) {
    Logger.error("Error procesando _fetchConfigData para $cityId: $e", "CITY_CONFIG");
    return {'primary_color': '#121212', 'logo_url': '', 'resolved_city_name': 'Experiencias'};
  }
}