// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventModelAdapter extends TypeAdapter<EventModel> {
  @override
  final int typeId = 1;

  @override
  EventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventModel(
      id: fields[0] as int,
      name: fields[1] as String,
      type: fields[2] as String,
      status: fields[3] as String,
      themeColorHex: fields[4] as String,
      startDate: fields[8] as DateTime,
      endDate: fields[9] as DateTime,
      slug: fields[10] as String,
      logoUrl: fields[5] as String?,
      bgImageUrl: fields[6] as String?,
      basePrice: fields[7] as double?,
      bgColorHex: fields[11] as String?,
      navColorHex: fields[12] as String?,
      textColorHex: fields[13] as String?,
      fontFamily: fields[14] as String?,
      cityId: fields[15] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, EventModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.themeColorHex)
      ..writeByte(5)
      ..write(obj.logoUrl)
      ..writeByte(6)
      ..write(obj.bgImageUrl)
      ..writeByte(7)
      ..write(obj.basePrice)
      ..writeByte(8)
      ..write(obj.startDate)
      ..writeByte(9)
      ..write(obj.endDate)
      ..writeByte(10)
      ..write(obj.slug)
      ..writeByte(11)
      ..write(obj.bgColorHex)
      ..writeByte(12)
      ..write(obj.navColorHex)
      ..writeByte(13)
      ..write(obj.textColorHex)
      ..writeByte(14)
      ..write(obj.fontFamily)
      ..writeByte(15)
      ..write(obj.cityId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventModel _$EventModelFromJson(Map<String, dynamic> json) => EventModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String? ?? 'gastronomic',
      status: json['status'] as String? ?? 'archived',
      themeColorHex: json['theme_color_hex'] as String? ?? '#FF9800',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      slug: json['slug'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      bgImageUrl: json['bg_image_url'] as String?,
      basePrice: (json['base_price'] as num?)?.toDouble(),
      bgColorHex: json['bg_color'] as String?,
      navColorHex: json['nav_color'] as String?,
      textColorHex: json['text_color'] as String?,
      fontFamily: json['font_family'] as String?,
      cityId: (json['city_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$EventModelToJson(EventModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'status': instance.status,
      'theme_color_hex': instance.themeColorHex,
      'logo_url': instance.logoUrl,
      'bg_image_url': instance.bgImageUrl,
      'base_price': instance.basePrice,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'slug': instance.slug,
      'bg_color': instance.bgColorHex,
      'nav_color': instance.navColorHex,
      'text_color': instance.textColorHex,
      'font_family': instance.fontFamily,
      'city_id': instance.cityId,
    };
