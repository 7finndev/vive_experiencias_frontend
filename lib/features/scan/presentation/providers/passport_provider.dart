import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';
import 'package:vive_core/features/scan/data/models/passport_entry_model.dart';
// IMPORTANTE: Importar el auth provider
import 'package:vive_core/features/auth/presentation/providers/auth_provider.dart';

part 'passport_provider.g.dart';

@riverpod
Future<List<PassportEntryModel>> passport(PassportRef ref, int eventId) async {
  // 1. VIGILANCIA: Hacemos que este provider dependa del usuario logueado.
  // Si el usuario cambia (login/logout), este provider se "autodestruye" y recarga.
  ref.watch(authStateProvider);

  final repository = ref.read(passportRepositoryProvider);
  
  // 2. Obtenemos los datos
  return repository.getPassportEntries(eventId);
}


@riverpod
bool hasStamp(HasStampRef ref, {required int establishmentId, required int eventId}) {
  // Escuchamos el provider principal que ya tienes creado
  final passportAsync = ref.watch(passportProvider(eventId));
  
  return passportAsync.when(
    data: (list) {
      // Comprobamos si en la lista hay algún sello con ese ID de establecimiento
      return list.any((entry) => entry.establishmentId == establishmentId);
    },
    error: (_, _) => false,
    loading: () => false,
  );
}