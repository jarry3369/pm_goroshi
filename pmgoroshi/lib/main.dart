import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pmgoroshi/firebase_options.dart';
import 'package:pmgoroshi/presentation/routes/app_router.dart';
import 'package:pmgoroshi/core/permissions/permission_handler.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pmgoroshi/data/services/push_notification_service.dart';
import 'package:logger/logger.dart';

// RouteObserver 전역 변수 정의
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // supabase 초기화
  await Supabase.initialize(
    url: 'https://dkidaihvsiykayvfeieh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRraWRhaWh2c2l5a2F5dmZlaWVoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5NDMyMDAsImV4cCI6MjA1NzUxOTIwMH0.NGHYLonvqDYZSRoM2smTHqGGvxAgozREIDfhoyVH7Y4',
  );

  // 네이버 맵 초기화
  await FlutterNaverMap().init(
    clientId: 'sllctg6180',
    onAuthFailed: (error) {
      final logger = Logger();
      logger.w('네이버 맵 인증 실패: $error');
    },
  );

  // 앱 시작 시 위치 권한 요청
  final permissionHandler = AppPermissionHandler();
  await permissionHandler.requestInitialLocationPermission();

  // 앱 실행
  runApp(const ProviderScope(child: QRDataCollectorApp()));
}

class QRDataCollectorApp extends ConsumerWidget {
  const QRDataCollectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ref.read(pushNotificationServiceProvider);

    return MaterialApp.router(
      title: 'QR 데이터 수집기',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF3B82F6),
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF3B82F6),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            elevation: 0,
            side: const BorderSide(color: Color(0xFF3B82F6)),
            foregroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
