import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/format_utils.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NaverMapController? _mapController;
  NLocationOverlay? _locationOverlay;

  // 경로 오버레이 관리
  bool _pathOverlayAdded = false;
  int _lastPathLength = 0;
  String? _lastPathColor;
  int? _lastPathThickness;

  // 속도 뱃지 드래그 & 리사이즈
  double _badgeLeft = 12.0;
  double _badgeTop = 12.0;
  double _badgeScale = 1.0;
  bool _isResizeMode = false;
  static const double _handleSize = 18.0;
  static const double _handlePad = _handleSize / 2;
  final _mapStackKey = GlobalKey();
  final _badgeWidgetKey = GlobalKey();

  // 마커 보간용
  NLatLng? _prevLatLng;
  NLatLng? _targetLatLng;
  NLatLng? _lastGpsLatLng;   // GPS 변경 감지
  DateTime? _lastGpsUpdateAt;

  NMapType _toNMapType(String type) {
    switch (type) {
      case 'satellite': return NMapType.satellite;
      case 'hybrid': return NMapType.hybrid;
      default: return NMapType.basic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final cs = Theme.of(context).colorScheme;
    final cardColor = cs.surfaceContainer;
    final textColor = cs.onSurface;
    final dividerColor = cs.outlineVariant;

    if (_mapController != null && ride.pathPoints.isNotEmpty) {
      final needsRedraw = ride.pathPoints.length != _lastPathLength ||
          settings.pathColor != _lastPathColor ||
          settings.pathThickness != _lastPathThickness;
      if (needsRedraw) {
        _lastPathLength = ride.pathPoints.length;
        _lastPathColor = settings.pathColor;
        _lastPathThickness = settings.pathThickness;
        _drawPath(ride.pathPoints, settings.pathColor, settings.pathThickness);
      }

      final last = ride.pathPoints.last;
      final latLng = NLatLng(last.latitude, last.longitude);

      // 새 GPS 좌표가 왔을 때만 보간 목표 갱신
      if (_lastGpsLatLng == null ||
          _lastGpsLatLng!.latitude != latLng.latitude ||
          _lastGpsLatLng!.longitude != latLng.longitude) {
        _prevLatLng = _targetLatLng ?? latLng;
        _targetLatLng = latLng;
        _lastGpsLatLng = latLng;
        _lastGpsUpdateAt = DateTime.now();
      }

      // 경과 시간 기반 보간 (1초에 걸쳐 이동)
      if (_prevLatLng != null && _targetLatLng != null && _lastGpsUpdateAt != null) {
        final t = (DateTime.now().difference(_lastGpsUpdateAt!).inMilliseconds / 1000.0).clamp(0.0, 1.0);
        final interpLat = _prevLatLng!.latitude + (_targetLatLng!.latitude - _prevLatLng!.latitude) * t;
        final interpLng = _prevLatLng!.longitude + (_targetLatLng!.longitude - _prevLatLng!.longitude) * t;
        _updateLocationMarker(NLatLng(interpLat, interpLng));
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
          // 지도
          Expanded(
            key: ValueKey(settings.mapType),
            child: Stack(
              key: _mapStackKey,
              children: [
            NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: const NCameraPosition(
                  target: NLatLng(37.5665, 126.9780),
                  zoom: 15,
                ),
                locationButtonEnable: true,
                mapType: _toNMapType(settings.mapType),
              ),
              onMapReady: (controller) async {
                _mapController = controller;

                _locationOverlay = await controller.getLocationOverlay();
                _locationOverlay?.setIsVisible(true);

                final trackingMode = _toTrackingMode(settings.mapTrackingMode);
                controller.setLocationTrackingMode(trackingMode);

                try {
                  final position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                  );

                  _locationOverlay?.setPosition(
                    NLatLng(position.latitude, position.longitude),
                  );

                  // 애니메이션 없이 바로 이동 (reason: 멀미 방지)
                  await controller.updateCamera(
                    NCameraUpdate.scrollAndZoomTo(
                      target: NLatLng(position.latitude, position.longitude),
                      zoom: 16,
                    )..setAnimation(
                      animation: NCameraAnimation.none,
                    ),
                  );
                } catch (e) {
                  print('위치 가져오기 실패: $e');
                }
              },
            ),
            if (_isResizeMode)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isResizeMode = false),
                ),
              ),
            Positioned(
              key: const ValueKey('speed_badge'),
              left: _badgeLeft - _handlePad,
              top: _badgeTop - _handlePad,
              child: _speedBadgeComposite(ride, settings),
            ),
          ]),
          ),

          // 하단 통계
          Container(
            color: cardColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard('거리',
                    '${formatDistance(ride.totalDistance, useKmh)}', distanceUnit(useKmh), textColor),
                _divider(dividerColor),
                _statCard('시간', ride.formattedDuration, '', textColor),
                _divider(dividerColor),
                _statCard('최고속도',
                    '${formatSpeed(ride.maxSpeed, useKmh)}', speedUnit(useKmh), textColor),
                _divider(dividerColor),
                _statCard('평균속도',
                    '${formatSpeed(_avgSpeed(ride), useKmh)}', speedUnit(useKmh), textColor),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _updateLocationMarker(NLatLng latLng) {
    _locationOverlay?.setPosition(latLng);
  }

  Color _pathStringToColor(String name) {
    switch (name) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'yellow': return Colors.yellow;
      default: return Colors.blue;
    }
  }

  NLocationTrackingMode _toTrackingMode(String mode) {
    switch (mode) {
      case 'follow': return NLocationTrackingMode.follow;
      case 'face': return NLocationTrackingMode.face;
      default: return NLocationTrackingMode.none;
    }
  }

  Future<void> _drawPath(List<Position> positions, String colorName, int thickness) async {
    if (_mapController == null) return;

    if (_pathOverlayAdded) {
      await _mapController!.deleteOverlay(
        const NOverlayInfo(type: NOverlayType.polylineOverlay, id: 'ride_path'),
      );
      _pathOverlayAdded = false;
    }

    if (positions.length < 2) return;

    final coords = positions
        .map((p) => NLatLng(p.latitude, p.longitude))
        .toList();

    final polyline = NPolylineOverlay(
      id: 'ride_path',
      coords: coords,
      color: _pathStringToColor(colorName),
      width: thickness.toDouble(),
    );

    await _mapController!.addOverlay(polyline);
    _pathOverlayAdded = true;
  }

  double _avgSpeed(RideProvider ride) {
    final durationHours = ride.duration / 3600.0;
    return durationHours > 0 ? ride.totalDistance / durationHours : 0.0;
  }

  Widget _speedBadgeComposite(RideProvider ride, SettingsProvider settings) {
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isResizeMode = !_isResizeMode),
      onPanStart: (_) {
        if (_isResizeMode) setState(() => _isResizeMode = false);
      },
      onPanUpdate: (d) {
        if (_isResizeMode) return;
        final mapBox = _mapStackKey.currentContext?.findRenderObject() as RenderBox?;
        final mapHeight = mapBox?.size.height ?? screenSize.height;
        final badgeBox = _badgeWidgetKey.currentContext?.findRenderObject() as RenderBox?;
        final badgeW = badgeBox?.size.width ?? 60.0;
        final badgeH = badgeBox?.size.height ?? 60.0;
        setState(() {
          _badgeLeft = (_badgeLeft + d.delta.dx).clamp(0.0, screenSize.width - badgeW);
          _badgeTop = (_badgeTop + d.delta.dy).clamp(0.0, mapHeight - badgeH);
        });
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(_handlePad),
            child: _speedBadgeWidget(ride, settings),
          ),
          if (_isResizeMode) ...[
            Positioned(top: 0, left: 0,     child: _resizeHandle(0)),
            Positioned(top: 0, right: 0,    child: _resizeHandle(1)),
            Positioned(bottom: 0, left: 0,  child: _resizeHandle(2)),
            Positioned(bottom: 0, right: 0, child: _resizeHandle(3)),
          ],
        ],
      ),
    );
  }

  Widget _speedBadgeWidget(RideProvider ride, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = _badgeScale;
    return Container(
      key: _badgeWidgetKey,
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 8 * s),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.82),
        borderRadius: BorderRadius.circular(14 * s),
        border: _isResizeMode
            ? Border.all(color: Colors.blue.withOpacity(0.7), width: 1.5)
            : null,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatSpeed(ride.currentSpeed, settings.useKmh),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 36 * s,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          Text(
            speedUnit(settings.useKmh),
            style: TextStyle(color: Colors.grey, fontSize: 13 * s),
          ),
        ],
      ),
    );
  }

  Widget _resizeHandle(int corner) {
    return GestureDetector(
      onPanUpdate: (d) {
        setState(() {
          final badgeBox = _badgeWidgetKey.currentContext?.findRenderObject() as RenderBox?;
          final naturalW = (badgeBox?.size.width ?? 80.0) / _badgeScale;
          final naturalH = (badgeBox?.size.height ?? 60.0) / _badgeScale;

          final double delta = switch (corner) {
            0 => (-d.delta.dx - d.delta.dy) / 80, // TL
            1 => (d.delta.dx - d.delta.dy) / 80,  // TR
            2 => (-d.delta.dx + d.delta.dy) / 80, // BL
            _ => (d.delta.dx + d.delta.dy) / 80,  // BR
          };
          final oldScale = _badgeScale;
          _badgeScale = (_badgeScale + delta).clamp(0.5, 3.0);
          final diff = _badgeScale - oldScale;

          // 반대편 코너를 고정점으로 — 좌측 핸들은 우측 고정, 상단 핸들은 하단 고정
          if (corner == 0 || corner == 2) _badgeLeft -= naturalW * diff;
          if (corner == 0 || corner == 1) _badgeTop -= naturalH * diff;
        });
      },
      child: Container(
        width: _handleSize,
        height: _handleSize,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, String unit, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: const TextStyle(color: Colors.blue, fontSize: 11)),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _divider(Color color) {
    return Container(height: 40, width: 1, color: color);
  }
}