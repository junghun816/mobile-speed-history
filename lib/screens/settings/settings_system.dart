import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../db/database_helper.dart';
import '../../db/sample_data.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/backup_utils.dart';
import '../../utils/gpx_utils.dart';
import '../../widgets/loading_overlay.dart';
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
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final panelColor = cs.surfaceContainer;
    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;
    final btnBgOff = cs.surfaceContainerHighest;
    final btnBorderOff = cs.outlineVariant;
    final btnTextOff = cs.onSurfaceVariant;
    final sectionColor = cs.outline;

    return Scaffold(
      appBar: AppBar(title: const Text('시스템')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _themeTile(settings, panelColor, titleColor, subtitleColor, btnBorderOff),
            SizedBox(height: 10.h),
            _startTabTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
            SizedBox(height: 10.h),
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

  Widget _themeTile(
    SettingsProvider settings,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
    Color btnBorderOff,
  ) {
    return settingsPanelContainer(
      panelColor: panelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              settingsIconBox(Icons.palette_outlined),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('테마',
                        style: TextStyle(color: titleColor, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2.h),
                    Text('속도계 화면 색상 테마',
                        style: TextStyle(color: subtitleColor, fontSize: 12.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _themeButton(settings, 'dark', Icons.dark_mode_outlined, 'Dark',
                  fixedBg: Colors.grey[900]!, fixedFg: Colors.white, btnBorderOff: btnBorderOff)),
              SizedBox(width: 6.w),
              Expanded(child: _themeButton(settings, 'light', Icons.light_mode_outlined, 'Light',
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
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: fixedBg,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? Colors.lightBlue : btnBorderOff,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fixedFg, size: 16.r),
            SizedBox(width: 6.w),
            Text(label,
                style: TextStyle(color: fixedFg, fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _startTabTile(
    SettingsProvider settings,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
    Color btnBgOff,
    Color btnBorderOff,
    Color btnTextOff,
  ) {
    const labels = ['속도계', '지도', '기록', '목표', '설정'];
    return settingsPanelContainer(
      panelColor: panelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              settingsIconBox(Icons.home_outlined),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('시작 탭',
                        style: TextStyle(color: titleColor, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2.h),
                    Text('앱 실행 시 처음 열리는 탭',
                        style: TextStyle(color: subtitleColor, fontSize: 12.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: List.generate(labels.length, (i) => Expanded(
              child: settingsOptionButton(
                labels[i], settings.startTab == i, () => settings.setStartTab(i),
                btnBgOff: btnBgOff, btnBorderOff: btnBorderOff, btnTextOff: btnTextOff,
                fontSize: 11,
                margin: EdgeInsets.only(right: i < labels.length - 1 ? 6.w : 0),
              ),
            )),
          ),
        ],
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
    Color iconColor = Colors.lightBlue,
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
                  color: Colors.lightBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(Icons.speed, color: Colors.lightBlue, size: 30.r),
              ),
              SizedBox(height: 14.h),
              Text(_kAppName,
                  style: TextStyle(color: textColor, fontSize: 20.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 4.h),
              Text(_appVersion.isEmpty ? '-' : 'v$_appVersion',
                  style: TextStyle(color: Colors.lightBlue, fontSize: 14.sp)),
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
              child: const Text('생성', style: TextStyle(color: Colors.lightBlue))),
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
