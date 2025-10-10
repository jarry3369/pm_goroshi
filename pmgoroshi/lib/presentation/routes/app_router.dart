import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/presentation/pages/qr_scan/qr_scan_page.dart';
import 'package:pmgoroshi/presentation/pages/data_form/data_form_page.dart';
import 'package:pmgoroshi/presentation/pages/completion/completion_page.dart';
import 'package:pmgoroshi/presentation/pages/main_scaffold.dart';
import 'package:pmgoroshi/presentation/pages/submission_history/submission_history_page.dart';
import 'package:pmgoroshi/presentation/pages/my_reports/my_reports_page.dart';
import 'package:pmgoroshi/presentation/pages/my_reports/my_report_detail_page.dart';
import 'package:pmgoroshi/presentation/pages/settings/settings_page.dart';
import 'package:pmgoroshi/main.dart' show routeObserver;
import 'package:pmgoroshi/presentation/screens/splash_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    observers: [routeObserver],
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // 메인 쉘 라우트 (탭 네비게이션)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // 첫 번째 탭: QR 스캔
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                builder: (context, state) => const QRScanPage(),
              ),
            ],
          ),
          // 두 번째 탭: 신고 지도
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const SubmissionHistoryPage(),
              ),
            ],
          ),
          // 세 번째 탭: 내 신고
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-reports',
                builder: (context, state) => const MyReportsPage(),
              ),
            ],
          ),
          // 네 번째 탭: 설정
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),

      // 비탭 라우트
      GoRoute(
        path: '/form',
        builder: (context, state) {
          final qrData = state.extra as String?;
          return DataFormPage(qrData: qrData ?? '');
        },
      ),
      GoRoute(
        path: '/completion',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return CompletionPage(
            isSuccess: data?['isSuccess'] == true,
            errorMessage: data?['errorMessage'] as String?,
            submissionTime:
                data?['submissionTime'] != null
                    ? DateTime.parse(data!['submissionTime'] as String)
                    : DateTime.now(),
          );
        },
      ),
      GoRoute(
        path: '/my-reports/:id',
        builder: (context, state) {
          final reportId = state.pathParameters['id']!;
          return MyReportDetailPage(reportId: reportId);
        },
      ),
    ],
  );
}
