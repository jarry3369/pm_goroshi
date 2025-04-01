import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pmgoroshi/domain/entities/banner.dart' as app_banner;
import 'package:pmgoroshi/presentation/controllers/banner_provider.dart';
import 'package:pmgoroshi/presentation/widgets/banner_widget.dart';

class BannerCarousel extends ConsumerStatefulWidget {
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final Curve autoPlayCurve;
  final bool showIndicator;
  final VoidCallback? onRefresh;

  const BannerCarousel({
    Key? key,
    this.height = 520, // 모달 높이 증가
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 800),
    this.autoPlayCurve = Curves.fastOutSlowIn,
    this.showIndicator = true,
    this.onRefresh,
  }) : super(key: key);

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 페이지 변경 감지
    _pageController.addListener(() {
      if (_pageController.page != null) {
        final page = _pageController.page!.round();
        if (page != _currentPage) {
          setState(() {
            _currentPage = page;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // displayableBannersProvider를 사용하여 '다시 보지 않기'가 설정되지 않은 배너만 표시
    final bannersAsyncValue = ref.watch(displayableBannersProvider);

    debugPrint('BannerCarousel build: ${bannersAsyncValue.toString()}');

    return bannersAsyncValue.when(
      data: (banners) {
        debugPrint('BannerCarousel data: ${banners.length} 배너');
        if (banners.isEmpty) {
          // 표시할 배너가 없으면 닫기 버튼 표시
          debugPrint('BannerCarousel: 표시할 배너가 없습니다');
          return _buildNoBannersView(context);
        }

        debugPrint('BannerCarousel: ${banners.length}개 배너 표시');
        for (int i = 0; i < banners.length; i++) {
          debugPrint('배너[$i] 제목: ${banners[i].title}');
        }

        return _buildCarousel(context, ref, banners);
      },
      loading: () {
        debugPrint('BannerCarousel: 로딩 중...');
        return SizedBox(
          height: widget.height,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
        );
      },
      error: (error, stack) {
        debugPrint('BannerCarousel 오류: $error');
        return const SizedBox.shrink(); // 오류 시 표시하지 않음
      },
    );
  }

  // 표시할 배너가 없을 때 보여줄 뷰
  Widget _buildNoBannersView(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            '현재 공지사항이 없습니다',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('닫기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(
    BuildContext context,
    WidgetRef ref,
    List<app_banner.Banner> banners,
  ) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];
                // BannerWidget에 인덱스 정보 전달
                return BannerWidget(
                  banner: banner,
                  onDismiss: () {
                    // 마지막 배너를 닫은 경우 모달 자체를 닫음
                    if (banners.length <= 1) {
                      Navigator.of(context).pop();
                    } else {
                      ref
                          .read(bannerProvider.notifier)
                          .dismissBanner(banner.id);
                    }
                  },
                  // 인덱스 정보 추가
                  currentIndex: index + 1,
                  totalCount: banners.length,
                );
              },
            ),
          ),

          // 하단 표시자 (현재 페이지 표시)
          if (widget.showIndicator && banners.length > 1)
            _buildPageIndicator(banners.length),

          // 하단 컨트롤 (닫기/다시보지않기)
          _buildBottomControls(context, ref, banners),
        ],
      ),
    );
  }

  // 페이지 인디케이터 위젯
  Widget _buildPageIndicator(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  index == _currentPage
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }

  // 하단 컨트롤 버튼 (닫기/다시보지않기)
  Widget _buildBottomControls(
    BuildContext context,
    WidgetRef ref,
    List<app_banner.Banner> banners,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 닫기 버튼
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('닫기'),
            ),
          ),
          const SizedBox(width: 12),

          // 다시보지않기 버튼
          // Expanded(
          //   child: OutlinedButton(
          //     onPressed: () {
          //       final banner = banners[_currentPage];
          //       ref
          //           .read(bannerProvider.notifier)
          //           .setDoNotShowAgain(banner.id, true);
          //       Navigator.of(context).pop();
          //     },
          //     style: OutlinedButton.styleFrom(
          //       foregroundColor: Colors.black87,
          //       side: BorderSide(color: Colors.grey.shade300),
          //       padding: const EdgeInsets.symmetric(vertical: 12),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //     ),
          //     child: const Text('다시 보지 않기'),
          //   ),
          // ),
        ],
      ),
    );
  }
}
