import 'package:hive/hive.dart';
import 'package:vive_core/features/home/data/models/product_item_model.dart';

part 'product_model.g.dart'; 

@HiveType(typeId: 2) 
class ProductModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final double? price;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  final int establishmentId;

  @HiveField(6)
  final int eventId;

  @HiveField(7)
  final bool isAvailable;

  @HiveField(8)
  final String? ingredients;

  @HiveField(9)
  final List<String>? allergens;

  @HiveField(10)
  final bool isWinner;
  
  // --- NUEVO CAMPO CON HIVE ---
  @HiveField(11) // Le damos un índice nuevo
  final List<ProductItemModel> items; 

  final String? establishmentName; // Este campo no se guarda en Hive, solo se usa para mostrar en la UI
  
  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.imageUrl,
    required this.establishmentId,
    required this.eventId,
    this.isAvailable = true,
    this.ingredients,
    this.allergens,
    this.isWinner = false,
    this.items = const [], 
    this.establishmentName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    var itemsList = <ProductItemModel>[];
    if (json['product_items'] != null) {
      itemsList = (json['product_items'] as List)
          .map((i) => ProductItemModel.fromJson(i))
          .toList();
    }

    String? estName;
    if(json['establishments'] != null && json['establishments'] is Map) {
      estName = json['establishments']['name'];
    }
    
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      imageUrl: json['image_url'],
      establishmentId: json['establishment_id'],
      eventId: json['event_id'],
      isAvailable: json['is_available'] ?? true,
      ingredients: json['ingredients'],
      allergens: json['allergens'] != null ? List<String>.from(json['allergens']) : null,
      isWinner: json['is_winner'] ?? false,
      items: itemsList, 
      establishmentName: estName,
    );
  }

  // Necesitas el toJson para el Repository
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'establishment_id': establishmentId,
      'event_id': eventId,
      'is_available': isAvailable,
      'ingredients': ingredients,
      'allergens': allergens,
      'is_winner': isWinner,
      // Nota: No enviamos 'items' aquí porque se guardan en otra tabla
    };
  }
}