import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/core/widgets/error_view.dart';
import 'package:vive_core/features/admin/data/superadmin_repository.dart';

final superadminManagersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(superadminRepositoryProvider).getManagers();
});

class SuperadminManagersScreen extends ConsumerWidget {
  const SuperadminManagersScreen({super.key});

  // Este modal sirve tanto para CREAR (managerToEdit == null) como para EDITAR
  void _showManagerFormDialog(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> cities, {Map<String, dynamic>? managerToEdit}) {
    final bool isEditing = managerToEdit != null;
    final formKey = GlobalKey<FormState>();
    
    final nameCtrl = TextEditingController(text: isEditing ? managerToEdit['full_name'] : '');
    final emailCtrl = TextEditingController(text: isEditing ? managerToEdit['email'] : '');
    final passCtrl = TextEditingController(); // Siempre vacío por seguridad
    int? selectedCityId = isEditing ? managerToEdit['city_id'] : null;
    
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? "Editar Gestor" : "Nuevo Gestor de Franquicia"),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.contains('@') ? null : 'Correo inválido',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passCtrl,
                        decoration: InputDecoration(
                          labelText: isEditing ? 'Nueva Contraseña (Opcional)' : 'Contraseña Provisional', 
                          border: const OutlineInputBorder(),
                          helperText: isEditing ? 'Déjalo en blanco para mantener la actual' : null,
                        ),
                        obscureText: true,
                        validator: (v) {
                          if (!isEditing && v!.length < 6) return 'Mínimo 6 caracteres';
                          if (isEditing && v!.isNotEmpty && v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: selectedCityId,
                        decoration: const InputDecoration(labelText: 'Asignar a Franquicia', border: OutlineInputBorder()),
                        items: cities.map((c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['name'] ?? 'Ciudad ${c['id']}'),
                        )).toList(),
                        onChanged: (val) => selectedCityId = val,
                        validator: (v) => v == null ? 'Selecciona una franquicia' : null,
                      ),
                      if (isLoading) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator())
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setState(() => isLoading = true);
                  
                  try {
                    final repo = ref.read(superadminRepositoryProvider);
                    if (isEditing) {
                      await repo.updateManager(
                        managerId: managerToEdit['id'],
                        email: emailCtrl.text,
                        fullName: nameCtrl.text,
                        cityId: selectedCityId!,
                        newPassword: passCtrl.text,
                      );
                    } else {
                      await repo.createManager(
                        email: emailCtrl.text,
                        password: passCtrl.text,
                        fullName: nameCtrl.text,
                        cityId: selectedCityId!,
                      );
                    }
                    
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isEditing ? '✅ Gestor actualizado' : '✅ Gestor creado con éxito'), 
                        backgroundColor: Colors.green
                      ));
                      ref.invalidate(superadminManagersProvider);
                    }
                  } catch (e) {
                    Logger.error("Fallo guardando gestor: $e", "SUPERADMIN");
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                    setState(() => isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                child: Text(isEditing ? "Guardar Cambios" : "Crear Gestor"),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managersAsync = ref.watch(superadminManagersProvider);
    final citiesAsync = ref.watch(superadminCitiesProvider); // Lo reutilizamos de las ciudades

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestores de Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_manager', // Evita conflictos si hay varios FAB
        onPressed: () {
          if (citiesAsync.hasValue) {
            _showManagerFormDialog(context, ref, citiesAsync.value!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cargando franquicias...')));
          }
        },
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("Nuevo Gestor", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
      ),
      body: managersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(error: err, onRetry: () => ref.invalidate(superadminManagersProvider)),
        data: (managers) {
          if (managers.isEmpty) return const Center(child: Text("No hay gestores asignados aún."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: managers.length,
            itemBuilder: (context, index) {
              final manager = managers[index];
              final String cityName = manager['cities']?['name'] ?? 'ID: ${manager['city_id']}';
              final String email = manager['email'] ?? 'Sin correo';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: const Icon(Icons.manage_accounts, color: Colors.blue),
                  ),
                  title: Text(manager['full_name'] ?? 'Usuario sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_city, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("Franquicia: $cityName", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                        child: const Text("ADMIN", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          if (citiesAsync.hasValue) {
                            _showManagerFormDialog(context, ref, citiesAsync.value!, managerToEdit: manager);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}