import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pmgoroshi/presentation/controllers/report_provider.dart';
import 'package:pmgoroshi/presentation/widgets/status_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class MyReportsPage extends ConsumerStatefulWidget {
  const MyReportsPage({super.key});

  @override
  ConsumerState<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends ConsumerState<MyReportsPage> {
  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 개인 신고 내역 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myReportDataNotifierProvider.notifier).refreshMyReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(myReportDataNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 신고'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(myReportDataNotifierProvider.notifier).refreshMyReports();
            },
          ),
        ],
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return _buildEmptyState();
          }
          return _buildReportsList(reports);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 신고 내역이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 신고를 시작해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        //   const SizedBox(height: 24),
        //   ElevatedButton.icon(
        //     onPressed: () {
        //       context.go('/scan');
        //     },
        //     icon: const Icon(Icons.qr_code_scanner),
        //     label: const Text('QR 스캔하기'),
        //   ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text('데이터 로드 중 오류 발생'),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(myReportDataNotifierProvider.notifier).refreshMyReports();
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(List<ReportData> reports) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myReportDataNotifierProvider.notifier).refreshMyReports();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(ReportData report) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/my-reports/${report.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 상태 뱃지와 날짜
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(
                    status: report.status,
                    processed: report.processed,
                  ),
                  Text(
                    dateFormat.format(report.reportedAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 위치 정보
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.address,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 신고 내용 요약
              if (report.description != null && report.description!.isNotEmpty)
                Text(
                  report.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),

              // 이미지 썸네일
              if (report.imageUrls.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: report.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: report.imageUrls[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // 접수 번호 표시 (있는 경우)
              if (report.reportId != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '접수번호: ${report.reportId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
