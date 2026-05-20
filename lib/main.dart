import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/ride_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/speedometer_screen.dart';
import 'screens/map_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/foreground_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  await ForegroundServiceHelper.initNotifications();

  await FlutterNaverMap().init(
      clientId: 'ua4rpblyze',
      onAuthFailed: (ex) {
        switch (ex) {
          case NQuotaExceededException(:final message):
            print("사용량 초과 (message: $message)");
            break;
          case NUnauthorizedClientException() ||
          NClientUnspecifiedException() ||
          NAnotherAuthFailedException():
            print("인증 실패: $ex");
            break;
        }
      });

  final settings = SettingsProvider();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settings),
        ChangeNotifierProvider(create: (_) => RideProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _UnfocusObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    final ctx = navigator?.context;
    if (ctx != null) FocusScope.of(ctx).unfocus();
  }
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    final isAllowed = await ForegroundServiceHelper.isAllowed();
    if (!isAllowed) {
      await ForegroundServiceHelper.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        title: '모바일 속도계',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.themeMode,
        navigatorObservers: [_UnfocusObserver()],
        home: settings.shouldShowOnboarding
            ? const OnboardingScreen()
            : const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  void _showHistoryFilterPopup(BuildContext context, {bool navigateOnSelect = false}) {
    final ride = context.read<RideProvider>();
    final cs = Theme.of(context).colorScheme;
    final navBottom = MediaQuery.of(context).viewPadding.bottom;
    const navH = 80.0;

    showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => Stack(
        children: [
          Positioned(
            bottom: navH + navBottom + 8,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  color: cs.surfaceContainer,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _filterBtn(ctx, '전체', 'all', Icons.list_alt, ride.historyFilter, cs),
                        _filterBtn(ctx, '자전거', 'bike', Icons.directions_bike, ride.historyFilter, cs),
                        _filterBtn(ctx, '런닝', 'run', Icons.directions_run, ride.historyFilter, cs),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).then((filter) {
      if (filter != null && mounted) {
        SystemSound.play(SystemSoundType.click);
        context.read<RideProvider>().setHistoryFilter(filter);
        if (navigateOnSelect) setState(() => _currentIndex = 2);
      }
    });
  }

  Widget _filterBtn(BuildContext ctx, String label, String value, IconData icon, String current, ColorScheme cs) {
    final selected = current == value;
    final color = value == 'bike' ? Colors.blue : value == 'run' ? Colors.deepOrange : cs.onSurface;
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? color : cs.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : cs.onSurface,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentIndex = context.read<SettingsProvider>().startTab;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyFilter = context.watch<RideProvider>().historyFilter;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('한 번 더 누르면 종료됩니다'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.grey,
            ),
          );
        } else {
          if (Platform.isAndroid) SystemNavigator.pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            SpeedometerScreen(),
            MapScreen(),
            HistoryScreen(),
            GoalScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            if (index == 2) {
              _showHistoryFilterPopup(context, navigateOnSelect: _currentIndex != 2);
            } else {
              setState(() => _currentIndex = index);
            }
          },
          destinations: [
            const NavigationDestination(icon: Icon(Icons.speed), label: '속도계'),
            const NavigationDestination(icon: Icon(Icons.map), label: '지도'),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: historyFilter != 'all',
                smallSize: 8,
                backgroundColor: historyFilter == 'bike' ? Colors.blue : Colors.deepOrange,
                child: const Icon(Icons.history),
              ),
              label: '기록',
            ),
            const NavigationDestination(icon: Icon(Icons.flag), label: '목표'),
            const NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
          ],
        ),
      ),
    );
  }
}
