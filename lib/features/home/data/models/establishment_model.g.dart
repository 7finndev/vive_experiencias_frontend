// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'establishment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EstablishmentModelAdapter extends TypeAdapter<EstablishmentModel> {
  @override
  final int typeId = 0;

  @override
  EstablishmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EstablishmentModel(
      id: fields[0] as int,
      name: fields[1] as String,
      address: fields[2] as String?,
      latitude: fields[3] as double?,
      longitude: fields[4] as double?,
      qrUuid: fields[5] as String,
      isActive: fields[6] == null ? true : fields[6] as bool,
      googlePlaceId: fields[7] as String?,
      description: fields[8] as String?,
      phone: fields[9] as String?,
      website: fields[10] as String?,
      schedule: fields[11] as String?,
      coverImage: fields[12] as String?,
      ownerName: fields[13] as String?,
      ownerPhone: fields[14] as String?,
      ownerEmail: fields[15] as String?,
      isPartner: fields[16] == null ? true : fields[16] as bool,
      socialTiktok: fields[17] as String?,
      facebook: fields[18] as String?,
      instagram: fields[19] as String?,
      products: (fields[20] as List?)?.cast<ProductModel>(),
      waiterPin: fields[21] as String?,
      cityId: fields[22] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, EstablishmentModel obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.qrUuid)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.googlePlaceId)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.phone)
      ..writeByte(11)
      ..write(obj.schedule)
      ..writeByte(12)
      ..write(obj.coverImage)
      ..writeByte(13)
      ..write(obj.ownerName)
      ..writeByte(14)
      ..write(obj.ownerPhone)
      ..writeByte(15)
      ..write(obj.ownerEmail)
      ..writeByte(16)
      ..write(obj.isPartner)
      ..writeByte(10)
      ..write(obj.website)
      ..writeByte(17)
      ..write(obj.socialTiktok)
      ..writeByte(18)
      ..write(obj.facebook)
      ..writeByte(19)
      ..write(obj.instagram)
      ..writeByte(20)
      ..write(obj.products)
      ..writeByte(21)
      ..write(obj.waiterPin)
      ..writeByte(22)
      ..write(obj.cityId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstablishmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EstablishmentModel _$EstablishmentModelFromJson(Map<String, dynamic> json) =>
    EstablishmentModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      qrUuid: json['qr_uuid'] as String,
      isActive: json['is_active'] as bool,
      googlePlaceId: json['google_place_id'] as String?,
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      schedule: json['schedule'] as String?,
      coverImage: json['cover_image'] as String?,
      ownerName: json['owner_name'] as String?,
      ownerPhone: json['owner_phone'] as String?,
      ownerEmail: json['owner_email'] as String?,
      isPartner: json['is_partner'] as bool? ?? true,
      socialTiktok: json['social_tiktok'] as String?,
      facebook: json['facebook'] as String?,
      instagram: json['instagram'] as String?,
      products: (json['products'] as List<dynamic>?)
          ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      waiterPin: json['waiter_pin'] as String?,
      cityId: (json['city_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$EstablishmentModelToJson(EstablishmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'qr_uuid': instance.qrUuid,
      'is_active': instance.isActive,
      'google_place_id': instance.googlePlaceId,
      'description': instance.description,
      'phone': instance.phone,
      'schedule': instance.schedule,
      'cover_image': instance.coverImage,
      'owner_name': instance.ownerName,
      'owner_phone': instance.ownerPhone,
      'owner_email': instance.ownerEmail,
      'is_partner': instance.isPartner,
      'website': instance.website,
      'social_tiktok': instance.socialTiktok,
      'facebook': instance.facebook,
      'instagram': instance.instagram,
      'waiter_pin': instance.waiterPin,
      'city_id': instance.cityId,
    };
