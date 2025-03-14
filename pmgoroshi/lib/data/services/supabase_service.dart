import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final String _bucketName = 'pmgoroshi-report-pic';
  final String _tableName = 'reports';
  final String _companyMappingTable = 'companies';

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
      debugPrint('회사 매핑 데이터 가져오기 오류: $e');
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

  /// Supabase Database에 데이터 저장
  Future<void> saveReportData(SubmissionData data) async {
    try {
      // 데이터베이스에 저장
      await _client.from(_tableName).insert({
        'content': {
          'qr_data': data.qrData,
          'description': data.description,
          'image_urls': data.imagePaths,
          'submission_time': data.submissionTime.toIso8601String(),
          'location': data.location,
          'company_name': data.companyName,
          'serial_number': data.serialNumber,
          'violation_type': data.violationType.toJson(),
        },
        'type': data.violationType.id,
      });
    } catch (e) {
      debugPrint('데이터 저장 오류: $e');
      throw Exception('데이터 저장 중 오류가 발생했습니다: $e');
    }
  }
}
