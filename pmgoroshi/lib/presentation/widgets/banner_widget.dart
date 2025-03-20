import 'package:flutter/material.dart';
import 'package:pmgoroshi/domain/entities/banner.dart' as app_banner;
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pmgoroshi/presentation/controllers/banner_provider.dart';

class BannerWidget extends ConsumerWidget {
  final app_banner.Banner banner;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;
  final int currentIndex;
  final int totalCount;

  const BannerWidget({
    Key? key,
    required this.banner,
    this.onDismiss,
    this.onTap,
    this.currentIndex = 1,
    this.totalCount = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 배경색 설정 (기본은 보라색 계열)
    final backgroundColor = _getBackgroundColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배너 내용
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 배너 이미지를 최상단에 표시 (있는 경우)
              if (banner.image_url != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9, // 카드와 동일한 비율
                    child: CachedNetworkImage(
                      imageUrl: banner.image_url!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),

              // 배너 내용
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      banner.content,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    // 확인 버튼
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _handleButtonTap(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(banner.button_text ?? '확인하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 배너 카운터 (오른쪽 상단)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$currentIndex/$totalCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // 타입 라벨 (왼쪽 상단)
          Positioned(top: 16, left: 16, child: _buildTypeLabel()),
        ],
      ),
    );
  }

  // 타입 라벨 위젯
  Widget _buildTypeLabel() {
    final label = banner.type_label ?? _getDefaultTypeLabel();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.pink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // 배너 색상 가져오기
  Color _getBackgroundColor() {
    if (banner.background_color != null) {
      // 16진수 문자열로부터 Color 객체 생성
      try {
        final hexColor = banner.background_color!;
        if (hexColor.startsWith('#')) {
          return Color(int.parse('0xFF${hexColor.substring(1)}'));
        }
        return Color(int.parse('0xFF$hexColor'));
      } catch (e) {
        // 파싱 실패시 기본 색상 반환
      }
    }

    // 타입별 기본 색상
    switch (banner.banner_type) {
      case app_banner.BannerType.video:
        return const Color(0xFF5E35B1);
      case app_banner.BannerType.image:
        return const Color(0xFF4527A0);
      case app_banner.BannerType.cinema:
        return const Color(0xFF1A1A1A);
      case app_banner.BannerType.basic:
      default:
        return const Color(0xFF3949AB);
    }
  }

  // 기본 타입 라벨 가져오기
  String _getDefaultTypeLabel() {
    switch (banner.banner_type) {
      case app_banner.BannerType.video:
        return '동영상형';
      case app_banner.BannerType.image:
        return '이미지형';
      case app_banner.BannerType.cinema:
        return '시네마형';
      case app_banner.BannerType.basic:
      default:
        return '기본형';
    }
  }

  // 버튼 클릭 처리
  void _handleButtonTap(BuildContext context, WidgetRef ref) {
    // 배너를 읽음으로 표시
    if (!banner.is_read) {
      ref.read(bannerProvider.notifier).markBannerAsRead(banner.id);
    }

    // 사용자 정의 탭 동작이 있으면 실행
    if (onTap != null) {
      onTap!();
      return;
    }

    // 액션 타입에 따라 다른 동작 수행
    if (banner.action_type == 'url' && banner.action_url != null) {
      _launchUrl(banner.action_url!);
    } else if (banner.action_type == 'route' && banner.action_url != null) {
      context.go(banner.action_url!);
    }

    // 배너 닫기
    if (onDismiss != null) {
      onDismiss!();
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
