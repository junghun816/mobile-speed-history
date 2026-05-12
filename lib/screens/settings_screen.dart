import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../db/database_helper.dart';
import '../db/sample_data.dart';
import '../providers/ride_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/number_input_dialog.dart';
import '../utils/backup_utils.dart';
import '../utils/gpx_utils.dart';
import '../widgets/loading_overlay.dart';
import '../models/speed_mode.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kAppName = '모바일 속도계';
  static const _kUpdateDate = '2026-04-29';
  static const _kDeveloperName = '김정훈';
  static const _kDeveloperEmail = 'kimjunghun816@gmail.com';

  bool _isDeleting = false;
  bool _isGenerating = false;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSharingExport = false;
  bool _isExportingGpx = false;
  String _appVersion = '';

  final _scrollController = ScrollController();
  final _tabScrollController = ScrollController();
  int _activeTab = 0;
  bool _isScrollingToSection = false;
  double _sectionActiveThreshold = 130.0;
  static const _tabLabels = ['테마', '주행', '화면', '알림', '지도', '기타'];
  final _sectionKeys = List.generate(6, (_) => GlobalKey());
  final _tabKeys = List.generate(6, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = info.version);
    }
  }

  void _onScroll() {
    if (_isScrollingToSection) return;
    if (!_scrollController.hasClients) return;
    int newActive = 0;
    for (int i = 0; i < _sectionKeys.length; i++) {
      final ctx = _sectionKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= _sectionActiveThreshold) {
        newActive = i;
      }
    }
    if (_activeTab != newActive) {
      setState(() => _activeTab = newActive);
      _scrollTabToVisible(newActive);
    }
  }

  void _scrollTabToVisible(int index) {
    final ctx = _tabKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  Future<void> _scrollToSection(int index) async {
    SystemSound.play(SystemSoundType.click);
    if (_activeTab != index) setState(() => _activeTab = index);
    _scrollTabToVisible(index);
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    _isScrollingToSection = true;
    await Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.0);
    if (mounted) _isScrollingToSection = false;
  }

  Widget _buildTabBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outline, width: 1.0)),
      ),
      child: ListView(
        controller: _tabScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: List.generate(_tabLabels.length, (i) {
          final isActive = _activeTab == i;
          return GestureDetector(
            key: _tabKeys[i],
            onTap: () => _scrollToSection(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isActive ? Colors.blue : cs.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  child: Text(_tabLabels[i]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showAppInfoDialog() {
    final cs = Theme.of(context).colorScheme;
    final textColor = cs.onSurface;
    final subColor = cs.onSurfaceVariant;
    final divColor = cs.outlineVariant;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.speed, color: Colors.blue, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                _kAppName,
                style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _appVersion.isEmpty ? '-' : 'v$_appVersion',
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Divider(color: divColor, height: 1),
              const SizedBox(height: 16),
              _infoRow('업데이트', _kUpdateDate, textColor, subColor),
              const SizedBox(height: 16),
              Divider(color: divColor, height: 1),
              const SizedBox(height: 16),
              _infoRow('개발자', _kDeveloperName, textColor, subColor),
              const SizedBox(height: 12),
              _infoRow('이메일', _kDeveloperEmail, textColor, subColor),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('닫기', style: TextStyle(color: subColor, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color textColor, Color subColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subColor, fontSize: 13)),
        Text(value, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 제거 확인'),
        content: const Text('모든 기록을 삭제합니다.\n되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    await DatabaseHelper.instance.deleteAllRecords();
    if (mounted) {
      await context.read<RideProvider>().loadRecords();
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 기록이 삭제되었습니다'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showBackupSheet() {
    final cs = Theme.of(context).colorScheme;
    final textColor = cs.onSurface;
    final subColor = cs.onSurfaceVariant;
    final panelColor = cs.surfaceContainerHighest;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainer,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + MediaQuery.of(ctx).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('백업 / 내보내기',
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _backupOptionTile(
              icon: Icons.share_outlined,
              color: Colors.orange,
              title: '공유하기',
              subtitle: '카카오톡·메일 등 앱으로 전송',
              textColor: textColor,
              subColor: subColor,
              panelColor: panelColor,
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isSharingExport = true);
                try {
                  await shareBackup();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('공유 실패: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isSharingExport = false);
                }
              },
            ),
            const SizedBox(height: 10),
            _backupOptionTile(
              icon: Icons.upload_file,
              color: Colors.teal,
              title: '파일로 저장',
              subtitle: '기기 내 원하는 위치에 JSON 저장',
              textColor: textColor,
              subColor: subColor,
              panelColor: panelColor,
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isExporting = true);
                try {
                  final saved = await exportBackup();
                  if (mounted && saved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('백업 파일이 저장되었습니다'),
                        backgroundColor: Colors.teal,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('내보내기 실패: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isExporting = false);
                }
              },
            ),
            const SizedBox(height: 10),
            _backupOptionTile(
              icon: Icons.download,
              color: Colors.blue,
              title: '가져오기',
              subtitle: '백업 파일에서 기록 복원 (중복 제외)',
              textColor: textColor,
              subColor: subColor,
              panelColor: panelColor,
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isImporting = true);
                try {
                  final path = await pickBackupFile();
                  if (path == null) return;
                  if (!mounted) return;

                  final count = await runWithLoading<int>(
                    context,
                    label: '불러오는 중...',
                    task: (setProgress) =>
                        importFromPath(path, onProgress: setProgress),
                  );

                  if (!mounted) return;
                  await context.read<RideProvider>().loadRecords();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(count > 0
                          ? '$count건 복원되었습니다'
                          : '새로 추가된 기록이 없습니다'),
                      backgroundColor: count > 0 ? Colors.teal : Colors.grey,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('가져오기 실패: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isImporting = false);
                }
              },
            ),
            const SizedBox(height: 10),
            _backupOptionTile(
              icon: Icons.route,
              color: Colors.deepPurple,
              title: 'GPX 내보내기',
              subtitle: '전체 기록을 GPX 파일로 공유 (Strava 등 호환)',
              textColor: textColor,
              subColor: subColor,
              panelColor: panelColor,
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isExportingGpx = true);
                try {
                  await shareAllGpx();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('GPX 내보내기 실패: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isExportingGpx = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _backupOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subColor,
    required Color panelColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: subColor, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 생성 확인'),
        content: const Text('기존 기록을 모두 지우고 임시 데이터를 생성합니다.\n되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('생성', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isGenerating = true);
    await SampleDataHelper.insertSampleData();
    if (mounted) {
      await context.read<RideProvider>().loadRecords();
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('임시 데이터 생성 완료'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;

    final panelColor = cs.surfaceContainer;
    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;
    final sectionColor = cs.outline;
    final btnBgOff = cs.surfaceContainerHighest;
    final btnBorderOff = cs.outlineVariant;
    final btnTextOff = cs.onSurfaceVariant;

    _sectionActiveThreshold = MediaQuery.of(context).padding.top + 88;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // 테마
                  SizedBox(key: _sectionKeys[0]),
                  _sectionTitle('테마', sectionColor),
                  _themeSelector(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
                  const SizedBox(height: 24),

                  // 주행
                  SizedBox(key: _sectionKeys[1]),
                  _sectionTitle('주행', sectionColor),
                  _speedModeTile(settings, panelColor, titleColor, subtitleColor),
                  const SizedBox(height: 10),
                  _switchTile(
                    icon: Icons.pause_circle_outline,
                    iconColor: Colors.deepOrange,
                    title: '자동 일시정지',
                    subtitle: '정지 감지 시 타이머 자동 일시정지',
                    value: settings.autoPause,
                    onChanged: (v) => settings.setAutoPause(v),
                    panelColor: panelColor,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                  ),
                  const SizedBox(height: 10),
                  _minDistanceTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
                  const SizedBox(height: 10),
                  _minDurationTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
                  const SizedBox(height: 10),
                  _toggleTile(
                    icon: Icons.speed,
                    iconColor: Colors.orange,
                    title: '단위',
                    subtitle: '속도/거리 표시 단위',
                    leftLabel: 'km/h',
                    rightLabel: 'mph',
                    isLeft: settings.useKmh,
                    onToggle: (v) => settings.setUseKmh(v),
                    panelColor: panelColor,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    btnBgOff: btnBgOff,
                    btnBorderOff: btnBorderOff,
                    btnTextOff: btnTextOff,
                  ),
                  const SizedBox(height: 10),
                  _toggleTile(
                    icon: Icons.gps_fixed,
                    iconColor: Colors.amber,
                    title: 'GPS 정확도',
                    subtitle: '고정밀 모드는 배터리를 더 소모해요',
                    leftLabel: '고정밀',
                    rightLabel: '배터리 절약',
                    isLeft: settings.gpsHighAccuracy,
                    onToggle: (v) => settings.setGpsHighAccuracy(v),
                    panelColor: panelColor,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    btnBgOff: btnBgOff,
                    btnBorderOff: btnBorderOff,
                    btnTextOff: btnTextOff,
                  ),
                  const SizedBox(height: 24),

                  // 화면
                  SizedBox(key: _sectionKeys[2]),
                  _sectionTitle('화면', sectionColor),
                  _gaugeSpeedTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
                  const SizedBox(height: 10),
                  _displayItemsTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
                  const SizedBox(height: 10),
                  _clockDisplayTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
                  const SizedBox(height: 24),

                  // 알림
                  SizedBox(key: _sectionKeys[3]),
                  _sectionTitle('알림', sectionColor),
                  _speedAlertTile(settings, panelColor, titleColor, subtitleColor, btnBgOff),
                  const SizedBox(height: 10),
                  _speedMinAlertTile(settings, panelColor, titleColor, subtitleColor, btnBgOff),
                  const SizedBox(height: 10),
                  _distanceAlertTile(settings, panelColor, titleColor, subtitleColor, btnBgOff),
                  const SizedBox(height: 24),

                  // 지도
                  SizedBox(key: _sectionKeys[4]),
                  _sectionTitle('지도', sectionColor),
                  _mapTypeTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
                  const SizedBox(height: 10),
                  _pathColorTile(settings, panelColor, titleColor, subtitleColor),
                  const SizedBox(height: 10),
                  _pathThicknessTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
                  const SizedBox(height: 10),
                  _mapTrackingModeTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
                  const SizedBox(height: 24),

                  // 기타
                  SizedBox(key: _sectionKeys[5]),
                  _sectionTitle('기타', sectionColor),
                  _startTabTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
                  const SizedBox(height: 10),
                  _weightTile(settings, panelColor, titleColor, subtitleColor, btnBgOff),
                  const SizedBox(height: 10),
                  _settingTile(
                    icon: Icons.upload_file,
                    iconColor: Colors.blueGrey,
                    title: '백업 / 내보내기',
                    subtitle: '주행 기록을 파일로 저장 · 복원',
                    onTap: () => _showBackupSheet(),
                    isLoading: _isExporting || _isImporting || _isSharingExport || _isExportingGpx,
                    loadingColor: Colors.blueGrey,
                    panelColor: panelColor,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                  ),
                  const SizedBox(height: 10),
                  _settingTile(
                    icon: Icons.info_outline,
                    iconColor: Colors.blueGrey,
                    title: '앱 정보',
                    subtitle: _appVersion.isEmpty ? _kAppName : '$_kAppName  v$_appVersion',
                    onTap: () => _showAppInfoDialog(),
                    isLoading: false,
                    loadingColor: Colors.blueGrey,
                    panelColor: panelColor,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                  ),
                  const SizedBox(height: 24),

                  if (kDebugMode) ...[
                    _sectionTitle('개발', sectionColor),
                    _settingTile(
                      icon: Icons.delete_outline,
                      iconColor: Colors.red,
                      title: '데이터 제거',
                      subtitle: '전체 기록 삭제',
                      onTap: (_isDeleting || _isGenerating) ? null : _deleteAllData,
                      isLoading: _isDeleting,
                      loadingColor: Colors.red,
                      panelColor: panelColor,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                    ),
                    const SizedBox(height: 10),
                    _settingTile(
                      icon: Icons.add_chart,
                      iconColor: Colors.blue,
                      title: '데이터 생성',
                      subtitle: '임시 샘플 데이터 삽입',
                      onTap: (_isDeleting || _isGenerating) ? null : _generateSampleData,
                      isLoading: _isGenerating,
                      loadingColor: Colors.blue,
                      panelColor: panelColor,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                    ),
                  ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clockDisplayTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const options = [
      ('none', '표시 안 함'),
      ('h24', '24시간'),
      ('h12', '12시간'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time, color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('속도계 시계',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('속도계 화면 상단에 현재 시각 표시',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: options.asMap().entries.map((e) {
              final (val, label) = e.value;
              final isLast = e.key == options.length - 1;
              final isOn = settings.clockDisplay == val;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setClockDisplay(val);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: isLast ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isOn ? Colors.blue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isOn ? Colors.blue : btnBorderOff),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isOn ? Colors.blue : btnTextOff,
                        fontSize: 12,
                        fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _gaugeSpeedTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const speeds = [60, 120, 180, 240];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.speed, color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('게이지 최대속도 기본값',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('속도계 실행 시 기본 최대 눈금',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: speeds.map((s) {
              final isSelected = settings.defaultGaugeSpeed == s;
              final isLast = s == speeds.last;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setDefaultGaugeSpeed(s);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: isLast ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      '$s',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : btnTextOff,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _displayItemsTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    final items = [
      ('거리', settings.showDistance, settings.setShowDistance),
      ('시간', settings.showDuration, settings.setShowDuration),
      ('최고속도', settings.showMaxSpeed, settings.setShowMaxSpeed),
      ('평균속도', settings.showAvgSpeed, settings.setShowAvgSpeed),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dashboard_outlined,
                    color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('주행 중 표시 항목',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('속도계 하단에 표시할 통계 선택',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final (label, isOn, setter) = e.value;
              final isLast = i == items.length - 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    setter(!isOn);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: isLast ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isOn ? Colors.blue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOn ? Colors.blue : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isOn ? Colors.blue : btnTextOff,
                        fontSize: 12,
                        fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _startTabTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const labels = ['속도계', '지도', '기록', '목표', '설정'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home_outlined, color: Colors.blueGrey, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('시작 탭',
                        style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('앱 실행 시 처음 열리는 탭',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(labels.length, (i) {
              final isSelected = settings.startTab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setStartTab(i);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: i < labels.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : btnTextOff,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _weightTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline,
                    color: Colors.blueGrey, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('체중',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('칼로리 추정에 사용됩니다',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  settings.setWeightKg((settings.weightKg ?? 70) - 1);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: btnBgOff,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.remove, color: titleColor, size: 20),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () async {
                  SystemSound.play(SystemSoundType.click);
                  final result = await NumberInputDialog.show(
                    context,
                    title: '체중 입력',
                    initialValue: settings.weightKg,
                    unit: 'kg',
                    maxDigits: 3,
                    allowEmpty: true,
                    allowDecimal: true,
                  );
                  if (result == null) return;
                  if (result == NumberInputDialog.clearValue) {
                    settings.setWeightKg(null);
                  } else {
                    settings.setWeightKg(result.toDouble());
                  }
                },
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: btnBgOff,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    settings.weightKg != null
                        ? '${settings.weightKg!.toInt()} kg'
                        : '--',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: settings.weightKg != null ? titleColor : subtitleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  settings.setWeightKg((settings.weightKg ?? 70) + 1);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: btnBgOff,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: titleColor, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String leftLabel,
    required String rightLabel,
    required bool isLeft,
    required void Function(bool) onToggle,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
    required Color btnBgOff,
    required Color btnBorderOff,
    required Color btnTextOff,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _twoStateButton(leftLabel, isLeft, () => onToggle(true),
                    btnBgOff: btnBgOff, btnBorderOff: btnBorderOff, btnTextOff: btnTextOff),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _twoStateButton(rightLabel, !isLeft, () => onToggle(false),
                    btnBgOff: btnBgOff, btnBorderOff: btnBorderOff, btnTextOff: btnTextOff),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _twoStateButton(String label, bool isSelected, VoidCallback onTap, {
    required Color btnBgOff,
    required Color btnBorderOff,
    required Color btnTextOff,
    Color activeColor = Colors.blue,
  }) {
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : btnBgOff,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : btnBorderOff,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? activeColor : btnTextOff,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _minDistanceTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const options = [0.0, 0.1, 0.5, 1.0];
    const labels = ['없음', '0.1 km', '0.5 km', '1.0 km'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.straighten, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('최소 기록 거리',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('미달 시 주행 종료 후 저장 안 됨',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(options.length, (i) {
              final isSelected = settings.minRecordDistanceKm == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setMinRecordDistanceKm(options[i]);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : btnTextOff,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _minDurationTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const options = [0, 60, 180, 300, 600];
    const labels = ['없음', '1분', '3분', '5분', '10분'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer_outlined, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('최소 기록 시간',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('미달 시 주행 종료 후 저장 안 됨',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(options.length, (i) {
              final isSelected = settings.minRecordDurationSec == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setMinRecordDurationSec(options[i]);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : btnTextOff,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _speedAlertTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff) {
    final inactiveTrackColor = Theme.of(context).colorScheme.outlineVariant;
    final isOn = settings.speedAlertKmh != null;
    final currentKmh = settings.speedAlertKmh?.toInt() ?? 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.speed_outlined,
                    color: Colors.red, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('속도 초과 알림',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('설정 속도 초과 시 진동 + 빨간색 표시',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: (v) {
                  SystemSound.play(SystemSoundType.click);
                  if (v) {
                    settings.setSpeedAlertKmh(currentKmh.toDouble());
                  } else {
                    settings.setSpeedAlertKmh(null);
                  }
                },
                activeThumbColor: Colors.red,
                activeTrackColor: Colors.red.withOpacity(0.4),
                inactiveTrackColor: inactiveTrackColor,
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    final next = (currentKmh - 5).clamp(kDebugMode ? 0 : 1, 999);
                    settings.setSpeedAlertKmh(next.toDouble());
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.remove, color: titleColor, size: 20),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () async {
                    SystemSound.play(SystemSoundType.click);
                    final result = await NumberInputDialog.show(
                      context,
                      title: '속도 알림 기준',
                      initialValue: settings.speedAlertKmh,
                      unit: 'km/h',
                      maxDigits: 3,
                      allowEmpty: false,
                      allowDecimal: false,
                    );
                    if (result == null) return;
                    settings.setSpeedAlertKmh(result.toDouble());
                  },
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$currentKmh km/h',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    final next = (currentKmh + 5).clamp(kDebugMode ? 0 : 1, 999);
                    settings.setSpeedAlertKmh(next.toDouble());
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: titleColor, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _speedMinAlertTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff) {
    final inactiveTrackColor = Theme.of(context).colorScheme.outlineVariant;
    final isOn = settings.speedMinAlertKmh != null;
    final currentKmh = settings.speedMinAlertKmh?.toInt() ?? 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.speed_outlined, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('속도 미달 알림',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('설정 속도 미만 시 진동 + 파란색 표시',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: (v) {
                  SystemSound.play(SystemSoundType.click);
                  settings.setSpeedMinAlertKmh(v ? currentKmh.toDouble() : null);
                },
                activeThumbColor: Colors.blue,
                activeTrackColor: Colors.blue.withOpacity(0.4),
                inactiveTrackColor: inactiveTrackColor,
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    final next = (currentKmh - 5).clamp(kDebugMode ? 0 : 1, 999);
                    settings.setSpeedMinAlertKmh(next.toDouble());
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.remove, color: titleColor, size: 20),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () async {
                    SystemSound.play(SystemSoundType.click);
                    final result = await NumberInputDialog.show(
                      context,
                      title: '속도 미달 알림 기준',
                      initialValue: settings.speedMinAlertKmh,
                      unit: 'km/h',
                      maxDigits: 3,
                      allowEmpty: false,
                      allowDecimal: false,
                    );
                    if (result == null) return;
                    settings.setSpeedMinAlertKmh(result.toDouble());
                  },
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$currentKmh km/h',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    final next = (currentKmh + 5).clamp(kDebugMode ? 0 : 1, 999);
                    settings.setSpeedMinAlertKmh(next.toDouble());
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: titleColor, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _distanceAlertTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff) {
    final inactiveTrackColor = Theme.of(context).colorScheme.outlineVariant;
    final isOn = settings.distanceAlertKm != null;
    final currentKm = settings.distanceAlertKm ?? 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.social_distance_outlined,
                    color: Colors.green, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('거리 알림',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('설정 km 도달마다 알림 · 진동',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: (v) {
                  SystemSound.play(SystemSoundType.click);
                  settings.setDistanceAlertKm(v ? currentKm : null);
                },
                activeThumbColor: Colors.green,
                activeTrackColor: Colors.green.withOpacity(0.4),
                inactiveTrackColor: inactiveTrackColor,
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setDistanceAlertKm((currentKm - 1).clamp(1, 999));
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.remove, color: titleColor, size: 20),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () async {
                    SystemSound.play(SystemSoundType.click);
                    final result = await NumberInputDialog.show(
                      context,
                      title: '거리 알림 기준',
                      initialValue: currentKm,
                      unit: 'km',
                      maxDigits: 3,
                      allowEmpty: false,
                      allowDecimal: false,
                    );
                    if (result == null) return;
                    settings.setDistanceAlertKm(result.toInt());
                  },
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$currentKm km',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setDistanceAlertKm((currentKm + 1).clamp(1, 999));
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: titleColor, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _mapTypeTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const options = ['basic', 'satellite', 'hybrid'];
    const labels = ['기본', '위성', '하이브리드'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map_outlined, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('지도 스타일',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('주행 지도 및 경로 지도에 적용',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(options.length, (i) {
              final isSelected = settings.mapType == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setMapType(options[i]);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : btnTextOff,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
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

  Widget _pathColorTile(SettingsProvider settings, Color panelColor, Color titleColor, Color subtitleColor) {
    const options = ['blue', 'red', 'green', 'orange', 'purple', 'yellow'];
    const labels = ['파랑', '빨강', '초록', '주황', '보라', '노랑'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.route, color: Colors.lightBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('경로 색상',
                    style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('주행·기록 지도의 경로 선 색상',
                    style: TextStyle(color: subtitleColor, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: settings.pathColor,
              dropdownColor: panelColor,
              borderRadius: BorderRadius.circular(10),
              onTap: () => SystemSound.play(SystemSoundType.click),
              onChanged: (val) {
                if (val == null) return;
                settings.setPathColor(val);
              },
              selectedItemBuilder: (_) => List.generate(options.length, (i) {
                final color = _pathStringToColor(options[i]);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(labels[i], style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                );
              }),
              items: List.generate(options.length, (i) {
                final color = _pathStringToColor(options[i]);
                return DropdownMenuItem<String>(
                  value: options[i],
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 4,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(labels[i], style: TextStyle(color: titleColor, fontSize: 13)),
                    ],
                  ),
                );
              }),
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pathThicknessTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const options = [3, 5, 8];
    const labels = ['얇게', '보통', '굵게'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.line_weight, color: Colors.cyan, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('경로 두께',
                        style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('주행·기록 지도의 경로 선 굵기',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(options.length, (i) {
              final isSelected = settings.pathThickness == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setPathThickness(options[i]);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : btnBorderOff,
                      ),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : btnTextOff,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _mapTrackingModeTile(SettingsProvider settings, Color panelColor,
      Color titleColor, Color subtitleColor, Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    const options = ['none', 'follow', 'face'];
    const labels = ['없음', '위치 추적', '방위 추적'];
    const descriptions = ['자동 이동 안 함', '현재 위치 따라감', '진행 방향 위로'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.my_location, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('지도 추적 모드 기본값',
                        style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('주행 지도 시작 시 초기 추적 모드',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(options.length, (i) {
              final isSelected = settings.mapTrackingMode == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setMapTrackingMode(options[i]);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : btnBorderOff,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.blue : btnTextOff,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          descriptions[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.blue.withOpacity(0.7) : subtitleColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _speedModeTile(
    SettingsProvider settings,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
  ) {
    const modes = SpeedMode.values;
    final selected = settings.speedMode;
    final cs = Theme.of(context).colorScheme;
    final btnBgOff = cs.surfaceContainerHighest;
    final btnBorderOff = cs.outlineVariant;
    final btnTextOff = cs.onSurfaceVariant;

    final modeIcons = {
      SpeedMode.normal: Icons.directions_bike,
      SpeedMode.lowSpeed: Icons.directions_run,
      SpeedMode.highSpeed: Icons.train,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(modeIcons[selected], color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('속도 측정 모드',
                      style: TextStyle(
                          color: titleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(selected.description,
                      style: TextStyle(color: subtitleColor, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: modes.map((mode) {
              final isSelected = mode == selected;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: mode != modes.last ? 6 : 0),
                  child: GestureDetector(
                    onTap: () {
                      SystemSound.play(SystemSoundType.click);
                      settings.setSpeedMode(mode);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.withOpacity(0.15) : btnBgOff,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue : btnBorderOff,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            modeIcons[mode],
                            size: 18,
                            color: isSelected ? Colors.blue : btnTextOff,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.blue : btnTextOff,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final inactiveTrackColor = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              SystemSound.play(SystemSoundType.click);
              onChanged(v);
            },
            activeThumbColor: Colors.blue,
            activeTrackColor: Colors.blue.withOpacity(0.4),
            inactiveTrackColor: inactiveTrackColor,
          ),
        ],
      ),
    );
  }

  Widget _themeSelector(SettingsProvider settings,
      Color panelColor, Color titleColor, Color subtitleColor,
      Color btnBgOff, Color btnBorderOff, Color btnTextOff) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.palette_outlined,
                    color: Colors.lightBlue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('테마',
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('속도계 화면 색상 테마',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _themeButton(settings, 'dark', Icons.dark_mode_outlined, 'Dark',
                      fixedBg: Colors.grey[900]!, fixedFg: Colors.white, btnBorderOff: btnBorderOff)),
              const SizedBox(width: 6),
              Expanded(
                  child: _themeButton(settings, 'light', Icons.light_mode_outlined, 'Light',
                      fixedBg: Colors.white, fixedFg: Colors.black87, btnBorderOff: btnBorderOff)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeButton(SettingsProvider settings, String theme, IconData icon, String label, {
    required Color fixedBg,
    required Color fixedFg,
    required Color btnBorderOff,
  }) {
    final isSelected = settings.appTheme == theme;
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        settings.setAppTheme(theme);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: fixedBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : btnBorderOff,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fixedFg, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fixedFg,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isLoading,
    required Color loadingColor,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return GestureDetector(
      onTap: onTap == null ? null : () {
        SystemSound.play(SystemSoundType.click);
        onTap();
      },
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: loadingColor,
                      ),
                    )
                  : const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
