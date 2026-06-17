import 'dart:io';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vive_core/core/utils/logger_service.dart';

part 'storage_service.g.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sube una imagen a un bucket específico
  /// [bucketName]: 'products', 'establishment', o 'events'
  Future<String?> uploadImage(XFile imageFile, String bucketName, String folder) async {
    try {
      // Limpiamos el nombre del archivo para evitar caracteres raros
      final fileExt = imageFile.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '$folder/$fileName';

      // 1. Subida para WEB
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        // Importante: definir contentType para que el navegador sepa que es una imagen
        await _supabase.storage.from(bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'), 
        );
      } 
      // 2. Subida para NATIVO
      else {
        final file = File(imageFile.path);
        await _supabase.storage.from(bucketName).upload(
          path, 
          file,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );
      }

      // 3. Obtener URL Pública
      final imageUrl = _supabase.storage.from(bucketName).getPublicUrl(path);
      return imageUrl;

    } catch (e) {
      Logger.error("❌ Error subiendo imagen al bucket $bucketName: $e", "STORAGE_SERVICE");
      return null;
    }
  }
}

// Provider de Riverpod
@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService();
}