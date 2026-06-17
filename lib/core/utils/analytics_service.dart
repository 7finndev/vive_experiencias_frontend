import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/local_storage/local_db_service.dart';
import 'package:vive_core/core/utils/logger_service.dart';

class AnalyticsService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Registra el dispositivo. 
  /// [forceUserId]: Si se pasa, fuerza este ID (útil post-login).
  static Future<void> trackDeviceStart(LocalDbService localDb, {String? forceUserId}) async {
    try {
      final String deviceId = localDb.getDeviceUuid();
      
      // PRIORIDAD: 1. ID forzado (Login) -> 2. ID de sesión actual -> 3. Null
      final user = _supabase.auth.currentUser;
      final String? userId = forceUserId ?? user?.id;

      Logger.info("🔍 Analytics Debug: Intentando vincular Device $deviceId con User $userId", "ANALYTICS_SERVICE");

      String os = 'desconocido';
      String model = 'genérico';
      String osVersion = '';

      if (kIsWeb) {
        final WebBrowserInfo webInfo = await _deviceInfo.webBrowserInfo;
        final String userAgent = webInfo.userAgent?.toLowerCase() ?? '';

        if (userAgent.contains('android')) {
          os = 'android';
        } else if (userAgent.contains('iphone') || userAgent.contains('ipad')) {
          os = 'ios';
        } else if (userAgent.contains('macintosh') || userAgent.contains('mac os')) {
          os = 'macos';
        } else if (userAgent.contains('windows')) {
          os = 'windows';
        } else if (userAgent.contains('linux')) {
          os = 'linux';
        } else {
          os = 'web_other';
        }

        model = '${webInfo.browserName.name.toUpperCase()} (Web)';
        osVersion = webInfo.platform ?? 'pwa';

      } else {
        if (Platform.isAndroid) {
          os = 'android';
          final androidInfo = await _deviceInfo.androidInfo;
          model = "${androidInfo.brand} ${androidInfo.model}";
          osVersion = androidInfo.version.release;
        } else if (Platform.isIOS) {
          os = 'ios';
          final iosInfo = await _deviceInfo.iosInfo;
          model = iosInfo.utsname.machine;
          osVersion = iosInfo.systemVersion;
        } else {
          os = Platform.operatingSystem;
          model = 'Desktop Native'; 
        }
      }

      // Preparamos el mapa de datos
      final Map<String, dynamic> data = {
        'device_id': deviceId,
        'os': os.toLowerCase(),
        'model': model,
        'version': osVersion,
        'last_seen': DateTime.now().toIso8601String(),
      };

      // IMPORTANTE: Solo enviamos user_id si NO es nulo.
      // Si es nulo, no lo enviamos para no borrar uno existente por error,
      // aunque el upsert suele mezclar, mejor ser explícitos.
      if (userId != null) {
        data['user_id'] = userId;
      }

      await _supabase.from('analytics_devices').upsert(
        data,
        onConflict: 'device_id',
      );

      Logger.info("📊 Analytics: Dispositivo registrado ($os) -> User: $userId", "ANALYTICS_SERVICE");

    } catch (e) {
      Logger.error("⚠️ Error en Analytics: $e", "ANALYTICS_SERVICE");
    }
  }
}