import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';
import 'package:pmgoroshi/domain/entities/banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// SupabaseService의 Provider 선언
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final String _bucketName = 'pmgoroshi-report-pic';
  final String _tableName = 'reports';
  final String _companyMappingTable = 'companies';
  final String _bannerTable = 'banners';

  Future<Map<String, dynamic>> getCompanyMapping() async {
    try {
      final response = await _client.from(_companyMappingTable).select();

      final Map<String, dynamic> companyMap = {};
      for (final item in response) {
        final url = item['id'] as String?;
        final name = item['name'] as String?;
        final qk = item['qk'] as String?;

        if (url != null && name != null) {
          companyMap[url] = {'name': name, 'qk': qk};
        }
      }

      return companyMap;
    } catch (e) {
      debugPrint('업체 매핑 데이터 가져오기 오류: $e');
      // 에러 발생 시 빈 맵 반환
      return {};
    }
  }

  /// 이미지를 압축하고 Supabase Storage에 업로드한 후 URL을 반환
  Future<List<String>> uploadImages(List<String> imagePaths) async {
    List<String> uploadedUrls = [];

    try {
      // 버킷이 존재하는지 확인하고 없으면 생성
      await _ensureBucketExists();

      for (String imagePath in imagePaths) {
        // 이미지 파일 읽기
        final file = File(imagePath);

        // 이미지 압축
        final tempDir = Directory.systemTemp;
        final String targetPath = path.join(
          tempDir.path,
          '${const Uuid().v4()}.jpg',
        );

        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 70,
          minWidth: 1024,
          minHeight: 1024,
        );

        if (compressedFile == null) continue;

        // 파일명 생성 (UUID 사용)
        final uuid = const Uuid().v4();
        final fileExt = path.extension(imagePath);
        final fileName = '$uuid$fileExt';

        // 압축된 파일 읽기
        final compressedBytes = await File(compressedFile.path).readAsBytes();

        // Supabase Storage에 업로드
        await _client.storage
            .from(_bucketName)
            .uploadBinary(fileName, compressedBytes);

        // 업로드 성공 시 공개 URL 가져오기
        final publicUrl = _client.storage
            .from(_bucketName)
            .getPublicUrl(fileName);

        uploadedUrls.add(publicUrl);

        // 임시 압축 파일 삭제
        final tempFile = File(compressedFile.path);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      return uploadedUrls;
    } catch (e) {
      debugPrint('업로드 오류: $e');
      throw Exception('이미지 업로드 중 오류가 발생했습니다: $e');
    }
  }

  /// Supabase Storage 버킷이 존재하는지 확인하고 없으면 생성
  Future<void> _ensureBucketExists() async {
    try {
      // 버킷 목록 가져오기
      final buckets = await _client.storage.listBuckets();

      // 지정된 이름의 버킷이 있는지 확인
      final bucketExists = buckets.any((bucket) => bucket.name == _bucketName);

      // 버킷이 없으면 생성
      if (!bucketExists) {
        await _client.storage.createBucket(
          _bucketName,
          const BucketOptions(
            public: true, // 공개 버킷으로 설정
            fileSizeLimit: '50MB', // 최대 파일 크기
          ),
        );
      }
    } catch (e) {
      debugPrint('버킷 생성 오류: $e');
    }
  }

  /// 현재 활성화된 배너 목록 가져오기
  Future<List<Banner>> getActiveBanners() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      debugPrint('============= 배너 조회 시작 [${DateTime.now()}] =============');
      debugPrint('현재 시간(UTC ISO): $now');

      // 디버깅을 위해 모든 배너 먼저 조회
      final allBanners = await _client.from(_bannerTable).select();

      // 전체 배너 로그 출력
      debugPrint('전체 배너 수: ${allBanners.length}');
      if (allBanners.isNotEmpty) {
        for (int i = 0; i < allBanners.length; i++) {
          final banner = allBanners[i];
          debugPrint('배너[$i] 전체 데이터: $banner');
          debugPrint('배너[$i] ID: ${banner['id']}, 타이틀: ${banner['title']}');
          debugPrint('배너[$i] 활성화 상태: ${banner['is_active']}');
          debugPrint(
            '배너[$i] 시작일: ${banner['start_date']}, 종료일: ${banner['end_date']}',
          );
        }
      } else {
        debugPrint('배너가 존재하지 않습니다. 테이블을 확인하세요.');
      }

      // 필터를 적용한 Supabase 쿼리 실행
      debugPrint('필터링된 쿼리로 배너 조회...');
      final response = await _client
          .from(_bannerTable)
          .select()
          .eq('is_active', true)
          .lte('start_date', now);

      // 종료일 필터링은 클라이언트에서 수행
      final filteredBanners =
          response.where((item) {
            try {
              if (item['end_date'] != null) {
                final endDate = DateTime.parse(item['end_date']);
                return endDate.isAfter(DateTime.now().toUtc()) ||
                    endDate.isAtSameMomentAs(DateTime.now().toUtc());
              }
              return true; // 종료일이 없으면 항상 유효
            } catch (e) {
              debugPrint('배너 종료일 파싱 오류: $e, 데이터: ${item['end_date']}');
              return false;
            }
          }).toList();

      debugPrint('최종 필터링된 배너 수: ${filteredBanners.length}');

      // 각 배너 항목의 필드를 디버그 출력
      for (var item in filteredBanners) {
        debugPrint('\n--- 배너 JSON 데이터 ---');
        item.forEach((key, value) {
          debugPrint('$key: $value (${value?.runtimeType})');
        });
      }

      // 각 배너 항목을 Banner 객체로 변환하고 날짜 필드 처리
      final List<Banner> result = [];
      for (var item in filteredBanners) {
        try {
          // 날짜 필드 파싱 개선
          DateTime? startDate;
          DateTime? endDate;
          DateTime timestamp;

          try {
            if (item['start_date'] != null) {
              startDate = DateTime.parse(item['start_date']);
            }
          } catch (e) {
            debugPrint('시작일 파싱 오류: ${item['start_date']}, $e');
          }

          try {
            if (item['end_date'] != null) {
              endDate = DateTime.parse(item['end_date']);
            }
          } catch (e) {
            debugPrint('종료일 파싱 오류: ${item['end_date']}, $e');
          }

          try {
            if (item['timestamp'] != null) {
              timestamp = DateTime.parse(item['timestamp']);
            } else {
              timestamp = DateTime.now(); // 기본값
            }
          } catch (e) {
            debugPrint('타임스탬프 파싱 오류: ${item['timestamp']}, $e');
            timestamp = DateTime.now(); // 오류 시 현재 시간으로
          }

          // 필수 필드 확인
          if (item['id'] == null ||
              item['title'] == null ||
              startDate == null) {
            debugPrint(
              '필수 필드 누락: id=${item['id']}, title=${item['title']}, start_date=$startDate',
            );
            continue;
          }

          // 표준화된 JSON 데이터로 변환
          final Map<String, dynamic> standardJson = {
            'id': item['id'],
            'title': item['title'],
            'content': item['content'] ?? '',
            'image_url': item['image_url'],
            'is_active': item['is_active'] ?? true,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
            'priority': item['priority'] ?? 0,
            'action_url': item['action_url'],
            'action_type': item['action_type'],
            'timestamp': timestamp.toIso8601String(),
          };

          debugPrint('표준화된 JSON: $standardJson');
          final banner = Banner.fromJson(standardJson);
          result.add(banner);
        } catch (e) {
          debugPrint('배너 변환 오류: $e');
        }
      }

      debugPrint('배너 변환 후 결과 수: ${result.length}');

      debugPrint('============= 배너 조회 완료 =============');
      return result;
    } catch (e) {
      debugPrint('활성 배너 가져오기 오류: $e');
      debugPrint('스택 트레이스: ${StackTrace.current}');
      return [];
    }
  }

  /// 특정 배너 가져오기
  Future<Banner?> getBannerById(String id) async {
    try {
      final response =
          await _client.from(_bannerTable).select().eq('id', id).single();

      return Banner.fromJson(response);
    } catch (e) {
      debugPrint('배너 가져오기 오류: $e');
      return null;
    }
  }

  // 디바이스 토큰 업데이트 메소드 추가
  Future<void> updateDeviceToken(String token) async {
    try {
      // final user = _client.auth.currentUser;
      // if (user != null) {
      //   // 사용자 정보 테이블에 디바이스 토큰 업데이트
      //   await _client.from('user_devices').upsert({
      //     'user_id': user.id,
      //     'device_token': token,
      //     'platform': Platform.isAndroid ? 'android' : 'ios',
      //     'last_updated': DateTime.now().toIso8601String(),
      //   }, onConflict: 'user_id, device_token');
      //   debugPrint('디바이스 토큰 업데이트 완료');
      // } else {
      // 비로그인 상태에서는 임시 사용자 식별자 생성 및 저장
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? const Uuid().v4();
      await prefs.setString('device_id', deviceId);

      await _client.from('anonymous_devices').upsert({
        'device_id': deviceId,
        'device_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'last_updated': DateTime.now().toIso8601String(),
      }, onConflict: 'device_id');
      debugPrint('디바이스 토큰 업데이트 완료');
      // }
    } catch (e) {
      debugPrint('디바이스 토큰 업데이트 오류: $e');
    }
  }

  // 리포트 저장 시 디바이스 정보 포함
  Future<void> saveReportData(SubmissionData data) async {
    try {
      // 디바이스 토큰 가져오기
      final token = await FirebaseMessaging.instance.getToken();
      final deviceId = await _getDeviceId();

      // 데이터베이스에 저장
      await _client.from(_tableName).insert({
        'content': {
          'qr_data': data.qrData,
          'description': data.description,
          'image_urls': data.imagePaths,
          'submission_time': data.submissionTime.toIso8601String(),
          'location': data.location,
          'latitude': data.latitude,
          'longitude': data.longitude,
          'company_name': data.companyName,
          'serial_number': data.serialNumber,
          'violation_type': data.violationType.toJson(),
        },
        'type': data.violationType.id,
        'device_token': token,
        'device_id': deviceId,
        'device_platform': Platform.isAndroid ? 'android' : 'ios',
      });
    } catch (e) {
      debugPrint('데이터 저장 오류: $e');
      throw Exception('데이터 저장 중 오류가 발생했습니다: $e');
    }
  }

  // 디바이스 ID 가져오기
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id');
    if (deviceId != null) return deviceId;

    final newDeviceId = const Uuid().v4();
    await prefs.setString('device_id', newDeviceId);
    return newDeviceId;
  }

  // 개인 신고 내역 조회
  Future<List<Map<String, dynamic>>> getMyReports(String deviceId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('device_id', deviceId)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('개인 신고 내역 조회 오류: $e');
      throw Exception('개인 신고 내역 조회 중 오류가 발생했습니다: $e');
    }
  }
}
