import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String? status;
  final bool processed;
  final String? reportId;

  const StatusBadge({
    super.key,
    this.status,
    this.processed = false,
    this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status, processed, reportId);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            statusInfo.text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  StatusInfo _getStatusInfo(String? status, bool processed, String? reportId) {
    // pending, waiting_code, ready → "접수됨"
    if (status == 'pending' || status == 'waiting_code' || status == 'ready') {
      return const StatusInfo(
        text: '접수됨',
        color: Colors.blue,
        icon: Icons.inbox,
      );
    }

    // failed → "제출 실패" (기존 유지)
    if (status == 'failed') {
      return const StatusInfo(
        text: '제출 실패',
        color: Colors.red,
        icon: Icons.error,
      );
    }

    // submitted → report_id 상태에 따라 세분화
    if (status == 'submitted') {
      if (reportId == null) {
        // report_id가 없으면 "제출완료"
        return const StatusInfo(
          text: '제출완료',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      } else if (processed) {
        // report_id가 있고 processed가 true면 "처리완료"
        return const StatusInfo(
          text: '처리완료',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      } else {
        // report_id가 있고 processed가 false면 "진행중"
        return const StatusInfo(
          text: '진행중',
          color: Colors.orange,
          icon: Icons.sync,
        );
      }
    }

    // default: processed 필드를 기반으로 기본 상태 결정
    if (processed) {
      return const StatusInfo(
        text: '처리완료',
        color: Colors.green,
        icon: Icons.check_circle,
      );
    } else {
      return const StatusInfo(
        text: '미처리',
        color: Colors.red,
        icon: Icons.warning,
      );
    }
  }
}

class StatusInfo {
  final String text;
  final Color color;
  final IconData icon;

  const StatusInfo({
    required this.text,
    required this.color,
    required this.icon,
  });
}
