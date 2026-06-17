import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/local_storage/local_db_service.dart';
import 'package:vive_core/features/scan/data/repositories/sync_service.dart';

part 'sync_provider.g.dart';

@riverpod
SyncService syncService(SyncServiceRef ref) {
  return SyncService(
    Supabase.instance.client,
    ref.watch(localDbServiceProvider),
  );
}