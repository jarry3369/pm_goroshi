import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String? status;
  final bool processed;

  const StatusBadge({
    super.key,
    this.status,
    this.processed = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status, processed);
    
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

  StatusInfo _getStatusInfo(String? status, bool processed) {
    switch (status) {
      case 'pending':
        return const StatusInfo(
          text: '대기 중',
          color: Colors.grey,
          icon: Icons.schedule,
        );
      case 'waiting_code':
        return const StatusInfo(
          text: 'SMS 대기',
          color: Colors.orange,
          icon: Icons.sms,
        );
      case 'ready':
        return const StatusInfo(
          text: '제출 준비',
          color: Colors.blue,
          icon: Icons.send,
        );
      case 'submitted':
        return const StatusInfo(
          text: '제출 완료',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case 'failed':
        return const StatusInfo(
          text: '제출 실패',
          color: Colors.red,
          icon: Icons.error,
        );
      default:
        // processed 필드를 기반으로 기본 상태 결정
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
