import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pmgoroshi/presentation/routes/app_router.dart';
import 'package:pmgoroshi/core/permissions/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // supabase 초기화
  await Supabase.initialize(
    url: 'https://dkidaihvsiykayvfeieh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRraWRhaWh2c2l5a2F5dmZlaWVoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5NDMyMDAsImV4cCI6MjA1NzUxOTIwMH0.NGHYLonvqDYZSRoM2smTHqGGvxAgozREIDfhoyVH7Y4',
  );

  // 네이버 맵 초기화
  await NaverMapSdk.instance.initialize(
    clientId: 'ua6cqc07v3',
    onAuthFailed: (error) {
      print('네이버 맵 인증 실패: $error');
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

    return MaterialApp.router(
      title: 'QR 데이터 수집기',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
