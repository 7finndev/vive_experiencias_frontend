import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/features/home/data/models/ranking_item_model.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';

part 'ranking_provider.g.dart';

@riverpod
Future<List<RankingItem>> rankingList(RankingListRef ref) async {
  final supabase = Supabase.instance.client;

  // 1. Esperamos a saber cuál es el evento activo
  final event = await ref.watch(currentEventProvider.future);

// este da fallos:
  // Consultamos la vista
  //final response = await supabase
  //.from('ranking_view')
  //.select()
  //.eq('event_id', event.id);
//##############################

  // Debe ser así:
  final response = await supabase
        .rpc('get_event_ranking', params: {'target_event_id': event.id});
  
  return (response as List).map((e) => RankingItem.fromJson(e)).toList();
}