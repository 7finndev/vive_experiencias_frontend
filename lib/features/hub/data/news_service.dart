import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';
import 'package:vive_core/core/utils/logger_service.dart'; // 🚀 Integrado el Logger

// Importamos los modelos
import 'models/app_config_model.dart';
import 'models/app_news_model.dart';

// =============================================================================
// 1. MODELO DE UI (INTACTO PARA CERO EFECTO DOMINÓ)
// =============================================================================
class NewsItem {
  final String title;
  final String imageUrl;
  final String link;
  final String date;
  final bool isInternal; 

  NewsItem({
    required this.title,
    required this.imageUrl,
    required this.link,
    required this.date,
    this.isInternal = true, // Ahora todas son internas por defecto
  });
}

// =============================================================================
// 2. PROVIDER DE CONFIGURACIÓN 
// =============================================================================
final appConfigProvider = FutureProvider<AppConfigModel>((ref) async {
  final supabase = Supabase.instance.client;
  final cityId = ref.watch(currentCityIdProvider);
  
  try {
    final data = await supabase.from('app_config').select().eq('city_id', cityId).maybeSingle();

    if (data == null) {
      Logger.warning("Sin config de noticias para ciudad $cityId, usando defecto.", "HUB_NEWS");
      return AppConfigModel(
        id: 1, carouselIntervalMs: 5000, maxNewsCount: 5, enableExternalSource: false, loadingBgImage: '', loadingMessage: ''
      );
    }
    
    return AppConfigModel.fromJson(data);
  } catch (e) {
    Logger.error("Error cargando config de noticias: $e", "HUB_NEWS");
    return AppConfigModel(
      id: 1, carouselIntervalMs: 5000, maxNewsCount: 5, enableExternalSource: false, loadingBgImage: '', loadingMessage: ''
    );
  }
});

// =============================================================================
// 3. PROVIDER DE NOTICIAS 100% INTERNAS 
// =============================================================================
final newsProvider = FutureProvider<List<NewsItem>>((ref) async {
  final cityId = ref.watch(currentCityIdProvider);
  final supabase = Supabase.instance.client;
  
  try {
    final results = await Future.wait<dynamic>([
      ref.watch(appConfigProvider.future),
      supabase
        .from('app_news')
        .select()
        .eq('city_id', cityId)
        .eq('is_active', true)
        .order('priority', ascending: false)
        .order('published_at', ascending: false)
    ]);

    final AppConfigModel config = results[0] as AppConfigModel;
    final List<dynamic> internalRaw = results[1] as List<dynamic>;

    List<NewsItem> finalList = internalRaw.map((json) {
      final news = AppNewsModel.fromJson(json);
      String dateFormatted = DateFormat('d MMM yyyy', 'es_ES').format(news.publishedAt);

      return NewsItem(
        title: news.title,
        imageUrl: news.imageUrl ?? 'https://via.placeholder.com/600x400/003366/ffffff?text=Vive+Rutas',
        link: news.linkUrl ?? '',
        date: dateFormatted,
        isInternal: true,
      );
    }).toList();

    Logger.info("Cargadas ${finalList.length} noticias para la ciudad $cityId", "HUB_NEWS");
    return finalList.take(config.maxNewsCount).toList();
    
  } catch (e) {
    Logger.error("Error procesando noticias: $e", "HUB_NEWS");
    return []; // Devolvemos lista vacía para no romper la UI si falla
  }
});