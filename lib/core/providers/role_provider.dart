import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/utils/logger_service.dart';

// 🔥 AHORA ESCUCHA LOS CAMBIOS DE SESIÓN
final userRoleProvider = FutureProvider<String?>((ref) async {
  // Suscribirse a los cambios de autenticación
  // (Si cambias esto, asegúrate de tener authStateChangesProvider u obtener la sesión)
  final session = Supabase.instance.client.auth.currentSession;
  final user = session?.user;
  
  if (user == null) {
    Logger.info('👤 RoleProvider: No hay usuario logueado.', 'ROLE_PROVIDER');
    return null;
  }

  try {
    Logger.info('👤 RoleProvider: Buscando rol para el usuario ${user.id}...', 'ROLE_PROVIDER');
    final data = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    
    Logger.info('✅ RoleProvider: Rol encontrado -> ${data['role']}', 'ROLE_PROVIDER');
    return data['role'] as String?;
    
  } catch (e) {
    // AHORA SÍ GRITAMOS EL ERROR EN LA CONSOLA
    Logger.error('❌ RoleProvider ERROR: No se pudo obtener el perfil: $e', 'ROLE_PROVIDER');
    return 'user'; // Devolvemos user por seguridad, pero ya sabemos por qué falló
  }
});