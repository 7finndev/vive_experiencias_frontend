import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

// Esto generará el adaptador para Hive
part 'passport_entry_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 4) // ID 2 (0 era Establishment, 1 era Event)
class PassportEntryModel extends HiveObject {
  @HiveField(0)
  final String establishmentName; // Guardamos el nombre para mostrarlo fácil

  @HiveField(1)
  @JsonKey(name: 'product_id')
  final int establishmentId; // ID del bar que has visitado

  @HiveField(2)
  @JsonKey(name: 'scanned_at')
  final DateTime scannedAt;

  @HiveField(3)
  final bool isSynced; // Para saber si ya se subió a la nube
  
  @HiveField(4) final int rating;
  @HiveField(5) @JsonKey(name: 'event_id') final int eventId;

  PassportEntryModel({
    required this.establishmentName,
    required this.establishmentId,
    required this.scannedAt,
    this.isSynced = false,
    this.rating = 0, // Por defecto 0 si no vota
    required this.eventId, // Obligatorio
  });
  
  // 🔥 AÑADIMOS ESTE MÉTODO COPYWITH PARA LA SINCRONIZACIÓN
  PassportEntryModel copyWith({
    String? establishmentName,
    int? establishmentId,
    DateTime? scannedAt,
    bool? isSynced,
    int? rating,
    int? eventId,
  }) {
    return PassportEntryModel(
      establishmentName: establishmentName ?? this.establishmentName,
      establishmentId: establishmentId ?? this.establishmentId,
      scannedAt: scannedAt ?? this.scannedAt,
      isSynced: isSynced ?? this.isSynced,
      rating: rating ?? this.rating,
      eventId: eventId ?? this.eventId,
    );
  }

  // Factory para JSON (útil futuro)
  factory PassportEntryModel.fromJson(Map<String, dynamic> json) => 
      _$PassportEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$PassportEntryModelToJson(this);
}