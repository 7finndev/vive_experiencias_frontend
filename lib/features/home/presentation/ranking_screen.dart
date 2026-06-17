import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/core/widgets/web_container.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart'; // Necesario para el modelo
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  List<Map<String, dynamic>> _ranking = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    final eventId = ref.read(currentEventIdProvider);
    
    try {
      final List<dynamic> data = await Supabase.instance.client
          .rpc('get_event_ranking', params: {'target_event_id': eventId});

      if (mounted) {
        setState(() {
          _ranking = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      Logger.error("Error cargando ranking: $e", "RANKING_SCREEN");
    }
  }

  // --- 🧭 LÓGICA DE NAVEGACIÓN INTELIGENTE ---
  Future<void> _navigateToDetail(int establishmentId) async {
    // 1. Buscamos primero en la lista local (Rápido)
    final localEstablishments = ref.read(establishmentsListProvider);
    
    if (localEstablishments.hasValue) {
      try {
        final fullBar = localEstablishments.value!.firstWhere((e) => e.id == establishmentId);
        context.push('/detail', extra: fullBar);
        return; // ¡Éxito! Nos ahorramos la llamada a la BD
      } catch (_) {
        // No estaba en la lista local, seguimos al plan B
      }
    }

    // 2. Plan B: Buscar en Supabase (Seguro)
    try {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Cargando información..."), duration: Duration(milliseconds: 500))
      );

      final response = await Supabase.instance.client
          .from('establishments')
          .select()
          .eq('id', establishmentId)
          .single();
      
      final bar = EstablishmentModel.fromJson(response);
      
      if (mounted) {
         context.push('/detail', extra: bar);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo cargar la ficha del local"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebContainer(
      backgroundColor: Colors.grey[100], //Fondo gris para la web.
      child: Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("🏆 Ranking"),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: Colors.orange,
        onRefresh: () async {
          await _loadRanking();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _ranking.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                       SizedBox(height: 100),
                       Center(child: Text("Aún no hay votos en este evento."))
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _ranking.length,
                    itemBuilder: (context, index) {
                      final item = _ranking[index];
                      
                      final int rank = index + 1; 
                      final bool isWinner = item['is_winner'] ?? false;
                      final double rating = (item['average_rating'] as num).toDouble();
                      final int votes = (item['vote_count'] as num).toInt();
                      final int establishmentId = (item['establishment_id'] as num).toInt(); // ID necesario
                      
                      // Estilos Podio
                      Color borderColor = Colors.transparent;
                      Color numberBgColor = Colors.grey[100]!;
                      Color numberTextColor = Colors.grey;
                      double scale = 1.0;

                      if (rank == 1) { 
                        borderColor = const Color(0xFFFFD700);
                        numberBgColor = const Color(0xFFFFF8E1);
                        numberTextColor = const Color(0xFFFFD700);
                        scale = 1.02; 
                      } else if (rank == 2) { 
                        borderColor = const Color(0xFFC0C0C0);
                        numberBgColor = const Color(0xFFF5F5F5);
                        numberTextColor = const Color(0xFF9E9E9E);
                      } else if (rank == 3) { 
                        borderColor = const Color(0xFFCD7F32);
                        numberBgColor = const Color(0xFFEFEBE9);
                        numberTextColor = const Color(0xFF8D6E63);
                      }

                      return Transform.scale(
                        scale: scale,
                        child: GestureDetector( // <--- AÑADIDO GESTO
                          onTap: () => _navigateToDetail(establishmentId),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05), 
                                  blurRadius: 10, 
                                  offset: const Offset(0,4)
                                )
                              ],
                              border: Border.all(
                                color: borderColor, 
                                width: rank <= 3 ? 2 : 0
                              ),
                            ),
                            child: Row(
                              children: [
                                // NÚMERO
                                Container(
                                  width: 60,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: numberBgColor,
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "#$rank",
                                      style: TextStyle(
                                        fontSize: 24, 
                                        fontWeight: FontWeight.w900, 
                                        color: numberTextColor,
                                        fontStyle: FontStyle.italic
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // FOTO
                                CachedNetworkImage(
                                  imageUrl: item['image_url'] ?? '',
                                  width: 80, 
                                  height: 100, 
                                  fit: BoxFit.cover,
                                  errorWidget: (_,_,_) => Container(
                                    width: 80, 
                                    color: Colors.grey[200], 
                                    child: const Icon(Icons.restaurant, color: Colors.grey)
                                  ),
                                ),
                                
                                // TEXTOS
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item['product_name'] ?? 'Tapa', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                                          maxLines: 1, 
                                          overflow: TextOverflow.ellipsis
                                        ),
                                        Text(
                                          item['establishment_name'] ?? 'Local', 
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                                            const SizedBox(width: 4),
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                            ),
                                            const Spacer(),
                                            Text(
                                              "$votes votos",
                                              style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),

                                // BADGE GANADOR
                                if (isWinner)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 32),
                                        Text("WINNER", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)))
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    ),
    );
  }
}