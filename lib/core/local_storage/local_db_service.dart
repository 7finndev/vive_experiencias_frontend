import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'dart:io' show Platform, Directory;

import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/home/data/models/event_model.dart';
import 'package:vive_core/features/home/data/models/product_item_model.dart';
import 'package:vive_core/features/scan/data/models/passport_entry_model.dart';
import 'package:vive_core/features/home/data/models/product_model.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'local_db_service.g.dart';

class LocalDbService {
  // Nombres de las cajas existentes
  static const String establishmentsBoxName = 'establishments_box';
  static const String eventsBoxName = 'events_box';
  static const String pendingVotesBoxName = 'pending_votes_box';
  static const String syncedStampsBoxName = 'synced_stamps_box';
  static const String productsBoxName = 'products_box';

  // --- NUEVAS CAJAS PARA CACHÉ ---
  static const String eventsCacheBoxName = 'cache_events_raw';
  static const String sponsorsCacheBoxName = 'cache_sponsors_raw';
  
  // --- CAJA PARA DEVICES ---
  static const String appSettingsBoxName = 'app_settings_box';

  Future<void> init() async {
    // --- LÓGICA DE INICIALIZACIÓN HÍBRIDA ---
    if (kIsWeb) {
      await Hive.initFlutter();
      Logger.info("🌐 Base de datos iniciada en Navegador (IndexedDB)", "LOCAL_DB");
    } else {
      Directory dir;
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        dir = await getApplicationSupportDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      await Hive.initFlutter(dir.path);
      Logger.info("📂 Base de datos local guardada en: ${dir.path}", "LOCAL_DB");
    }

    // --- REGISTRO DE ADAPTADORES ---
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(EstablishmentModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(EventModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ProductModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ProductItemModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(PassportEntryModelAdapter());

    // --- ABRIR CAJAS EXISTENTES ---
    await _openBoxSafely(establishmentsBoxName);
    await _openBoxSafely(eventsBoxName);
    await _openBoxSafely(pendingVotesBoxName);
    await _openBoxSafely(syncedStampsBoxName);
    await _openBoxSafely(productsBoxName);
    await _openBoxSafely(appSettingsBoxName);

    // --- ABRIR CAJAS DE CACHÉ ---
    await _openBoxSafely(eventsCacheBoxName);
    await _openBoxSafely(sponsorsCacheBoxName);
    
    Logger.info("✅ Local Database initialized.", "LOCAL_DB");
  }

  Future<void> _openBoxSafely(String boxName) async {
    try {
      await Hive.openBox(boxName);
    } catch (e) {
        Logger.error('⚠️ Error crítico abriendo "$boxName": $e', "LOCAL_DB");
        Logger.info('🗑️ Procediendo a eliminar y recrear la caja...', "LOCAL_DB");
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (eDelete) {
        Logger.warning('ℹ️ No se pudo borrar la caja: $eDelete', "LOCAL_DB");
      }
      try {
        await Hive.openBox(boxName);
        Logger.info('✅ Caja "$boxName" recreada con éxito.', "LOCAL_DB");
      } catch (e2) {
        Logger.error('❌ ERROR FATAL: No se pudo recrear la caja "$boxName": $e2', "LOCAL_DB");
      }
    }
  }

  // Getters existentes
  Box get establishmentsBox => Hive.box(establishmentsBoxName);
  Box get eventsBox => Hive.box(eventsBoxName);
  Box get pendingVotesBox => Hive.box(pendingVotesBoxName);
  Box get syncedStampsBox => Hive.box(syncedStampsBoxName);
  Box get productsBox => Hive.box(productsBoxName);

  Box get _appSettingsBox => Hive.box(appSettingsBoxName);

  // --- GETTERS Y MÉTODOS DE CACHÉ ---
  Box get _eventsCacheBox => Hive.box(eventsCacheBoxName);
  Box get _sponsorsCacheBox => Hive.box(sponsorsCacheBoxName);

  // MÉTODO OBTENER/CREAR ID DISPOSITIVO:
  String getDeviceUuid() {
    //.-Buscamos si ya tiene identificador
    String? deviceId = _appSettingsBox.get('device_uuid');

    //.-Se lo creamos si no tiene:
    if(deviceId == null){
      deviceId = const Uuid().v4();
      _appSettingsBox.put('device_uuid', deviceId);
      Logger.info("🆕 Asignado nuevo Device ID: $deviceId", "LOCAL_DB");
    } else {
      Logger.info("🆔 Device ID recuperado: $deviceId", "LOCAL_DB");
    }
    return deviceId;
  }
  
  // 1. CACHÉ DE EVENTOS
  Future<void> cacheEvents(List<Map<String, dynamic>> eventsJson) async {
    // Guardamos la lista completa bajo una sola clave 'all'
    await _eventsCacheBox.put('all', eventsJson);
    // Guardamos fecha de actualización (opcional, por si quieres expirar caché)
    await _eventsCacheBox.put('timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> getCachedEvents() {
    final data = _eventsCacheBox.get('all');
    if (data != null) {
      // Convertimos dynamic a List<Map>
      return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  // 2. CACHÉ DE PATROCINADORES
  Future<void> cacheSponsors(List<Map<String, dynamic>> sponsorsJson) async {
    await _sponsorsCacheBox.put('all', sponsorsJson);
  }

  List<Map<String, dynamic>> getCachedSponsors() {
    final data = _sponsorsCacheBox.get('all');
    if (data != null) {
      return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }
}

@Riverpod(keepAlive: true)
LocalDbService localDbService(LocalDbServiceRef ref) {
  return LocalDbService();
}