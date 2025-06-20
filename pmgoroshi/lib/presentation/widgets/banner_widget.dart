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
    final textColor = _getTextColor(Color(0xFFF5F5F5));
    // _buildHeader(),

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            // 이미지 영역 (있는 경우에만)
            if (banner.image_url != null) _buildImageSection(),

            // 콘텐츠 영역
            _buildContentSection(context, textColor, ref),
          ],
        ),
      ),
    );
  }

  // 이미지 섹션
  Widget _buildImageSection() {
    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: banner.image_url!,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder:
              (context, url) => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey.shade400,
                  ),
                ),
              ),
          errorWidget:
              (context, url, error) => const Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 48,
              ),
        ),
      ),
    );
  }

  // 콘텐츠 섹션
  Widget _buildContentSection(
    BuildContext context,
    Color textColor,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            banner.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // 내용
          Text(
            banner.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black54,
              height: 1.5,
            ),
          ),

          // 버튼 (조건부)
          if ((banner.action_type == 'url' || banner.action_type == 'route') &&
              banner.action_url != null &&
              banner.action_url!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ElevatedButton(
                onPressed: () => _handleButtonTap(context, ref),
                child: Text(banner.button_text ?? '확인하기'),
              ),
            ),
        ],
      ),
    );
  }

  // 배경색에 따른 텍스트 색상 결정
  Color _getTextColor(Color backgroundColor) {
    // 배경색이 어두운지 확인
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
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
