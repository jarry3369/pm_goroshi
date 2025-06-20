import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkVersionAndProceed();
  }

  Future<void> _checkVersionAndProceed() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Remote Config 초기화 fetch
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.fetchAndActivate();

      final minimumVersion = remoteConfig.getString('minimum_version');

      // 버전 비교
      if (_isVersionLower(currentVersion, minimumVersion)) {
        _showUpdateDialog();
      } else {
        _goToScan();
      }
    } catch (e) {
      _showErrorAndExit();
    }
  }

  bool _isVersionLower(String current, String minimum) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> minimumParts = minimum.split('.').map(int.parse).toList();
    for (int i = 0; i < minimumParts.length; i++) {
      if (currentParts.length <= i || currentParts[i] < minimumParts[i]) {
        return true;
      } else if (currentParts[i] > minimumParts[i]) {
        return false;
      }
    }
    return false;
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 강제 업데이트
      builder:
          (context) => AlertDialog(
            title: const Text('업데이트 필요'),
            content: const Text('최신 버전으로 업데이트가 필요합니다.'),
            actions: [
              TextButton(
                onPressed: () async {
                  final packageInfo = await PackageInfo.fromPlatform();
                  final url =
                      'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
                  launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: const Text('업데이트'),
              ),
            ],
          ),
    );
  }

  void _showErrorAndExit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('오류 발생'),
            content: const Text('앱 실행에 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else if (Platform.isIOS) {
                    exit(0);
                  }
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _goToScan() {
    // /scan으로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/scan');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
