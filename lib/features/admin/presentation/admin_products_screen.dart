import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Imports de Modelos
import 'package:vive_core/features/home/data/models/event_model.dart';
import 'package:vive_core/features/home/data/models/product_model.dart';
import 'package:vive_core/features/home/data/repositories/product_repository.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';

// Import del Provider
import 'providers/admin_products_providers.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = "";

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminEventsListProvider);
    final selectedEvent = ref.watch(selectedEventFilterProvider);
    final productsAsync = ref.watch(adminProductsByEventProvider);

    // 🔥 ELIMINADO: Ya no necesitamos bajar todos los bares aquí. FastAPI hace el trabajo.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Buscar tapa, cóctel...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
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
              onChanged: (val) =>
                  setState(() => _searchText = val.toLowerCase()),
            ),
          ),
        ),
      ),

      floatingActionButton: selectedEvent == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab_add_product', // Evita conflictos si hay varios FAB
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Producto'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () async {
                await context.pushNamed(
                  'product_form',
                  extra: {'eventId': selectedEvent.id},
                );
                ref.invalidate(adminProductsByEventProvider);
              },
            ),

      body: Column(
        children: [
          // ZONA SUPERIOR: FILTRO DE EVENTOS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: eventsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('Error cargando lista de eventos'),
              data: (events) {
                if (events.isEmpty) {
                  return const Text('Primero debes crear un Evento.');
                }

                if (selectedEvent == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    try {
                      final activeEvent = events.firstWhere(
                        (e) => e.status == 'active',
                        orElse: () => events.first,
                      );
                      ref.read(selectedEventFilterProvider.notifier).state =
                          activeEvent;
                    } catch (_) {}
                  });
                }

                EventModel? safeValue;
                if (selectedEvent != null) {
                  try {
                    safeValue = events.firstWhere(
                      (e) => e.id == selectedEvent.id,
                    );
                  } catch (_) {
                    safeValue = null;
                    Future.microtask(
                      () =>
                          ref.read(selectedEventFilterProvider.notifier).state =
                              null,
                    );
                  }
                }

                return DropdownButtonFormField<EventModel>(
                  decoration: const InputDecoration(
                    labelText: 'Selecciona el Evento a gestionar',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  initialValue: safeValue,
                  isExpanded: true,
                  items: events.map((event) {
                    return DropdownMenuItem(
                      value: event,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getStatusColor(event.status),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: event.status == 'archived'
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newEvent) {
                    ref.read(selectedEventFilterProvider.notifier).state =
                        newEvent;
                  },
                );
              },
            ),
          ),

          // ZONA CENTRAL: LISTA DE PRODUCTOS
          Expanded(
            child: selectedEvent == null
                ? _buildEmptyState('👆 Selecciona un evento arriba')
                : productsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                    data: (products) {
                      if (products.isEmpty) {
                        return _buildEmptyState(
                          'No hay productos en este evento.\n¡Añade la primera!',
                        );
                      }

                      final filteredProducts = products.where((p) {
                        return _searchText.isEmpty ||
                            p.name.toLowerCase().contains(_searchText);
                      }).toList();

                      if (filteredProducts.isEmpty) {
                        return _buildEmptyState(
                          'No se encontraron productos con ese nombre.',
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80, top: 8),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];

                          // 🔥 ELIMINADO: Todo el código de búsqueda del bar local

                          final String? imageUrl = product.imageUrl != null
                              ? "${product.imageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}"
                              : null;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              onTap: () => context.push(
                                '/admin/products/detail',
                                extra: product,
                              ),

                              leading: SizedBox(
                                width: 50,
                                height: 50,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    color: Colors.grey[200],
                                    child: imageUrl != null
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(Icons.broken_image),
                                          )
                                        : const Icon(
                                            Icons.fastfood,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                              ),

                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.store,
                                        size: 14,
                                        color: Colors.blueGrey,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          // 🔥 MAGIA: Usamos directamente el nombre extraído de FastAPI
                                          product.establishmentName ??
                                              "Local Desconocido (ID: ${product.establishmentId})",
                                          style: const TextStyle(
                                            color: Colors.blueGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "${product.price?.toStringAsFixed(2) ?? '0.00'} €",
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () async {
                                      await context.pushNamed(
                                        'product_form',
                                        extra: {
                                          'eventId': selectedEvent.id,
                                          'productToEdit': product,
                                        },
                                      );
                                      ref.invalidate(
                                        adminProductsByEventProvider,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _confirmDelete(context, ref, product),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'active') return Colors.green;
    if (status == 'upcoming') return Colors.orange;
    return Colors.grey;
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar Producto?'),
        content: Text(
          'Vas a eliminar "${product.name}". Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(productRepositoryProvider)
                    .deleteProduct(product.id);
                ref.invalidate(adminProductsByEventProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Producto eliminado correctamente'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al borrar: $e')),
                  );
                }
              }
            },
            child: const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
