import 'package:vive_core/core/utils/logger_service.dart';

class RankingItem {
  final int productId;
  final int establishmentId; // Necesario para navegar al detalle
  final String productName;
  final String establishmentName;
  final String? imageUrl;     // Foto de la Tapa/coctel
  final String? coverImage;   // Foto del Bar (Logo)
  final double price;
  final double averageRating;
  final int voteCount;
  final bool isWinner;

  RankingItem({
    required this.productId,
    required this.establishmentId,
    required this.productName,
    required this.establishmentName,
    this.imageUrl,
    this.coverImage,
    required this.price,
    required this.averageRating,
    required this.voteCount,
    this.isWinner = false,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json) {
    // CHIVATO DE DEPURACIÓN
    if (json['establishment_id'] == null) {
      Logger.warning("⚠️ ALERTA: establishment_id es NULL en el JSON recibido: $json", "RANKING_ITEM");
    }    
    return RankingItem(
      // Usamos (json['key'] as num?)?.toInt()
      // Esto hace que cualquier numero (int, double, bigint) lo pase o convierta a un int seguro.
      // 
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      //
      establishmentId: (json['establishment_id'] as num?)?.toInt() ?? 0, 

      productName: json['product_name']?.toString() ?? 'Producto desconocido',
      establishmentName: json['establishment_name']?.toString() ?? 'Local desconocido',
      imageUrl: json['image_url']?.toString(),
      coverImage: json['cover_image']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      isWinner: json['is_winner'] ?? false,
    );
  }
}