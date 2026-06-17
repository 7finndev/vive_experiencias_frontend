import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 1) 
class EventModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  @JsonKey(name: 'type', defaultValue: 'gastronomic')
  final String type;

  @HiveField(3)
  @JsonKey(name: 'status', defaultValue: 'archived')
  final String status;

  String get computedStatus {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 'upcoming';
    if (now.isAfter(endDate)) return 'archived';
    return 'active';
  }

  @HiveField(4)
  @JsonKey(name: 'theme_color_hex', defaultValue: '#FF9800')
  final String themeColorHex;

  @HiveField(5)
  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  @HiveField(6)
  @JsonKey(name: 'bg_image_url')
  final String? bgImageUrl;

  @HiveField(7)
  @JsonKey(name: 'base_price')
  final double? basePrice;

  @HiveField(8)
  @JsonKey(name: 'start_date')
  final DateTime startDate;

  @HiveField(9)
  @JsonKey(name: 'end_date')
  final DateTime endDate;

  @HiveField(10)
  @JsonKey(defaultValue: '')
  final String slug;

  @HiveField(11)
  @JsonKey(name: 'bg_color')
  final String? bgColorHex; 

  @HiveField(12)
  @JsonKey(name: 'nav_color')
  final String? navColorHex; 

  @HiveField(13)
  @JsonKey(name: 'text_color')
  final String? textColorHex; 

  @HiveField(14)
  @JsonKey(name: 'font_family')
  final String? fontFamily; 

  // 🔥 NUEVO CAMPO: Para la seguridad B2B de FastAPI
  @HiveField(15)
  @JsonKey(name: 'city_id')
  final int? cityId; 

  bool get isActive => computedStatus == 'active';

  EventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.themeColorHex,
    required this.startDate,
    required this.endDate,
    required this.slug,
    this.logoUrl,
    this.bgImageUrl,
    this.basePrice,
    this.bgColorHex,
    this.navColorHex,
    this.textColorHex,
    this.fontFamily,
    this.cityId, // 🔥 Añadido al constructor
  });

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventModelToJson(this);
}