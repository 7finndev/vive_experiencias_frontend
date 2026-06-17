import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';
// import 'package:vive_core/core/utils/smart_image_container.dart'; // Ya no lo usaremos aquí directamente para tener más control
import 'package:vive_core/core/widgets/error_view.dart';

class TapasListScreen extends ConsumerWidget {
  const TapasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsListProvider);
    final establishmentsAsync = ref.watch(establishmentsListProvider);

    void reloadAll(){
      ref.invalidate(currentEventProvider);
      ref.invalidate(productsListProvider);
      ref.invalidate(establishmentsListProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Galería de Productos")),
      body: RefreshIndicator(
        color: Colors.orange,
        onRefresh: () async {
          reloadAll();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          
          error: (err, stack) => ErrorView(
            error: err,
            onRetry: () {
              reloadAll();
            },
          ),

          data: (tapas) {
            if (tapas.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                   SizedBox(height: 100),
                   Center(child: Text("No hay productos cargados.")),
                ],
              );
            }

            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              
              // 1. SOLUCIÓN PAISAJE (RESPONSIVE)
              // En lugar de "FixedCrossAxisCount" (siempre 2), usamos "MaxCrossAxisExtent".
              // Esto dice: "Cada tarjeta debe medir como MÁXIMO 200px de ancho".
              // - En vertical (pantalla ~380px): Caben 2 tarjetas.
              // - En paisaje (pantalla ~800px): Caben 4 tarjetas (no se ven gigantes).
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,//220, 
                childAspectRatio: 0.75, // Un poco más altas para que quepa el texto
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              
              itemCount: tapas.length,
              itemBuilder: (context, index) {
                final tapa = tapas[index];
                
                final establishments = establishmentsAsync.value ?? [];
                final bar = establishments.firstWhere(
                  (e) => e.id == tapa.establishmentId,
                  orElse: () => EstablishmentModel(id: -1, name: "Local Desconocido", qrUuid: "", isActive: false),
                );

                return GestureDetector(
                  onTap: () {
                    if (bar.id != -1) {
                      context.push('/detail', extra: bar);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0,4))
                      ],
                    ),
                    child: Column(
                      // 2. SOLUCIÓN ALINEACIÓN IZQUIERDA
                      // Esto obliga a que los hijos (la imagen) ocupen todo el ancho disponible
                      crossAxisAlignment: CrossAxisAlignment.stretch, 
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Stack(
                              fit: StackFit.expand, // Obliga a la imagen a llenar el hueco
                              children: [
                                // Fondo para rellenar (por si la imagen no encaja)
                                Image.network(
                                  tapa.imageUrl ?? "",
                                  fit: BoxFit.cover,
                                  errorBuilder: (c,o,s) => Container(color: Colors.grey[200]),
                                ),
                                // (Opcional) Si quieres que se vean completas sin recortar,
                                // puedes descomentar esto, pero en grids pequeños suele quedar mejor 'cover'.
                                // Si prefieres verla entera centrada como en el detalle, cambia el fit de arriba
                                // a BoxFit.cover y añade un Container negro semitransparente encima.
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tapa.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bar.name, 
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (tapa.price != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "${tapa.price}€",
                                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}