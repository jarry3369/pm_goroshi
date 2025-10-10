class StatusHelper {
  /// 상태 코드를 한글 메시지로 변환
  static String getStatusMessage(String? status) {
    switch (status) {
      case 'pending':
        return '신고가 접수되었습니다';
      case 'waiting_code':
        return 'SMS 인증 대기 중입니다';
      case 'ready':
        return '안전신문고 제출 준비 중입니다';
      case 'submitted':
        return '안전신문고에 제출되었습니다';
      case 'failed':
        return '제출에 실패했습니다';
      default:
        return '처리 상태를 확인할 수 없습니다';
    }
  }

  /// 상태별 상세 설명 텍스트
  static String getStatusDescription(String? status) {
    switch (status) {
      case 'pending':
        return '신고가 정상적으로 접수되었습니다. 처리 과정을 진행합니다.';
      case 'waiting_code':
        return 'SMS 인증을 통해 신고를 안전신문고에 제출하기 위한 절차를 진행 중입니다.';
      case 'ready':
        return '모든 준비가 완료되었습니다. 곧 안전신문고에 제출됩니다.';
      case 'submitted':
        return '신고가 안전신문고에 성공적으로 제출되었습니다. 접수번호를 확인하실 수 있습니다.';
      case 'failed':
        return '안전신문고 제출 중 오류가 발생했습니다. 다시 시도해주세요.';
      default:
        return '처리 상태를 확인할 수 없습니다.';
    }
  }

  /// 상태별 진행 단계 번호 (타임라인용)
  static int getStatusStep(String? status) {
    switch (status) {
      case 'pending':
        return 1;
      case 'waiting_code':
        return 2;
      case 'ready':
        return 3;
      case 'submitted':
        return 4;
      case 'failed':
        return 4; // 실패도 마지막 단계로 간주
      default:
        return 0;
    }
  }

  /// 전체 단계 수
  static int getTotalSteps() {
    return 4;
  }

  /// 상태가 완료 상태인지 확인
  static bool isCompleted(String? status) {
    return status == 'submitted';
  }

  /// 상태가 실패 상태인지 확인
  static bool isFailed(String? status) {
    return status == 'failed';
  }

  /// 상태가 진행 중인지 확인
  static bool isInProgress(String? status) {
    return status == 'pending' || status == 'waiting_code' || status == 'ready';
  }
}
