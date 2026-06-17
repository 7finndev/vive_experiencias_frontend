import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';
import 'package:vive_core/features/scan/presentation/providers/passport_provider.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/core/utils/smart_image_container.dart';

class SmartRecommendationCard extends ConsumerWidget {
  final int eventId;
  const SmartRecommendationCard({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final establishmentsAsync = ref.watch(establishmentsListProvider);
    // Necesitamos el pasaporte para saber qué has visitado ya
    // Asumimos que tienes un provider que te da los sellos. 
    // Si usas el passportRepository directamente, habría que adaptar esto, 
    // pero para la UI usaremos el provider de pasaporte si lo tienes, o consultaremos el repo.
    final passportAsync = ref.watch(passportProvider(eventId)); 

    return passportAsync.when(
      loading: () => const SizedBox(), // Cargando silencioso
      error: (_, _) => const SizedBox(),
      data: (stamps) {
        return establishmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox(),
          data: (establishments) {
            
            // 1. FILTRADO INTELIGENTE
            // Sacamos los IDs de los sitios que YA has visitado en este evento
            final visitedIds = stamps
                .where((s) => s.eventId == eventId)
                .map((s) => s.establishmentId)
                .toSet();

            // Buscamos los locales que NO están en esa lista
            final unvisited = establishments
                .where((e) => !visitedIds.contains(e.id))
                .toList();

            // 2. CASOS DE USO
            if (unvisited.isEmpty) {
              // CASO A: ¡Ya ha visitado todo! (Misión cumplida)
              return _buildCompletedCard();
            }

            // CASO B: Le faltan sitios.
            // Escogemos uno ALEATORIO para ser justos con los locales lejanos.
            final random = Random();
            final suggestion = unvisited[random.nextInt(unvisited.length)];

            return _buildSuggestionCard(context, suggestion, unvisited.length);
          },
        );
      },
    );
  }

  Widget _buildSuggestionCard(BuildContext context, EstablishmentModel bar, int leftCount) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.yellow, size: 24),
              const SizedBox(width: 10),
              const Text(
                "TU PRÓXIMA PARADA",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: Text("Te faltan $leftCount", style: const TextStyle(color: Colors.white, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            "¿Qué tal si pruebas la propuesta de...",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 10),
          
          // TARJETA DEL LOCAL SUGERIDO
          GestureDetector(
            onTap: () => context.push('/detail', extra: bar),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60, height: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SmartImageContainer(imageUrl: bar.coverImage, borderRadius: 0),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bar.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            const Text("Ver ubicación", style: TextStyle(fontSize: 12, color: Colors.blue)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.white, size: 40),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("¡HAS COMPLETADO LA RUTA!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Has visitado todos los establecimientos. ¡Enhorabuena!", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}