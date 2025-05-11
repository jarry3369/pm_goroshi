import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pmgoroshi/data/services/supabase_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

part 'report_provider.g.dart';

// 신고 데이터 모델
class ReportData {
  final String id;
  final List<String> imageUrls;
  final double latitude;
  final double longitude;
  final DateTime reportedAt;
  final String address;
  final String? description;
  final bool processed;

  ReportData({
    required this.id,
    required this.imageUrls,
    required this.latitude,
    required this.longitude,
    required this.reportedAt,
    required this.address,
    this.description,
    this.processed = false,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      id: json['id'] as String,
      imageUrls:
          (json['image_urls'] as List<dynamic>)
              .map((url) => url as String)
              .toList(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      reportedAt: DateTime.parse(json['reported_at'] as String),
      address: json['address'] as String? ?? '주소 정보 없음',
      description: json['description'] as String?,
      processed: json['processed'] as bool? ?? false,
    );
  }
}

@riverpod
class ReportDataNotifier extends _$ReportDataNotifier {
  @override
  FutureOr<List<ReportData>> build() async {
    return _fetchReports();
  }

  Future<List<ReportData>> _fetchReports() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('reports')
          .select()
          .order('timestamp', ascending: false);

      return response
          .map<ReportData?>((data) {
            try {
              final Map<String, dynamic> content =
                  data['content'] is String
                      ? jsonDecode(data['content'] as String)
                      : data['content'] as Map<String, dynamic>;

              final DateTime timestamp = DateTime.parse(
                data['timestamp'] as String,
              );

              // 이미지 URL 리스트 추출
              List<String> imageUrls = [];
              if (content['image_urls'] is List) {
                imageUrls =
                    (content['image_urls'] as List)
                        .map((url) => url.toString())
                        .toList();
              } else if (content['image_urls'] is String &&
                  content['image_urls'].isNotEmpty) {
                imageUrls = [content['image_urls'] as String];
              }

              return ReportData(
                id: data['report_id'] as String? ?? data['id'] as String,
                imageUrls: imageUrls.isNotEmpty ? imageUrls : [''],
                latitude: (content['latitude'] as num?)?.toDouble() ?? 37.5666,
                longitude:
                    (content['longitude'] as num?)?.toDouble() ?? 126.9784,
                reportedAt:
                    content['submission_time'] != null
                        ? DateTime.parse(content['submission_time'] as String)
                        : timestamp,
                address: content['location'] as String? ?? '위치 정보 없음',
                description: content['description'] as String?,
                processed: data['processed'] as bool? ?? false,
              );
            } catch (e) {
              // 데이터 변환 오류 발생 시 null 반환 (리스트에서 제외)
              print('데이터 파싱 오류: $e, 데이터: \\${data['id']}');
              return null;
            }
          })
          .whereType<ReportData>()
          .toList();
    } catch (e) {
      // 오류 발생 시 빈 배열 반환
      print('신고 내역 로드 중 오류 발생: $e');
      return [];
    }
  }

  // 데이터 새로고침
  Future<void> refreshReports() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchReports());
  }
}

// 현재 선택된 마커 ID를 관리하는 프로바이더
@riverpod
class SelectedReportProvider extends _$SelectedReportProvider {
  @override
  String? build() {
    return null;
  }

  void selectReport(String id) {
    state = id;
  }

  void clearSelection() {
    state = null;
  }
}
