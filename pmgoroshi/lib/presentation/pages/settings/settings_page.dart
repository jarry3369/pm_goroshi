import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: '앱 정보',
            children: [
              _buildListTile(
                context,
                title: '버전',
                trailing: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Text('버전 확인 불가');
                    }

                    final info = snapshot.data!;
                    return Text('${info.version}+${info.buildNumber}');
                  },
                ),
              ),

              _buildListTile(
                context,
                title: '데이터 수집 동의',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // 동의 정보 페이지로 이동
                  final url =
                      'https://sites.google.com/view/clean-road-privacy';
                  launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ),
          // const SizedBox(height: 16),
          // _buildSection(
          //   context,
          //   title: '계정',
          //   children: [
          //     _buildListTile(
          //       context,
          //       title: '로그아웃',
          //       trailing: const Icon(Icons.logout, color: Colors.red),
          //       onTap: () {
          //         // 로그아웃 처리
          //       },
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(title: Text(title), trailing: trailing, onTap: onTap);
  }
}
