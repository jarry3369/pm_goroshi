# 클린로드

[![Google Play Store](https://img.shields.io/badge/Google%20Play-클린로드-414141?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.minestroneteam.pmgoroshi)   
방치된 공유 킥보드, 자전거 간단 신고

## 📱 프로젝트 소개

클린로드는 공유 모빌리티의 불법 주차 및 방치 문제를 해결하고, 깨끗하고 안전한 도시 환경 조성에 기여하기 위해 개발된 모바일 애플리케이션입니다. 기존의 복잡하고 분산된 신고 시스템을 안전신문고를 통한 통합으로, 사진과 위치 정보를 첨부해 불법 주차된 공유 모빌리티를 간편하게 신고할 수 있습니다.

**"당신이 움직이면, 도시도 깨끗해집니다!"**

## 📱 앱 스크린샷

<div align="center">
  <img src="https://play-lh.googleusercontent.com/e4cKKJnoDn4cx_fX-I8u9Qm24T0bIasfhztejbChiyDC90oma_0OH5NnfAzsh5U0aQ=w5120-h2880-rw" width="200" alt="QR 코드 스캔"/>
  <img src="https://play-lh.googleusercontent.com/1s9jvkjlIF81E6SLGy2HkmBzpeEkHt2cyMmvF2Zgs55fR_tMTwd9NYVtwmt709a8Qw=w5120-h2880-rw" width="200" alt="데이터 입력1"/>
  <img src="https://play-lh.googleusercontent.com/XHgO85Z3lEmLEfEXo6MQqOk2vm8Dq5HE8X8VHZBEfZ9nRB5PWUEyhW8JRHu2r2KKvYjp=w5120-h2880-rw" width="200" alt="데이터 입력2 / 사진 첨부"/>
  <img src="https://play-lh.googleusercontent.com/Bbllmwtg6mBR7OAsQ0V-EdMof4qvr5V9H-7bb06KJx1OtOi_RUZtbfu23QxF1Y-vf-SQ=w5120-h2880-rw" width="200" alt="신고 내역"/>
</div>

<p align="center">
  <em>QR 스캔 → 데이터 입력 → 사진 첨부 → 지도 보기 → 신고 내역</em>
</p>

## ✨ 주요 기능

- **간편한 신고**: 기존의 복잡하고 신고 시스템을 대신, QR스캔 후 사진만 찍어 간편하게 신고
- **위치 정보**: GPS 기반의 위치 정보를 제공하여 빠른 신고를 지원
- **QR 코드 스캔**: 킥보드의 QR 코드를 스캔하여 기기 정보 자동 입력
- **사진 첨부**: 불법 주차 현장 사진 첨부 기능 (최대 4장)
- **신고 유형 선택**: 다양한 불법 주차 유형 분류 (보도, 자전거도로, 횡단보도 등)
- **신고 내역 조회**: 과거 신고 기록 확인
- **푸시 알림**: 신고 처리 상태 실시간 알림
- **킥보드, 자전거 등 공유 모빌리티 통합 지원**

## 🛠 기술 스택

### Frontend (Flutter)
- **Framework**: Flutter 3.7.0+
- **상태 관리**: Riverpod
- **라우팅**: GoRouter
- **UI/UX**: Material Design 3

### 주요 패키지
- `mobile_scanner`: QR 코드 스캔
- `flutter_naver_map`: 네이버 지도 연동
- `geolocator`: 위치 서비스
- `image_picker`: 사진 촬영/선택
- `firebase_messaging`: 푸시 알림
- `supabase_flutter`: 백엔드 서비스

### Backend
- **Database**: Supabase (PostgreSQL)
- **Storage**: Supabase Storage
- **Functions**: Supabase Edge Functions
- **Push Notifications**: Firebase Cloud Messaging

## 📱 앱 구조

```
lib/
├── core/           # 권한 관리, 테마 등 핵심 기능
├── data/           # 서비스 레이어 (API, 로컬 데이터)
├── domain/         # 엔티티 및 도메인 로직
└── presentation/   # UI 레이어
    ├── controllers/
    ├── pages/
    ├── routes/
    └── widgets/
```
## 📄 버전

현재 버전: **0.1.3+4**

---

_당신이 움직이면, 도시도 깨끗해집니다!_
