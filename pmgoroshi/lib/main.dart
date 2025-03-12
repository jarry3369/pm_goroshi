import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pmgoroshi/presentation/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
