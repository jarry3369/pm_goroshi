import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pmgoroshi/data/services/supabase_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'report_provider.g.dart';

// 신고 데이터 모델
class ReportData {
  final String id;
  final String title;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final DateTime reportedAt;
  final String address;
  final String? description;

  ReportData({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.reportedAt,
    required this.address,
    this.description,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      id: json['id'] as String,
      title: json['title'] as String? ?? '킥보드 신고',
      imageUrl: json['image_url'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      reportedAt: DateTime.parse(json['reported_at'] as String),
      address: json['address'] as String? ?? '주소 정보 없음',
      description: json['description'] as String?,
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
          .from('submissions')
          .select()
          .order('reported_at', ascending: false);

      return response
          .map<ReportData>((data) => ReportData.fromJson(data))
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
