import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';

class HomeEstablishmentsList extends StatelessWidget {
  // Recibimos el estado asíncrono desde el padre
  final AsyncValue<List<EstablishmentModel>> establishmentsAsync;

  const HomeEstablishmentsList({super.key, required this.establishmentsAsync});

  @override
  Widget build(BuildContext context) {
    return establishmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
      data: (establishments) {
        if (establishments.isEmpty) {
          return const Text('No hay locales activos aún.');
        }

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: establishments.length,
            itemBuilder: (context, index) {
              final bar = establishments[index];
              return _EstablishmentCard(bar: bar); // Sub-widget privado
            },
          ),
        );
      },
    );
  }
}

// Widget privado solo para este archivo (el item individual)
class _EstablishmentCard extends StatelessWidget {
  final EstablishmentModel bar;

  const _EstablishmentCard({required this.bar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail', extra: bar),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // FOTO
            CachedNetworkImage(
              imageUrl: bar.coverImage ??
                  'https://images.pexels.com/photos/1307698/pexels-photo-1307698.jpeg?auto=compress&cs=tinysrgb&w=400',
              // AÑADIR ESTAS DOS LÍNEAS DE OPTIMIZACIÓN:
              memCacheWidth: 200, // Reduce uso de RAM drásticamente
              maxWidthDiskCache: 400, // Reduce uso de disco
              imageBuilder: (context, imageProvider) => Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: const Icon(Icons.storefront, color: Colors.grey),
              ),
            ),
            // DATOS
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bar.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    bar.address ?? 'Sin dirección',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
