import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/home/data/models/ranking_item_model.dart';

class HomeRankingCarousel extends StatelessWidget {
  final AsyncValue<List<RankingItem>> rankingAsync;
  final AsyncValue<List<EstablishmentModel>> establishmentsAsync;

  const HomeRankingCarousel({
    super.key, 
    required this.rankingAsync,
    required this.establishmentsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160, // Altura de la tarjeta
      child: rankingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_,_) => const SizedBox(), // Si falla, ocultamos la sección
        data: (ranking) {
          if (ranking.isEmpty) return const Center(child: Text("¡Vota para destacar aquí!"));

          // Solo mostramos el TOP 5
          final top5 = ranking.take(5).toList();

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4), // Margen lateral
            itemCount: top5.length,
            separatorBuilder: (_,_) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = top5[index];
              return _RankingCard(
                item: item, 
                position: index + 1,
                //Función navegación inteligente:
                onTap: (){
                  _navigateToDetail(context, item.establishmentId);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _navigateToDetail(BuildContext context, int establishmentId) async {
    // 1. Validación de seguridad
    if (establishmentId <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de datos: ID de local inválido ($establishmentId)"), backgroundColor: Colors.red)
       );
       return;
    }    
    // PLAN A: Buscar en la lista ya cargada (Rápido)
    if (establishmentsAsync.hasValue) {
      try {
        final fullBar = establishmentsAsync.value!.firstWhere((e) => e.id == establishmentId);
        context.push('/detail', extra: fullBar);
        return; // ¡Éxito! Salimos.
      } catch (_) {
        // Si falla, no hacemos nada y pasamos al Plan B
        Logger.warning("⚠️ El bar ID $establishmentId no está en la lista local. Buscando en nube...", "HOME_RANKING_CAROUSEL");
      }
    }

    // PLAN B: Buscar directamente en Supabase (Seguro)
    try {
      // Mostramos un pequeño indicador de carga o feedback (opcional)
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Cargando ficha..."), duration: Duration(milliseconds: 500))
      );

      final response = await Supabase.instance.client
          .from('establishments')
          .select()
          .eq('id', establishmentId)
          .single();
      
      // Convertimos el JSON a nuestro modelo
      final bar = EstablishmentModel.fromJson(response);
      
      if (context.mounted) {
         context.push('/detail', extra: bar);
      }
      
    } catch (e) {
      Logger.error("Error recuperando bar: $e", "HOME_RANKING_CAROUSEL");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: No se pudo cargar la información del local"), backgroundColor: Colors.red)
        );
      }
    }
  }
}

class _RankingCard extends StatelessWidget {
  final RankingItem item;
  final int position;
  final VoidCallback onTap; // Callback recibido

  const _RankingCard({required this.item, required this.position, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

//**************************************************************************************** */      
      //OLD (Deprecated) 
//    onTap: () {

        // Reconstruimos un modelo básico para navegar al detalle
//        final establishment = EstablishmentModel(
//          id: item.establishmentId, // Ojo: Necesitamos que RankingItem tenga este campo
//          name: item.establishmentName,
//          qrUuid: "", // No lo tenemos aquí, pero el detalle lo volverá a cargar
//          isActive: true,
//          coverImage: item.coverImage,
//        );
        
//        context.push('/detail', extra: establishment);
//      },
//************************************************************************************** */
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0,4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO DEL LOCAL (LOGO)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      // USAMOS COVER IMAGE (FOTO LOCAL) EN LUGAR DE TAPA
                      // Asegúrate de que tu RankingItem tiene este campo mapeado desde SQL
                      imageUrl: item.imageUrl ?? '', // Usamos la de la tapa o bar según SQL
                      fit: BoxFit.cover,
                      placeholder: (_,_) => Container(color: Colors.grey[200]),
                      errorWidget: (_,_,_) => const Icon(Icons.store),
                    ),
                  ),
                  // Badge de Posición
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: position == 1 ? Colors.amber : Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "#$position",
                        style: TextStyle(
                          color: position == 1 ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            // TEXTOS
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.establishmentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        item.averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}