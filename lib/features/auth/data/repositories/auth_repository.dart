// NECESARIO para Uint8List
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/features/auth/data/datasources/auth_service.dart';

class AuthRepository {
  final AuthService _authService;
  final SupabaseClient _client = Supabase.instance.client;

  AuthRepository(this._authService);

  Future<void> signIn(String email, String password) async {
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _authService.signUp(email, password);
    } catch (e) {
      throw Exception('Error al registrarse: $e');
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  User? get currentUser => _authService.currentUser;
  
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  // --- ACTUALIZAR PERFIL (VERSIÓN BYTES) ---
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
    Uint8List? imageBytes,
  }) async {
    final updates = <String, dynamic>{};
    
    // 1. Preparamos los datos de texto
    if (name != null) {
      updates['full_name'] = name; 
      updates['name'] = name; 
    }
    if (phone != null) {
      updates['phone'] = phone;
    }

    // 2. Si hay imagen nueva (BYTES), la subimos
    if (imageBytes != null) {
      final fileName = '$userId/avatar.jpg'; 

      try {
        await _client.storage.from('avatars').uploadBinary(
          fileName,
          imageBytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg', 
          ),
        );

        final imageUrl = _client.storage.from('avatars').getPublicUrl(fileName);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        updates['avatar_url'] = "$imageUrl?t=$timestamp";
        
      } catch (e) {
        Logger.error('Error subiendo imagen al servidor: $e', "AUTH");
        throw 'Error subiendo imagen al servidor: $e';
      }
    }

    // 3. Actualizamos el usuario en Supabase Auth
    if (updates.isNotEmpty) {
      final UserResponse res = await _client.auth.updateUser(
        UserAttributes(
          data: updates, 
        ),
      );
      
      if (res.user == null) {
        throw 'No se pudo actualizar el perfil en la base de datos';
      }

      try {
        // 👇 SOLUCIÓN: Usar "if" de colección en lugar de "?variable"
        //final Map<String, dynamic> profileUpdates = {
        //  'full_name': ?name,
        //  'phone': ?phone,
        //  if (updates.containsKey('avatar_url')) 'avatar_url': updates['avatar_url'],
        //  'updated_at': DateTime.now().toIso8601String(),
        //};
        //El codigo de arriba siempre se pone aunque lo corrija
        //Ahora cuando vuelva a "descorregirse" tengo
        // en comentario el codigo correcto y corregido para asi
        //  no tener que volver a buscarlo.
        final Map<String, dynamic> profileUpdates = {
          if (name != null) 'full_name': name,
          if (phone != null) 'phone': phone,
          if (updates.containsKey('avatar_url')) 'avatar_url': updates['avatar_url'],
          'updated_at': DateTime.now().toIso8601String(),
        };
        /* De todas formas lo dejo guardado en comentarios:
        final Map<String, dynamic> profileUpdates = {
          if (name != null) 'full_name': name,
          if (phone != null) 'phone': phone,
          if (updates.containsKey('avatar_url')) 'avatar_url': updates['avatar_url'],
          'updated_at': DateTime.now().toIso8601String(),
        };
        */

        await _client
          .from('profiles')
          .update(profileUpdates)
          .eq('id', userId);
      } catch (e) {
        Logger.error('⚠️ Error al actualizar la tabla profiles: $e', "AUTH");
        throw 'Error al guardar los datos públicos: $e';
      }
    }
  }

  // --- RECUPERACIÓN DE CONTRASEÑAS ---
  //.-Enviar correo con enlace mágico:
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      //Determinamos a dónde volverá el usuario
      //En Web: localhost o tu dominio real
      //En móvil: io.supabase.flutter://reset-callback/ (Debes configurar Deep Links si no lo has hecho)
      //Por ahora, usaremos una redirección genérica que funciona bien en la mayoria de los casos.
      String redirectUrl;
      if(kIsWeb){
        //Si estamos depuranbdo en local --> localhost:3000
        //Si estamos en producción --> acet.universoweb.pro
        redirectUrl = kDebugMode
          ? 'http://localhost:3000/update-password'
          : 'https://acet.universoweb.pro/update-password';
      } else {
        //Para Android/ios (Deep Link)
        redirectUrl = 'es.sietefinn.appvivetorredelmar://login-callback/';
      }

      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );
    } catch (e) {
      throw Exception('Error enviando correo de recuperación: $e');
    }
  }

  //.-Guardar nueva contraseña (mediante link):
  Future<void> updateUserPassword(String newPassword) async{
    try{
      final res = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if(res.user == null) throw 'No se pudo actualizar la contraseña';
    } catch (e) {
      throw Exception ('Error actualizando contraseña: $e');
    }
  }
}