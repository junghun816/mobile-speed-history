import 'dart:convert';
import 'dart:math';
import '../models/ride_record.dart';
import 'database_helper.dart';

class SampleDataHelper {
  static Future<void> insertSampleData() async {
    print('샘플 데이터 삽입 시작!');

    final db = DatabaseHelper.instance;

    // 기존 데이터 전체 삭제 추가
    final database = await db.database;
    await database.delete('ride_records');

    final random = Random();

    final start = DateTime(2020, 5, 5);
    final end = DateTime.now();

    DateTime current = start;

    while (current.isBefore(end)) {
      // 월요일(1)부터 일요일(7) 중 이번 주 탈 날짜 랜덤 선택 (3~6일)
      final weekStart = current;
      final rideDays = <int>{};
      final rideCount = 3 + random.nextInt(4); // 3~6일

      while (rideDays.length < rideCount) {
        rideDays.add(random.nextInt(7)); // 0~6 (월~일)
      }

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final day = weekStart.add(Duration(days: dayOffset));
        if (day.isAfter(end)) break;

        if (rideDays.contains(dayOffset)) {
          // 하루에 1~4회 주행
          final sessionCount = random.nextInt(4) + 1;

          for (int s = 0; s < sessionCount; s++) {
            final activityType = random.nextDouble() > 0.5 ? 'bike' : 'run';

            // 종목별 거리·속도 범위
            final double distance;
            final double avgSpeed;
            final double maxSpeed;
            if (activityType == 'bike') {
              distance = 5.0 + random.nextDouble() * 35;       // 5~40km
              avgSpeed = 15.0 + random.nextDouble() * 13;      // 15~28 km/h
              maxSpeed = avgSpeed * (1.3 + random.nextDouble() * 0.4);
            } else {
              distance = 3.0 + random.nextDouble() * 12;       // 3~15km
              avgSpeed = 8.0 + random.nextDouble() * 6;        // 8~14 km/h
              maxSpeed = avgSpeed * (1.1 + random.nextDouble() * 0.2);
            }

            // 시간 = 거리 / 속도 (초)
            final duration = ((distance / avgSpeed) * 3600).toInt();

            // 출발 시간: 오전 6시 ~ 오후 8시
            final hour = 6 + random.nextInt(14);
            final minute = random.nextInt(60);
            final rideTime = DateTime(
                day.year, day.month, day.day, hour, minute);

            // 랩 데이터 생성 (1km 기준)
            final lapCount = distance.floor();
            String? lapSplitsJson;
            if (lapCount > 0) {
              final baseLapTimeSec = (3600 / avgSpeed).round();
              final laps = <Map<String, dynamic>>[];
              for (int lap = 1; lap <= lapCount; lap++) {
                final lapTimeSec = (baseLapTimeSec * (0.93 + random.nextDouble() * 0.14)).round();
                final lapMaxSpeed = avgSpeed * (1.1 + random.nextDouble() * 0.2);
                laps.add({
                  'lap': lap,
                  'timeMs': lapTimeSec * 1000,
                  'paceSecPerKm': lapTimeSec,
                  'maxSpeedKmh': double.parse(lapMaxSpeed.toStringAsFixed(1)),
                });
              }
              lapSplitsJson = jsonEncode(laps);
            }

            final record = RideRecord(
              year: day.year,
              month: day.month,
              day: day.day,
              totalDistance: double.parse(
                  distance.toStringAsFixed(2)),
              maxSpeed: double.parse(
                  maxSpeed.toStringAsFixed(1)),
              avgSpeed: double.parse(
                  avgSpeed.toStringAsFixed(1)),
              duration: duration,
              pathPoints: '[]',
              createdAt: rideTime.millisecondsSinceEpoch,
              activityType: activityType,
              lapSplits: lapSplitsJson,
            );

            await db.insertRecord(record);
          }
        }
      }

      // 다음 주로
      current = weekStart.add(const Duration(days: 7));
    }

    print('샘플 데이터 삽입 완료!');
  }
}