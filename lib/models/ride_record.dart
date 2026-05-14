class RideRecord {
  final int? id;
  final int year;
  final int month;
  final int day;
  final double totalDistance;
  final double maxSpeed;
  final double avgSpeed;
  final int duration;
  final String pathPoints;
  final int createdAt;
  final String? memo;
  final String activityType; // 'bike' | 'run'
  final String? lapSplits;   // JSON: [{lap, timeMs, paceSecPerKm, maxSpeedKmh}, ...]
  final int? targetPace;     // 목표 페이스 (초/km), null이면 미설정
  final int? cadenceBpm;     // 케이던스 메트로놈 BPM, null이면 미사용

  RideRecord({
    this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.totalDistance,
    required this.maxSpeed,
    required this.avgSpeed,
    required this.duration,
    required this.pathPoints,
    required this.createdAt,
    this.memo,
    this.activityType = 'bike',
    this.lapSplits,
    this.targetPace,
    this.cadenceBpm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'day': day,
      'totalDistance': totalDistance,
      'maxSpeed': maxSpeed,
      'avgSpeed': avgSpeed,
      'duration': duration,
      'pathPoints': pathPoints,
      'createdAt': createdAt,
      'memo': memo,
      'activityType': activityType,
      'lapSplits': lapSplits,
      'targetPace': targetPace,
      'cadenceBpm': cadenceBpm,
    };
  }

  factory RideRecord.fromMap(Map<String, dynamic> map) {
    return RideRecord(
      id: map['id'],
      year: map['year'],
      month: map['month'],
      day: map['day'],
      totalDistance: map['totalDistance'],
      maxSpeed: map['maxSpeed'],
      avgSpeed: map['avgSpeed'] ?? 0.0,
      duration: map['duration'],
      pathPoints: map['pathPoints'],
      createdAt: map['createdAt'],
      memo: map['memo'] as String?,
      activityType: map['activityType'] as String? ?? 'bike',
      lapSplits: map['lapSplits'] as String?,
      targetPace: map['targetPace'] as int?,
      cadenceBpm: map['cadenceBpm'] as int?,
    );
  }
}
