import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../db/database_helper.dart';
import '../../db/sample_data.dart';
import '../../providers/ride_provider.dart';
import '../../utils/utils_backup.dart';
import '../../utils/utils_gpx.dart';
import '../../widgets/widgets_loading_overlay.dart';
import 'settings_widgets.dart';

class SettingsSystemScreen extends StatefulWidget {
  const SettingsSystemScreen({super.key});

  @override
  State<SettingsSystemScreen> createState() => _SettingsSystemScreenState();
}

class _SettingsSystemScreenState extends State<SettingsSystemScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final panelColor = cs.surfaceContainer;
    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;
    final sectionColor = cs.outline;

    return Scaffold(
      appBar: AppBar(title: const Text('시스템')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _navTile(
              icon: Icons.upload_file,
              title: '백업 / 내보내기',
              subtitle: '주행 기록을 파일로 저장 · 복원',
              onTap: _showBackupSheet,
              isLoading: _isExporting || _isImporting || _isSharingExport || _isExportingGpx,
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            SizedBox(height: 10.h),
            _navTile(
              icon: Icons.balance_outlined,
              title: '오픈소스 라이선스',
              subtitle: '사용된 오픈소스 패키지 목록',
              onTap: _showOpenSourceSheet,
              isLoading: false,
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            SizedBox(height: 10.h),
            _navTile(
              icon: Icons.info_outline,
              title: '앱 정보',
              subtitle: _appVersion.isEmpty ? _kAppName : '$_kAppName  v$_appVersion',
              onTap: _showAppInfoDialog,
              isLoading: false,
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            if (kDebugMode) ...[
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
                child: Text('개발',
                    style: TextStyle(color: sectionColor, fontSize: 12.sp,
                        fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
              _navTile(
                icon: Icons.delete_outline,
                title: '데이터 제거',
                subtitle: '전체 기록 삭제',
                onTap: (_isDeleting || _isGenerating) ? null : _deleteAllData,
                isLoading: _isDeleting,
                panelColor: panelColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                iconColor: Colors.red,
              ),
              SizedBox(height: 10.h),
              _navTile(
                icon: Icons.add_chart,
                title: '데이터 생성',
                subtitle: '임시 샘플 데이터 삽입',
                onTap: (_isDeleting || _isGenerating) ? null : _generateSampleData,
                isLoading: _isGenerating,
                panelColor: panelColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isLoading,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
    Color iconColor = Colors.blueGrey,
  }) {
    return GestureDetector(
      onTap: onTap == null ? null : () {
        SystemSound.play(SystemSoundType.click);
        onTap();
      },
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: settingsPanelContainer(
          panelColor: panelColor,
          child: Row(
            children: [
              settingsIconBox(icon, color: iconColor),
              SizedBox(width: 14.w),
              Expanded(child: settingsTileLabel(title, subtitle, titleColor, subtitleColor)),
              isLoading
                  ? SizedBox(width: 20.r, height: 20.r,
                      child: CircularProgressIndicator(strokeWidth: 2, color: iconColor))
                  : Icon(Icons.chevron_right, color: subtitleColor, size: 20.r),
            ],
          ),
        ),
      ),
    );
  }

  void _showOpenSourceSheet() {
    const packages = [
      ('flutter_naver_map',        'MIT',          '네이버 지도 SDK Flutter 래퍼'),
      ('geolocator',               'MIT',          'GPS 위치 정보 수집'),
      ('sqflite',                  'MIT',          'SQLite 로컬 데이터베이스'),
      ('provider',                 'MIT',          '상태 관리'),
      ('shared_preferences',       'BSD-3-Clause', '키-값 로컬 설정 저장'),
      ('path_provider',            'BSD-3-Clause', '플랫폼 파일 경로 접근'),
      ('path',                     'BSD-3-Clause', '파일 경로 유틸리티'),
      ('share_plus',               'BSD-3-Clause', '시스템 공유 시트'),
      ('file_picker',              'MIT',          '파일 선택 다이얼로그'),
      ('flutter_foreground_task',  'MIT',          '포그라운드 서비스 관리'),
      ('flutter_local_notifications', 'MIT',       '로컬 푸시 알림'),
      ('wakelock_plus',            'MIT',          '화면 켜짐 유지'),
      ('flutter_screenutil',       'MIT',          '반응형 UI 크기 조정'),
      ('flutter_tts',              'MIT',          '텍스트 음성 변환 (TTS)'),
      ('audioplayers',             'MIT',          '오디오 재생'),
      ('vibration',                'MIT',          '진동 피드백'),
      ('table_calendar',           'Apache-2.0',   '달력 위젯'),
      ('intl',                     'BSD-3-Clause', '국제화 및 날짜 포맷'),
      ('package_info_plus',        'BSD-3-Clause', '앱 버전 정보'),
      ('flutter_launcher_icons',   'MIT',          '런처 아이콘 생성 도구'),
      ('flutter_native_splash',    'MIT',          '스플래시 화면 생성 도구'),
      ('cupertino_icons',          'MIT',          'iOS 스타일 아이콘'),
    ];

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Container(
                  width: 40.w, height: 4.h,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('오픈소스 라이선스',
                      style: TextStyle(color: cs.onSurface, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: packages.length,
                  separatorBuilder: (_, __) => Divider(color: cs.outlineVariant, height: 1),
                  itemBuilder: (_, i) {
                    final (name, license, desc) = packages[i];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: TextStyle(color: cs.onSurface, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                SizedBox(height: 2.h),
                                Text(desc,
                                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp)),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(license,
                                style: TextStyle(color: Colors.blueGrey, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h + MediaQuery.of(ctx).viewPadding.bottom),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showLicensePage(
                        context: context,
                        applicationName: _kAppName,
                        applicationVersion: _appVersion,
                      );
                    },
                    child: Text('전체 라이선스 원문 보기',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.sp)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Padding(
          padding: EdgeInsets.all(28.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.r, height: 56.r,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(Icons.speed, color: Colors.blueGrey, size: 30.r),
              ),
              SizedBox(height: 14.h),
              Text(_kAppName,
                  style: TextStyle(color: textColor, fontSize: 20.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 4.h),
              Text(_appVersion.isEmpty ? '-' : 'v$_appVersion',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 14.sp)),
              SizedBox(height: 20.h),
              Divider(color: divColor, height: 1),
              SizedBox(height: 16.h),
              _infoRow('업데이트', _kUpdateDate, textColor, subColor),
              SizedBox(height: 16.h),
              Divider(color: divColor, height: 1),
              SizedBox(height: 16.h),
              _infoRow('개발자', _kDeveloperName, textColor, subColor),
              SizedBox(height: 12.h),
              _infoRow('이메일', _kDeveloperEmail, textColor, subColor),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('닫기', style: TextStyle(color: subColor, fontSize: 14.sp)),
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
        Text(label, style: TextStyle(color: subColor, fontSize: 13.sp)),
        Text(value, style: TextStyle(color: textColor, fontSize: 13.sp, fontWeight: FontWeight.w500)),
      ],
    );
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h + MediaQuery.of(ctx).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('백업 / 내보내기',
                style: TextStyle(color: textColor, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            _backupOption(Icons.share_outlined, Colors.orange, '공유하기', '카카오톡·메일 등 앱으로 전송',
                textColor, subColor, panelColor, () async {
              Navigator.pop(ctx);
              setState(() => _isSharingExport = true);
              try { await shareBackup(); }
              catch (e) { _showError('공유 실패: $e'); }
              finally { if (mounted) setState(() => _isSharingExport = false); }
            }),
            SizedBox(height: 10.h),
            _backupOption(Icons.upload_file, Colors.teal, '파일로 저장', '기기 내 원하는 위치에 JSON 저장',
                textColor, subColor, panelColor, () async {
              Navigator.pop(ctx);
              setState(() => _isExporting = true);
              try {
                final saved = await exportBackup();
                if (mounted && saved) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('백업 파일이 저장되었습니다'),
                      backgroundColor: Colors.teal, duration: Duration(seconds: 2)));
                }
              }
              catch (e) { _showError('내보내기 실패: $e'); }
              finally { if (mounted) setState(() => _isExporting = false); }
            }),
            SizedBox(height: 10.h),
            _backupOption(Icons.download, Colors.lightBlue, '가져오기', '백업 파일에서 기록 복원 (중복 제외)',
                textColor, subColor, panelColor, () async {
              Navigator.pop(ctx);
              setState(() => _isImporting = true);
              try {
                final path = await pickBackupFile();
                if (path == null) return;
                if (!mounted) return;
                final count = await runWithLoading<int>(context, label: '불러오는 중...',
                    task: (setProgress) => importFromPath(path, onProgress: setProgress));
                if (!mounted) return;
                await context.read<RideProvider>().loadRecords();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(count > 0 ? '$count건 복원되었습니다' : '새로 추가된 기록이 없습니다'),
                    backgroundColor: count > 0 ? Colors.teal : Colors.grey,
                    duration: const Duration(seconds: 3)));
              }
              catch (e) { _showError('가져오기 실패: $e'); }
              finally { if (mounted) setState(() => _isImporting = false); }
            }),
            SizedBox(height: 10.h),
            _backupOption(Icons.route, Colors.deepPurple, 'GPX 내보내기', '전체 기록을 GPX 파일로 공유 (Strava 등 호환)',
                textColor, subColor, panelColor, () async {
              Navigator.pop(ctx);
              setState(() => _isExportingGpx = true);
              try { await shareAllGpx(); }
              catch (e) { _showError('GPX 내보내기 실패: $e'); }
              finally { if (mounted) setState(() => _isExportingGpx = false); }
            }),
          ],
        ),
      ),
    );
  }

  Widget _backupOption(
    IconData icon, Color color, String title, String subtitle,
    Color textColor, Color subColor, Color panelColor, VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () { SystemSound.play(SystemSoundType.click); onTap(); },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12.r)),
        child: Row(
          children: [
            Container(
              width: 36.r, height: 36.r,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10.r)),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColor, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2.h),
                  Text(subtitle, style: TextStyle(color: subColor, fontSize: 12.sp)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20.r),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 제거 확인'),
        content: const Text('모든 기록을 삭제합니다.\n되돌릴 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    await DatabaseHelper.instance.deleteAllRecords();
    if (mounted) {
      await context.read<RideProvider>().loadRecords();
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('모든 기록이 삭제되었습니다'),
          backgroundColor: Colors.red, duration: Duration(seconds: 2)));
    }
  }

  Future<void> _generateSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 생성 확인'),
        content: const Text('기존 기록을 모두 지우고 임시 데이터를 생성합니다.\n되돌릴 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('생성', style: TextStyle(color: Colors.blueGrey))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isGenerating = true);
    await SampleDataHelper.insertSampleData();
    if (mounted) {
      await context.read<RideProvider>().loadRecords();
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('임시 데이터 생성 완료'),
          backgroundColor: Colors.green, duration: Duration(seconds: 2)));
    }
  }
}
