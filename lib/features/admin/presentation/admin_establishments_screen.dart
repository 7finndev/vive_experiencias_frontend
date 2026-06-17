import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/home/data/repositories/establishment_repository.dart';
// Ya no necesitamos importar la pantalla del formulario directamente
// import 'establishment_form_screen.dart'; 

// Provider simple para listar socios (se auto-refresca)
final adminEstablishmentsListProvider = FutureProvider.autoDispose<List<EstablishmentModel>>((ref) async {
  return ref.read(establishmentRepositoryProvider).getAllEstablishments();
});

class AdminEstablishmentsScreen extends ConsumerStatefulWidget {
  const AdminEstablishmentsScreen({super.key});

  @override
  ConsumerState<AdminEstablishmentsScreen> createState() => _AdminEstablishmentsScreenState();
}

class _AdminEstablishmentsScreenState extends ConsumerState<AdminEstablishmentsScreen> {
  
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = "";

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final establishmentsAsync = ref.watch(adminEstablishmentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Socios'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Buscar por nombre, dueño...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none
                ),
                suffixIcon: _searchText.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchText = "");
                      },
                    ) 
                  : null,
              ),
              onChanged: (val) {
                setState(() => _searchText = val.toLowerCase());
              },
            ),
          ),
        ),
      ),
      
      // BOTÓN FLOTANTE CORREGIDO CON GOROUTER
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_establishment', // Evita conflictos si hay varios FAB
        icon: const Icon(Icons.add),
        label: const Text('NUEVO SOCIO'),
        // Usamos el color del tema (Naranja) en lugar de hardcodear BlueGrey
        backgroundColor: Theme.of(context).primaryColor, 
        foregroundColor: Colors.white,
        onPressed: () async {
          // 1. Usamos GoRouter para ir a la ruta definida en app_router.dart
          // 'await' espera a que volvamos de esa pantalla (pop)
          await context.push('/admin/socios/nuevo');
          
          // 2. Al volver, invalidamos el provider para forzar la recarga de la lista
          // (invalidate es más moderno que refresh en las últimas versiones de Riverpod)
          ref.invalidate(adminEstablishmentsListProvider);
        },
      ),
      
      body: establishmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (establishments) {
          
          final filteredList = establishments.where((e) {
            final name = e.name.toLowerCase();
            final owner = e.ownerName?.toLowerCase() ?? '';
            return _searchText.isEmpty || 
                   name.contains(_searchText) || 
                   owner.contains(_searchText);
          }).toList();

          if (filteredList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 50, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text('No se encontraron socios con "$_searchText".'),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), 
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final bar = filteredList[index];
              
              // TRUCO ANTI-CACHÉ (Para que si cambias el logo se vea al instante)
              final String? imageUrl = bar.coverImage != null 
                  ? "${bar.coverImage!}?t=${DateTime.now().millisecondsSinceEpoch}"
                  : null;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  
                  // --- AQUÍ ESTÁ EL CAMBIO DE IMAGEN ---
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white, // Fondo blanco por si la foto no es cuadrada
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300), // Borde elegante
                    ),
                    child: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              // 🔥 EL SECRETO: 'contain' muestra TODA la imagen sin recortar
                              fit: BoxFit.contain, 
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image, color: Colors.grey);
                              },
                            ),
                          )
                        : Icon(
                            Icons.store, 
                            color: bar.isPartner ? Colors.orange[800] : Colors.grey,
                            size: 30,
                          ),
                  ),
                  // -------------------------------------
                  title: Text(
                    bar.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bar.ownerName ?? bar.address ?? 'Sin datos'),
                      if (bar.isPartner)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4)
                          ),
                          child: const Text("ACTIVO", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  
                  onTap: (){
                    context.push('/admin/socios/detail', extra: bar);
                  },

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, ref, bar),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, EstablishmentModel bar) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar Socio?'),
        content: Text('Vas a eliminar a "${bar.name}". Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancelar')
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(establishmentRepositoryProvider).deleteEstablishment(bar.id);
              // Usamos invalidate para recargar
              ref.invalidate(adminEstablishmentsListProvider);
            },
            child: const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}