import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vive_core/features/home/data/models/product_model.dart';

part 'establishment_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class EstablishmentModel extends HiveObject {
  @HiveField(0) final int id;
  @HiveField(1) final String name;
  @HiveField(2) final String? address;
  @HiveField(3) @JsonKey(name: 'latitude') final double? latitude;
  @HiveField(4) @JsonKey(name: 'longitude') final double? longitude;  @HiveField(5) @JsonKey(name: 'qr_uuid') final String qrUuid;
  @HiveField(6, defaultValue: true) @JsonKey(name: 'is_active') final bool isActive;
  @HiveField(7) @JsonKey(name: 'google_place_id') final String? googlePlaceId;
  @HiveField(8) final String? description;
  @HiveField(9) final String? phone;
  @HiveField(11) final String? schedule;
  @HiveField(12) @JsonKey(name: 'cover_image') final String? coverImage;

  // --- NUEVOS CAMPOS DE ADMINISTRACIÓN ---
  @HiveField(13) @JsonKey(name: 'owner_name') final String? ownerName;
  @HiveField(14) @JsonKey(name: 'owner_phone') final String? ownerPhone;
  @HiveField(15) @JsonKey(name: 'owner_email') final String? ownerEmail;
  @HiveField(16, defaultValue: true) @JsonKey(name: 'is_partner') final bool isPartner;
  
  //RRSS:
  @HiveField(10) final String? website;
  @HiveField(17) @JsonKey(name: 'social_tiktok') final String? socialTiktok;
  @HiveField(18) @JsonKey(name: 'facebook') final String? facebook;
  @HiveField(19) @JsonKey(name: 'instagram') final String? instagram;

  @HiveField(20)
  @JsonKey(includeToJson: false)                                                                                                                                                                      
  final List<ProductModel>? products;
  
  @HiveField(21)
  @JsonKey(name: 'waiter_pin')
  final String? waiterPin;

  @HiveField(22) // En orden correlativo de tus @HiveField
  @JsonKey(name: 'city_id') 
  final int? cityId;

  EstablishmentModel({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    required this.qrUuid,
    required this.isActive,
    this.googlePlaceId,
    this.description,
    this.phone,
    this.website,
    this.schedule,
    this.coverImage,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    this.isPartner = true, 
    this.socialTiktok,
    this.facebook,
    this.instagram,
    this.products,
    this.waiterPin,
    this.cityId,
  });

  factory EstablishmentModel.fromJson(Map<String, dynamic> json) => 
      _$EstablishmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$EstablishmentModelToJson(this);
}