class BikeRecord {
  final int? id;
  final String manufacturer;
  final String model;
  final int? fromDateMs;
  final int? toDateMs;
  final String? photoPath;
  final String? notes;

  const BikeRecord({
    this.id,
    required this.manufacturer,
    required this.model,
    this.fromDateMs,
    this.toDateMs,
    this.photoPath,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'manufacturer': manufacturer,
      'model': model,
      'fromDateMs': fromDateMs,
      'toDateMs': toDateMs,
      'photoPath': photoPath,
      'notes': notes,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory BikeRecord.fromMap(Map<String, dynamic> map) => BikeRecord(
        id: map['id'] as int?,
        manufacturer: (map['manufacturer'] as String?) ?? '',
        model: (map['model'] as String?) ?? '',
        fromDateMs: map['fromDateMs'] as int?,
        toDateMs: map['toDateMs'] as int?,
        photoPath: map['photoPath'] as String?,
        notes: map['notes'] as String?,
      );
}
