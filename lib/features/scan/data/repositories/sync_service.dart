import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/local_storage/local_db_service.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/scan/data/models/passport_entry_model.dart';

part 'sync_service.g.dart';

class SyncService {
  final SupabaseClient _supabase;
  final LocalDbService _localDb;

  SyncService(this._supabase, this._localDb);

  Future<int> syncPendingVotes({int? targetEventId}) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return 0;

    final pendingBox = _localDb.pendingVotesBox;
    final syncedBox = _localDb.syncedStampsBox;
    final establishmentsBox = _localDb.establishmentsBox; 

    int uploadedCount = 0;
    final keysToDelete = <dynamic>[];

    // =========================================================
    // ⬆️ PASO 1: SUBIDA (Móvil -> Nube) 
    // Buscamos en event_products (El PADRE)
    // =========================================================
    for (var key in pendingBox.keys) {
      final entry = pendingBox.get(key) as PassportEntryModel;

      if (!entry.isSynced) {
        try {
          // Buscamos el producto principal asociado al bar y al evento
          final productData = await _supabase
              .from('event_products') 
              .select('id')
              .eq('establishment_id', entry.establishmentId)
              .eq('event_id', entry.eventId)
              .maybeSingle();

          if (productData == null) {
            Logger.error("⚠️ Error: No existe producto activo para el bar ${entry.establishmentName}", "SYNC_SERVICE");
            // Si no existe el producto, no podemos asignar el voto. Lo descartamos.
            keysToDelete.add(key);
            continue;
          }

          final int realProductId = productData['id'];

          await _supabase.from('passport_entries').insert({
            'user_id': currentUser.id,
            'product_id': realProductId,
            'event_id': entry.eventId,
            'scanned_at': entry.scannedAt.toIso8601String(),
            'gps_verified': true, 
            'rating': entry.rating, 
          });

          // Mover a la caja de sincronizados
          final syncedEntry = PassportEntryModel(
             establishmentId: entry.establishmentId,
             establishmentName: entry.establishmentName,
             scannedAt: entry.scannedAt,
             isSynced: true, // Marcamos como subido
             rating: entry.rating,
             eventId: entry.eventId,
          );
          
          final String uniqueKey = "${entry.eventId}_${entry.establishmentId}";
          await syncedBox.put(uniqueKey, syncedEntry);
          
          keysToDelete.add(key);
          uploadedCount++;
          Logger.info("✅ Voto sincronizado: ${entry.establishmentName}", "SYNC_SERVICE");

        } catch (e) {
          Logger.error("⚠️ Error subiendo voto ${entry.establishmentName}: $e", "SYNC_SERVICE");
          // Si es duplicado (ya votó antes), lo borramos de pendientes
          if (e.toString().contains("duplicate key") || e.toString().contains("23505")) {
             keysToDelete.add(key);
          }
        }
      }
    }
    // Borramos los pendientes procesados
    await pendingBox.deleteAll(keysToDelete);


    // =========================================================
    // ⬇️ PASO 2: BAJADA (Nube -> Móvil)
    // Usamos la relación con event_products
    // =========================================================
    try {
      Logger.info("⬇️ Descargando historial...", "SYNC_SERVICE");
      
      // Consulta con Relación Anidada:
      // passport_entries -> event_products -> establishments
      var query = _supabase
        .from('passport_entries')
        .select('''
          *,
          product:event_products (
            establishment_id,
            establishment:establishments (name)
          )
        ''') 
        .eq('user_id', currentUser.id);

      if(targetEventId != null){
        query = query.eq('event_id', targetEventId);
      }
      
      final response = await query;
      final List<dynamic> cloudEntries = response as List<dynamic>;

      // Limpiamos locales antiguos para evitar duplicados visuales
      if(targetEventId != null) {
        final keysToRemove = syncedBox.keys.where((key) {
          final entry = syncedBox.get(key);
          return entry != null && entry.eventId == targetEventId;
        }).toList();
        await syncedBox.deleteAll(keysToRemove);
      } else {
        await syncedBox.clear();
      }

      for (var item in cloudEntries) {
        final String scannedAtStr = item['scanned_at'];
        final int rating = item['rating'] ?? 0;
        final int eventId = item['event_id'] ?? 1;
        
        // Extraemos datos anidados
        final productData = item['product']; 
        
        int establishmentId = 0;
        String cloudBarName = ""; 

        if (productData != null) {
           establishmentId = productData['establishment_id'];
           
           final establishmentData = productData['establishment'];
           if (establishmentData != null) {
             cloudBarName = establishmentData['name'] ?? "";
           }
        } else {
           // Si falla la relación (datos corruptos antiguos), usamos el ID directo
           establishmentId = item['product_id'] ?? 0;
        }

        // Buscamos nombre bonito
        String finalBarName = cloudBarName;
        if (finalBarName.isEmpty) {
           try {
             final match = establishmentsBox.values.cast<EstablishmentModel>().firstWhere(
               (e) => e.id == establishmentId,
             );
             finalBarName = match.name;
           } catch (_) {
             finalBarName = "Local #$establishmentId";
           }
        }

        final downloadedEntry = PassportEntryModel(
          establishmentId: establishmentId,
          establishmentName: finalBarName, 
          scannedAt: DateTime.parse(scannedAtStr),
          isSynced: true,
          rating: rating,
          eventId: eventId,
        );

        final String uniqueKey = "${eventId}_$establishmentId";
        await syncedBox.put(uniqueKey, downloadedEntry);
      }
      
      Logger.info("✅ Sincronización completada. ${cloudEntries.length} votos recuperados.", "SYNC_SERVICE");

    } catch (e) {
      Logger.error("⚠️ Error bajando historial: $e", "SYNC_SERVICE");
    }

    return uploadedCount;
  }
}

@riverpod
SyncService syncService(SyncServiceRef ref) {
  return SyncService(
    Supabase.instance.client,
    ref.watch(localDbServiceProvider), 
  );
}