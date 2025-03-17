import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/presentation/pages/qr_scan/qr_scan_page.dart';
import 'package:pmgoroshi/presentation/pages/data_form/data_form_page.dart';
import 'package:pmgoroshi/presentation/pages/completion/completion_page.dart';
import 'package:pmgoroshi/main.dart' show routeObserver;

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/scan',
    observers: [routeObserver],
    routes: [
      GoRoute(path: '/scan', builder: (context, state) => const QRScanPage()),
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
    ],
  );
}
