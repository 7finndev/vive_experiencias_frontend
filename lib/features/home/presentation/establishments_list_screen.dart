import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';
import 'package:vive_core/features/home/presentation/providers/ranking_provider.dart';
import 'package:vive_core/features/home/presentation/widgets/establishment_card.dart';
import 'package:vive_core/core/widgets/error_view.dart'; // <--- IMPORTA ESTO

class EstablishmentsListScreen extends ConsumerStatefulWidget {
  final int eventId;
  const EstablishmentsListScreen({super.key, required this.eventId});

  @override
  ConsumerState<EstablishmentsListScreen> createState() =>
      _EstablishmentsListScreenState();
}

class _EstablishmentsListScreenState
    extends ConsumerState<EstablishmentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Función de Recarga
  void _reloadData() {
    //Importante: Invalidamos al Padre primero
    ref.invalidate(currentEventProvider);
    //Luego a los hijos
    ref.invalidate(establishmentsListProvider);
    ref.invalidate(rankingListProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final establishmentsAsync = ref.watch(establishmentsListProvider);

    final eventAsync = ref.watch(currentEventProvider);
    Color themeColor = Colors.orange;
    if (eventAsync.hasValue && eventAsync.value != null) {
      try {
        String hex = eventAsync.value!.themeColorHex.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        themeColor = Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        color: themeColor,
        backgroundColor: Colors.white,
        onRefresh: () async {
          //Utilizamos la funcion _reloadData() aqui:
          _reloadData();
          //Sustituyendo a estas dos lineas:
          //--> ref.invalidate(establishmentsListProvider);
          //--> ref.invalidate(rankingListProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar bar o tapa...',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // AQUÍ CORREGIMOS EL ERROR:
            establishmentsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),

              // ✅ USAMOS TU WIDGET ERRORVIEW (Envuelto en Sliver)
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  error: err,
                  // Aqui tambien utilizamos la funcion _reloadData();
                  onRetry: () => _reloadData(),
                  //Sustituyendo esta linea:
                  // -->onRetry: () => ref.invalidate(establishmentsListProvider),
                ),
              ),

              data: (list) {
                final filtered = list.where((est) {
                  final q = _searchQuery.toLowerCase();
                  final matchName = est.name.toLowerCase().contains(q);
                  final matchProduct =
                      est.products?.any(
                        (p) => p.name.toLowerCase().contains(q),
                      ) ??
                      false;
                  return matchName || matchProduct;
                }).toList();

                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text("No se encontraron resultados")),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16), // Padding uniforme
                  sliver: SliverGrid(
                    // Cambiamos SliverList por SliverGrid
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent:
                          400, // Ancho máximo de la tarjeta (PC: Varias columnas, Móvil: 1 columna)
                      mainAxisExtent:
                          130, // Altura FIJA de la tarjeta (para que no se deforme)
                      crossAxisSpacing: 16, // Hueco horizontal
                      mainAxisSpacing: 16, // Hueco vertical
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final est = filtered[index];
                      // Ya no necesitamos Padding extra porque SliverGrid lo gestiona con el spacing
                      return EstablishmentCard(establishment: est);
                    }, childCount: filtered.length),
                  ),
                );
              },
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }
}
