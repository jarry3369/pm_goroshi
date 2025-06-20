import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pmgoroshi/data/services/supabase_service.dart';
import 'package:pmgoroshi/domain/entities/banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// 배너 상태를 위한 provider
final bannerProvider =
    StateNotifierProvider<BannerNotifier, AsyncValue<List<Banner>>>((ref) {
      final supabaseService = ref.watch(supabaseServiceProvider);
      return BannerNotifier(supabaseService);
    });

// 읽지 않은 배너 수 계산 provider
final unreadBannerCountProvider = Provider<AsyncValue<int>>((ref) {
  final bannersAsync = ref.watch(bannerProvider);

  return bannersAsync.when(
    data: (banners) {
      final unreadCount = banners.where((banner) => !banner.is_read).length;
      return AsyncValue.data(unreadCount);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// 표시할 수 있는 배너 provider (다시 보지 않기가 설정되지 않은 배너만)
final displayableBannersProvider = Provider<AsyncValue<List<Banner>>>((ref) {
  final bannersAsync = ref.watch(bannerProvider);

  return bannersAsync.when(
    data: (banners) {
      final displayable =
          banners.where((banner) => !banner.do_not_show_again).toList();
      return AsyncValue.data(displayable);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// 배너 상태 관리를 위한 StateNotifier
class BannerNotifier extends StateNotifier<AsyncValue<List<Banner>>> {
  final SupabaseService _supabaseService;

  BannerNotifier(this._supabaseService) : super(const AsyncValue.loading()) {
    loadBanners();
  }

  Future<void> loadBanners() async {
    try {
      debugPrint('BannerNotifier.loadBanners() 시작');
      state = const AsyncValue.loading();
      final banners = await _supabaseService.getActiveBanners();

      debugPrint('BannerNotifier: 서버에서 배너 ${banners.length}개 로드됨');

      // SharedPreferences에서 설정 불러오기
      final prefs = await SharedPreferences.getInstance();

      // 설정 불러와서 적용
      final updatedBanners = await Future.wait(
        banners.map((banner) async {
          final isRead = prefs.getBool('banner_read_${banner.id}') ?? false;
          final doNotShowAgain =
              prefs.getBool('banner_doNotShowAgain_${banner.id}') ?? false;

          debugPrint('배너 ${banner.id}: 읽음=$isRead, 다시보지않기=$doNotShowAgain');

          // UI 표시를 위한 클라이언트 측 속성 설정
          final bannerType = _getBannerTypeFromContent(
            banner.content,
            banner.image_url,
          );
          final typeLabel = _getTypeLabelFromBannerType(bannerType);
          final buttonText = _getButtonTextFromActionType(banner.action_type);
          final backgroundColor = _getBackgroundColorFromType(bannerType);

          return banner.copyWith(
            is_read: isRead,
            do_not_show_again: doNotShowAgain,
            banner_type: bannerType,
            type_label: typeLabel,
            button_text: buttonText,
            background_color: backgroundColor,
          );
        }),
      );

      debugPrint('BannerNotifier: 최종 ${updatedBanners.length}개 배너 로드 완료');
      // 표시 가능한 배너 수 (다시 보지 않기가 설정되지 않은 배너)
      final displayableBanners =
          updatedBanners.where((b) => !b.do_not_show_again).length;
      debugPrint('BannerNotifier: 표시 가능한 배너 ${displayableBanners}개');

      state = AsyncValue.data(updatedBanners);
      debugPrint('BannerNotifier.loadBanners() 완료');
    } catch (e) {
      debugPrint('BannerNotifier.loadBanners() 오류: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // 컨텐츠와 이미지 URL 기반으로 배너 타입 추론
  BannerType _getBannerTypeFromContent(String content, String? imageUrl) {
    final lowerContent = content.toLowerCase();

    if (lowerContent.contains('동영상') || lowerContent.contains('video')) {
      return BannerType.video;
    } else if (lowerContent.contains('시네마') ||
        lowerContent.contains('cinema')) {
      return BannerType.cinema;
    } else if (imageUrl != null) {
      return BannerType.image;
    }

    return BannerType.basic;
  }

  // 배너 타입에 따른 라벨 생성
  String _getTypeLabelFromBannerType(BannerType type) {
    switch (type) {
      case BannerType.video:
        return '동영상형';
      case BannerType.image:
        return '이미지형';
      case BannerType.cinema:
        return '시네마형';
      case BannerType.basic:
      default:
        return '기본형';
    }
  }

  // 액션 타입에 따른 버튼 텍스트 생성
  String _getButtonTextFromActionType(String? actionType) {
    if (actionType == null) return '확인하기';

    switch (actionType) {
      case 'url':
        return '이동하기';
      case 'route':
        return '이동하기';
      default:
        return '확인하기';
    }
  }

  // 배너 타입에 따른 배경색 생성
  String _getBackgroundColorFromType(BannerType type) {
    switch (type) {
      case BannerType.video:
        return '#5E35B1';
      case BannerType.image:
        return '#4527A0';
      case BannerType.cinema:
        return '#1A1A1A';
      case BannerType.basic:
      default:
        return '#3949AB';
    }
  }

  Future<void> markBannerAsRead(String bannerId) async {
    state.whenData((banners) async {
      final updatedBanners =
          banners.map((banner) {
            if (banner.id == bannerId) {
              return banner.copyWith(is_read: true);
            }
            return banner;
          }).toList();

      state = AsyncValue.data(updatedBanners);

      // 설정 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('banner_read_$bannerId', true);
    });
  }

  Future<void> setDoNotShowAgain(String bannerId, bool value) async {
    state.whenData((banners) async {
      final updatedBanners =
          banners.map((banner) {
            if (banner.id == bannerId) {
              return banner.copyWith(do_not_show_again: value);
            }
            return banner;
          }).toList();

      state = AsyncValue.data(updatedBanners);

      // 설정 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('banner_doNotShowAgain_$bannerId', value);
    });
  }

  Future<void> dismissBanner(String bannerId) async {
    state.whenData((banners) {
      final updatedBanners =
          banners.where((banner) => banner.id != bannerId).toList();
      state = AsyncValue.data(updatedBanners);
    });
  }

  Future<void> refreshBanners() async {
    try {
      debugPrint('BannerNotifier.refreshBanners() 시작');

      // 로딩 상태 설정
      state = const AsyncValue.loading();

      // 서버에서 배너 가져오기
      final banners = await _supabaseService.getActiveBanners();
      debugPrint('서버에서 배너 ${banners.length}개 로드됨');

      if (banners.isEmpty) {
        debugPrint('배너가 없습니다. 빈 리스트로 상태 업데이트');
        state = const AsyncValue.data([]);
        return;
      }

      // SharedPreferences에서 설정 불러오기
      final prefs = await SharedPreferences.getInstance();

      // UI 표시에 필요한 추가 속성 설정
      final updatedBanners = await Future.wait(
        banners.map((banner) async {
          // 클라이언트 설정 불러오기
          final isRead = prefs.getBool('banner_read_${banner.id}') ?? false;
          final doNotShowAgain =
              prefs.getBool('banner_doNotShowAgain_${banner.id}') ?? false;

          debugPrint('배너 ${banner.id} 설정: 읽음=$isRead, 다시보지않기=$doNotShowAgain');

          // 컨텐츠 기반으로 배너 타입 추론
          final bannerType = _getBannerTypeFromContent(
            banner.content,
            banner.image_url,
          );

          // 배너 타입에 따른 UI 속성 설정
          final backgroundColor = _getBackgroundColorFromType(bannerType);
          final typeLabel = _getTypeLabelFromBannerType(bannerType);
          final buttonText = _getButtonTextFromActionType(banner.action_type);

          // 최종 배너 객체 생성
          return banner.copyWith(
            is_read: isRead,
            do_not_show_again: doNotShowAgain,
            banner_type: bannerType,
            background_color: backgroundColor,
            type_label: typeLabel,
            button_text: buttonText,
          );
        }),
      );

      debugPrint('BannerNotifier: 최종 ${updatedBanners.length}개 배너 상태 업데이트');

      // 상태 업데이트
      state = AsyncValue.data(updatedBanners);

      // 표시 가능한 배너 수 로깅
      final displayableBanners =
          updatedBanners.where((b) => !b.do_not_show_again).length;
      debugPrint('BannerNotifier: 표시 가능한 배너 ${displayableBanners}개');

      debugPrint('BannerNotifier.refreshBanners() 완료');
    } catch (e, stack) {
      debugPrint('BannerNotifier.refreshBanners() 오류: $e');
      debugPrint('스택 트레이스: $stack');
      state = AsyncValue.error(e, stack);
    }
  }
}
