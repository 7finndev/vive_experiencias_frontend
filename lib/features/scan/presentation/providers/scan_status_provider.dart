import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vive_core/core/local_storage/local_db_service.dart';
import 'package:vive_core/features/scan/data/models/passport_entry_model.dart';

part 'scan_status_provider.g.dart';

// AHORA PEDIMOS TAMBIÉN EL ID DEL EVENTO
@riverpod
bool hasStamp(HasStampRef ref, {required int establishmentId, required int eventId}) {
  final pendingBox = Hive.box(LocalDbService.pendingVotesBoxName);
  final syncedBox = Hive.box(LocalDbService.syncedStampsBoxName);

  // Función de comprobación estricta (Bar + Evento)
  bool check(Box box) {
    return box.values.cast<PassportEntryModel>().any((entry) => 
      entry.establishmentId == establishmentId && 
      entry.eventId == eventId // <--- EL FILTRO QUE FALTABA
    );
  }

  return check(pendingBox) || check(syncedBox);
}