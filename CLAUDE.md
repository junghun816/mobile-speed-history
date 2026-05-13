# CLAUDE.md

LLM의 일반적인 코딩 실수를 줄이기 위한 행동 지침이다. 프로젝트별 지침이 있을 경우 본 가이드라인과 병합하여 사용한다.

트레이드오프: 본 지침은 속도보다 신중함에 우선순위를 둔다. 사소한 작업은 상황에 맞게 판단한다.

### 1. 구현 전 사고 (Think Before Coding)
가정하지 않는다. 모호함을 숨기지 않는다. 트레이드오프를 명확히 밝힌다.

구현을 시작하기 전 다음을 준수한다:

- 자신의 가정을 명시적으로 기술한다. 불확실한 경우 질문한다.

- 해석의 여지가 여러 가지라면 임의로 선택하지 말고 대안들을 제시한다.

- 더 간단한 접근 방식이 있다면 제안한다. 정당한 사유가 있다면 사용자의 요청에 반대 의견을 제시한다.

- 불분명한 부분이 있다면 작업을 중단한다. 혼란스러운 부분을 구체적으로 언급하며 질문한다.

### 2. 단순성 우선 (Simplicity First)
- 문제를 해결하는 최소한의 코드만 작성한다. 추측에 기반한 코드는 배제한다.

- 요청되지 않은 기능은 추가하지 않는다.

- 일회성 코드를 위해 추상화 계층을 만들지 않는다.

- 요청되지 않은 유연성이나 설정 가능성을 고려하지 않는다.

- 발생 불가능한 시나리오에 대한 예외 처리를 하지 않는다.

- 200줄의 코드를 50줄로 줄일 수 있다면 코드를 다시 작성한다.

- "시니어 엔지니어가 보기에 이 코드가 지나치게 복잡한가?"라고 자문한다. 그렇다면 단순화한다.

### 3. 정밀한 수정 (Surgical Changes)
필요한 부분만 수정한다. 본인이 만든 코드의 뒷정리만 수행한다.

기존 코드를 편집할 때 다음을 준수한다:

- 인접한 코드, 주석, 포맷을 임의로 개선하지 않는다.
- 망가지지 않은 부분을 리팩토링하지 않는다.
- 본인의 스타일과 다르더라도 기존 스타일을 따른다.
- 작업과 무관한 데드 코드를 발견하면 보고하되 직접 삭제하지 않는다.

수정으로 인해 사용되지 않게 된 요소가 발생할 경우:

- 본인의 수정으로 인해 불필요해진 임포트, 변수, 함수는 제거한다.
- 기존에 존재하던 데드 코드는 요청이 없는 한 그대로 둔다.
- 테스트 기준: 변경된 모든 라인은 사용자의 요청사항과 직접적으로 연결되어야 한다.

### 4. 목표 중심 실행 (Goal-Driven Execution)
성공 기준을 정의한다. 검증될 때까지 반복한다.
작업을 검증 가능한 목표로 변환한다:

- "유효성 검사 추가" → "잘못된 입력에 대한 테스트 작성 후 통과 확인"
- "버그 수정" → "버그를 재현하는 테스트 작성 후 통과 확인"
- "X 리팩토링" → "리팩토링 전후의 테스트 통과 확인"

다단계 작업의 경우 간략한 계획을 수립한다:

1. [단계] → 검증: [확인 사항]
2. [단계] → 검증: [확인 사항]
3. [단계] → 검증: [확인 사항]
성공 기준이 명확해야 독립적인 작업이 가능하다. "작동하게 만들기"와 같은 모호한 기준은 불필요한 재질의를 야기한다.

지침 작동 확인: Diff 내 불필요한 변경 감소, 복잡성으로 인한 재작성 빈도 감소, 구현 전 질문을 통한 명확한 의사결정 증대.

---

## 작업 방침

- **CLAUDE.md 동기화**: 기능 추가·구조 변경 등 큰 작업을 마친 후 CLAUDE.md를 자동으로 업데이트해 현재 프로젝트 상태와 일치시킨다.
- **토큰 절약**: 파일은 필요한 부분만 읽고, 불필요한 전체 탐색은 피한다.
- **컨벤션/리팩토링 금지**: 명시적으로 요청받기 전까지 전체 코드를 훑어 컨벤션 정리나 리팩토링을 하지 않는다.

---

## Flutter 공통 규칙

### 클릭 이벤트 시스템 음
모든 클릭/탭 이벤트에는 반드시 시스템 음을 출력한다.
```dart
SystemSound.play(SystemSoundType.click);
```
Flutter의 일부 위젯(예: `Switch`, `Checkbox`, `Radio`, `DropdownButton`)은 자체적으로 시스템 음을 출력하므로 별도 처리가 필요 없다. 그 외 `GestureDetector`, `InkWell` 등 커스텀 탭 영역에는 반드시 명시적으로 추가한다.

### 반응형 UI (flutter_screenutil)
`flutter_screenutil: ^5.9.3`을 사용해 기기별 크기 대응을 한다. 기준 해상도는 **390×844**.

> 테스트 기기는 Galaxy S22+(dp 360×780)지만, screenutil 적용 후 이 값을 기준으로 UI 크기를 보정해왔으므로 designSize는 390×844를 유지한다. 기준 해상도를 바꾸면 S22+에서 scale이 1.0이 되어 기존 값들이 8% 더 크게 보인다.

`main.dart`에서 `MaterialApp`을 `ScreenUtilInit`으로 감싼다:
```dart
ScreenUtilInit(
  designSize: const Size(390, 844),
  minTextAdapt: true,
  builder: (context, child) => MaterialApp(...),
)
```

크기 단위 규칙:
- `.sp` — 폰트 크기 (`fontSize: 14.sp`)
- `.r` — 정사각형 크기, 아이콘, `BorderRadius` (`width: 36.r`, `size: 20.r`, `BorderRadius.circular(12.r)`)
- `.w` — 수평 간격·패딩 (`SizedBox(width: 14.w)`, `horizontal: 16.w`)
- `.h` — 수직 간격·패딩 (`SizedBox(height: 10.h)`, `vertical: 8.h`)

주의:
- `const EdgeInsets`는 `.w`/`.h`/`.sp`와 함께 쓸 수 없다. `const` 키워드를 제거한다.
- `CustomPainter` 내부처럼 canvas 크기가 `MediaQuery`로 이미 적응하는 경우엔 적용하지 않는다.
- 자체 스케일 배율이 있는 위젯(예: 드래그로 크기 조절되는 뱃지)은 `.sp`를 먼저 적용 후 배율 곱하기: `fontSize: 36.sp * scale`.

### 시스템 네비게이션 바 패딩
Android 제스처/버튼 내비게이션 바가 화면 하단을 가린다. `showModalBottomSheet`에는 반드시 아래 두 가지를 적용한다:
1. `useSafeArea: true` — 네비게이션 바 영역 자동 회피
2. 컨텐츠 하단 패딩에 `MediaQuery.of(ctx).viewPadding.bottom` 추가

키보드(`viewInsets.bottom`)와 네비게이션 바(`viewPadding.bottom`)는 별개다.

```dart
showModalBottomSheet(
  useSafeArea: true,
  isScrollControlled: true, // 키보드 대응 시 필요
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), // 키보드
    child: Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewPadding.bottom), // 네비게이션 바
    ),
  ),
);
```

### 색상 인덱스 주의
`Colors.grey`의 유효 인덱스는 50·100·200·300·400·500·600·700·800·**850**·**900**까지다. `Colors.grey[950]` 등 존재하지 않는 인덱스는 `null`을 반환하므로 `!` 연산자와 함께 쓰면 런타임 에러가 발생한다.

### 플랫폼 대응
Android/iOS 양 플랫폼을 지원한다. 플랫폼 분기가 필요한 경우 `Platform.isAndroid` / `Platform.isIOS`로 처리한다.
- `SystemNavigator.pop()` — Android 전용이므로 반드시 `if (Platform.isAndroid)` 조건 필요 (iOS는 앱 강제 종료 불가)

iOS 권한은 `ios/Runner/Info.plist`에서 관리한다. 현재 설정: 위치(`NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`), 배경 모드(`location`, `fetch`).

---

## 명령어

```bash
# 연결된 기기/에뮬레이터에서 실행
flutter run

# APK 빌드
flutter build apk --release

# iOS 빌드 (Mac + Xcode 필요)
flutter build ios --release

# 정적 분석 (lint)
flutter analyze

# 전체 테스트 실행
flutter test

# 런처 아이콘 재생성 (assets/icon/icon.png 변경 후)
dart run flutter_launcher_icons

# 스플래시 화면 재생성
dart run flutter_native_splash:create
```

---

## 아키텍처

Android/iOS를 지원하는 자전거 속도계 앱. 상태관리는 **Provider**, 로컬 저장소는 **sqflite**를 사용한다.

### 상태 레이어 — 두 개의 Provider

**`RideProvider`** (`lib/providers/ride_provider.dart`) — 앱의 핵심 런타임 상태 머신. GPS 스트림 구독, 200ms 보간 타이머, 거리 누적, 자동 일시정지 로직, 속도 알림 진동을 담당한다. `startRide()`로 스트림을 열고, `stopRide()`로 취소하고 DB에 기록을 저장한다. 최소 거리/시간 조건 미달 시 `null`을 반환하며 `stopFailReason`에 원인(`'distance'` 또는 `'duration'`)을 설정한다.

**`SettingsProvider`** (`lib/providers/settings_provider.dart`) — 모든 사용자 설정을 `SharedPreferences`로 영속화하는 래퍼. 앱 시작 시 `main()`에서 `settings.load()`를 호출한다. 각 setter는 `notifyListeners()` 후 즉시 `await prefs.set*()`으로 기록한다. 목표 관련 설정(`yearlyGoalKm`, `monthlyGoalKm`, `goalMaxSpeedKmh`, `goalMaxDistanceKm`, `goalMaxDurationMin`)도 이 Provider에서 관리한다.

두 Provider는 `main.dart`의 루트 `MultiProvider`에서 제공된다.

### 내비게이션

`MainScreen`은 `IndexedStack` + `NavigationBar`로 구성된 탭 5개짜리 구조다: 속도계 → 지도 → 기록 → 목표 → 설정. `IndexedStack`이므로 탭 전환 시 서브트리가 유지된다(상태 초기화 없음).

### 데이터 레이어

`DatabaseHelper` (`lib/db/database_helper.dart`) — sqflite를 감싸는 싱글턴. DB 파일명 `bike_speedometer.db`, 버전 4. 테이블: `ride_records` (`id, year, month, day, totalDistance, maxSpeed, avgSpeed, duration, pathPoints(JSON), createdAt(ms epoch), memo`).

`RideRecord` (`lib/models/ride_record.dart`) — `toMap()`/`fromMap()`을 가진 불변 데이터 클래스.

GPS 경로 좌표는 `pathPoints` 컬럼에 `[{lat, lng}, ...]` 형태의 JSON 문자열로 저장된다.

### 서비스

- **`LocationService`** — `geolocator` 래퍼. 플랫폼별 설정(Android: `AndroidSettings`, iOS: `AppleSettings`)으로 `Stream<Position>`을 반환한다.
- **`ForegroundServiceHelper`** — `flutter_local_notifications`로 주행 중 상태 알림을 관리한다. Android는 `AndroidNotificationDetails`, iOS는 `DarwinNotificationDetails`를 사용한다. 주행 시작 시 `start()`, 종료 시 `stop()` 호출.

### GPS 필터링 (`RideProvider._onPositionUpdate`)

GPS 업데이트마다 아래 세 필터를 순서대로 적용한다:
1. 정확도 게이트: `accuracy > 25m`이면 무시
2. 속도 급등 필터: 이전 속도 대비 3배 이상 급등하고 20 km/h 초과이면 무시
3. 드리프트 게이트: 이전 위치와의 거리가 3m 미만이면 거리 누적 안 함

화면에 표시되는 속도는 이전 GPS 속도와 새 속도 사이를 5단계로 선형 보간(200ms × 5 = 1초)하여 바늘이 부드럽게 움직이도록 한다.

### 테마

테마는 Flutter의 `ThemeData` 교체 방식으로 관리된다. `lib/core/theme/app_theme.dart`에 `AppTheme.dark` / `AppTheme.light`가 정의되어 있고, `MaterialApp`에 `theme` / `darkTheme` / `themeMode`로 주입된다. `SettingsProvider.themeMode`가 `ThemeMode`를 반환하며, `SettingsProvider.appTheme`(`'dark'`/`'light'`)은 설정 저장·UI 버튼에만 사용한다.

새 UI 추가 시 `final cs = Theme.of(context).colorScheme;`으로 색상을 가져온다:
- 배경: `cs.surface` · 카드/패널: `cs.surfaceContainer` · 버튼 비활성 배경: `cs.surfaceContainerHighest`
- 주 텍스트: `cs.onSurface` · 보조 텍스트: `cs.onSurfaceVariant`
- 구분선/테두리: `cs.outlineVariant` · 섹션 라벨: `cs.outline`
- `CustomPainter`처럼 context가 없는 경우엔 `isDark = Theme.of(context).brightness == Brightness.dark`를 부모에서 계산해 파라미터로 전달한다.

### 단위 변환

내부 값은 모두 **km/h**(속도), **km**(거리)로 저장·계산한다. `lib/utils/format_utils.dart`의 `formatSpeed`, `formatDistance`, `speedUnit`, `distanceUnit`, `convertSpeed`, `convertDistance`를 사용해 표시 시점에만 변환한다. 저장 시점에 변환하지 않는다.

### 네이버 지도

`flutter_naver_map`은 `main()`에서 클라이언트 ID `ua4rpblyze`로 초기화된다. 지도 타입(basic/satellite/hybrid)은 `SettingsProvider.mapType`에 저장된다.

---

## 화면별 설계

### 공통 자산

억지로 묶지 않되, 동일한 로직이나 UI 패턴이 여러 곳에서 반복된다고 판단되면 `lib/utils/` 또는 `lib/widgets/`로 분리한다.

- `lib/utils/format_utils.dart` — 속도·거리·시간·숫자 포맷, 단위 변환, 칼로리 계산
- `lib/widgets/number_input_dialog.dart` — 숫자 키패드 입력 다이얼로그. `allowDecimal: true`로 소수점 입력 활성화 가능. 반환 타입 `double?`, 빈 확인 시 `clearValue(-1)` 반환
- `lib/widgets/memo_bottom_sheet.dart` — 메모 입력 바텀시트. `showMemoBottomSheet(context, controller: ctrl)` 호출. 완료 시 `controller.text`에 값이 쓰여 반환되므로 호출 후 직접 읽으면 된다.
- `lib/widgets/stat_item.dart` — 통계 표시 위젯 2종:
  - `StatDetailItem(label, value, unit, textColor)` — 값(16px 굵게) + 단위(파란색, 선택) + 라벨(회색 11px). 주행 상세/요약 행에 사용.
  - `StatItem(label, value, textColor, {labelBlue})` — 값(13px 굵게) + 라벨(기본 회색, `labelBlue: true`이면 파란색). 목록 카드 내 통계 행에 사용.
- `lib/utils/backup_utils.dart` — 백업/복원 유틸. `shareBackup()` : 공유 시트 표시. `exportBackup()` : 파일 저장 위치 선택 → `true`=저장완료/`false`=취소. `pickBackupFile()` : 파일 선택 → 경로 반환(`null`=취소). `importFromPath(path, {onProgress})` : 파싱·삽입 → 새로 추가된 건수 반환. 가져오기 후 반드시 `ride.loadRecords()` 호출로 Provider 갱신.
- `lib/utils/gpx_utils.dart` — GPX 내보내기 유틸. `shareGpx(record)` : 단일 주행 GPX 공유. `shareAllGpx()` : 전체 기록 다중 트랙 GPX 공유. 표준 GPX 1.1 포맷 (Strava 등 호환).
- `lib/widgets/loading_overlay.dart` — 전화면 터치 차단 로딩 오버레이. `runWithLoading<T>(context, task: (setProgress) async { ... }, label: '...')` 호출. `setProgress(0.0~1.0)` 전달 시 진행률 바, `null` 전달 시 무한 스피너.

### 설정 화면 구조

설정 화면은 2단계 네비게이션으로 구성된다. `lib/screens/settings/` 폴더:
- `settings_screen.dart` — 대메뉴 목록 (주행·화면·알림·지도·사용자·시스템)
- `settings_widgets.dart` — 공통 위젯: `settingsIconBox`, `settingsPanelContainer`, `settingsOptionButton`
- `settings_ride.dart` — 속도 측정 모드·자동 일시정지·최소 기록 거리/시간·단위·GPS
- `settings_display.dart` — 주행 중 표시 항목·속도계 시계
- `settings_alert.dart` — 속도 초과/미달 알림·거리 알림
- `settings_map.dart` — 지도 스타일·경로 색상/두께·추적 모드
- `settings_user.dart` — 체중
- `settings_system.dart` — 테마·시작 탭·백업/내보내기·앱 정보·(개발 섹션)

모든 설정 아이콘 색상은 `Colors.lightBlue`로 통일. 알림 타일의 Switch 색(red/lightBlue/green)은 의미색이므로 제외.
앱 정보 상수(`_kAppName` 등)는 `_SettingsSystemScreenState`에서 수기 관리.

### 목표 화면 (`GoalScreen`)

`RideProvider.records`와 `SettingsProvider` 목표값만으로 동작하며 별도 DB 없음. 구성:
- **거리 목표** (올해/이번달) — 진행률 바, 달성 시 초록 체크. 목표값은 내부적으로 km 저장, 표시는 useKmh 단위 변환
- **도전 목표** (최고속도/최장거리/최장시간) — 현재 기록 대비 목표 표시. 최장시간은 분 단위 입력, 초 단위 저장
- **스트릭** — 설정 없음. records 날짜로 현재 연속일·역대 최장 계산. 오늘 또는 어제 주행이 있으면 스트릭 유지

### 속도 알림 (`speedAlertKmh`)

설정에서 켜면 두 가지 피드백이 동작한다:
- **진동** — 임계값 상향 돌파 시 1회 `HapticFeedback.heavyImpact()` (edge-trigger)
- **시각** — `currentSpeed >= speedAlertKmh`인 동안 속도계 숫자·게이지 호·바늘이 빨간색으로 변경. `SpeedometerPainter`의 `isOverAlert` 파라미터로 제어.

속도 알림 최솟값은 릴리즈 1 km/h, 디버그 0 km/h (`kDebugMode` 분기).

### 주요 설계 제약

- 설정 화면 `'백업 / 내보내기'` 타일 — 공유·파일저장·가져오기·GPX 내보내기 4가지 옵션을 바텀시트로 제공.
- 기록 상세 팝업 하단 버튼 — `[경로 보기] [GPX 공유]` 두 버튼 Row 구성.
- `개발` 섹션(데이터 제거 / 데이터 생성)은 `kDebugMode`일 때만 표시 — 릴리즈 빌드에서 자동 숨김.
- `wakelock_plus`로 주행 중 화면이 꺼지지 않도록 한다. `startRide()`에서 활성화, `stopRide()`에서 비활성화.

---

## 미결 TODO

- [ ] 지도 or 기타에 추가할 설정 고민
