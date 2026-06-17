import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/features/auth/data/datasources/auth_service.dart';
import 'package:vive_core/features/auth/data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// 1. Proveedor del Servicio
@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService(Supabase.instance.client);
}

// 2. Proveedor del Repositorio
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final service = ref.watch(authServiceProvider);
  return AuthRepository(service);
}

// 3. Proveedor del Usuario Actual (Stream)
// Esto permitirá que la UI reaccione automáticamente si el usuario entra o sale
@riverpod
Stream<User?> authState(AuthStateRef ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges.map((event) => event.session?.user);
}

// 4. Provider para obtener el ROL del usuario (Admin/User)
@riverpod
Future<String> userRole(UserRoleRef ref) async {
  // Obtenemos el usuario actual de Supabase
  final user = Supabase.instance.client.auth.currentUser;
  
  if (user == null) return 'guest'; // Si no está logueado, es invitado

  // Consultamos la tabla profiles
  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return response?['role'] as String? ?? 'user';
  } catch (e) {
    return 'user'; // Si falla, por seguridad devolvemos usuario normal
  }
}

// 5. Provider para obtener el PERFIL COMPLETO de base de datos (Avatar, Nombre real)
// Este es el que usaremos en el Drawer para que salga la foto buena.
@riverpod
Future<Map<String, dynamic>?> userProfile(UserProfileRef ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  
  if (user == null) return null;

  // Escuchamos cambios en el repositorio para que se actualice si editamos el perfil
  // (Opcional, pero recomendado si quieres reactividad total)
  // ref.watch(authStateProvider); 

  final response = await Supabase.instance.client
      .from('profiles')
      .select() // Trae todas las columnas (avatar_url, full_name, role...)
      .eq('id', user.id)
      .maybeSingle();

  return response;
}