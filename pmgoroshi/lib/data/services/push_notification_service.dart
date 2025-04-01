import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pmgoroshi/data/services/supabase_service.dart';
import 'package:pmgoroshi/firebase_options.dart';

// 백그라운드 메시지 핸들러 (반드시 최상위 함수로 정의)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('백그라운드 메시지 처리: ${message.messageId}');
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return PushNotificationService(supabaseService);
});

class PushNotificationService {
  final SupabaseService _supabaseService;
  late final FirebaseMessaging _messaging;
  late final FlutterLocalNotificationsPlugin _localNotifications;

  PushNotificationService(this._supabaseService) {
    _init();
  }

  Future<void> _init() async {
    try {
      // 이미 Firebase가 main.dart에서 초기화되었으므로 여기서 다시 초기화하지 않음
      // Firebase.initializeApp() 호출 제거

      debugPrint('푸시 알림 서비스 초기화 시작 - ${DateTime.now()}');
      _messaging = FirebaseMessaging.instance;

      // 로컬 알림 설정
      _localNotifications = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true,
          );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      // 권한 요청
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('사용자 푸시 알림 허용 상태: ${settings.authorizationStatus}');

      // 토큰 가져오기 및 저장
      await _updateToken();

      // 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen(_saveToken);

      // 포그라운드 메시지 핸들러
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 백그라운드 메시지 핸들러 설정
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 알림 클릭 처리
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

      debugPrint('푸시 알림 서비스 초기화 완료 - ${DateTime.now()}');
    } catch (e, stack) {
      debugPrint('푸시 알림 초기화 오류: $e');
      debugPrint('스택 트레이스: $stack');
    }
  }

  Future<void> _updateToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint(
        'FCM 토큰 요청 결과: ${token != null ? '토큰 있음(${token.substring(0, 10)}...)' : 'null'}',
      );

      if (token != null) {
        await _saveToken(token);
      } else {
        debugPrint('FCM 토큰이 null입니다. 기기 정보가 저장되지 않을 수 있습니다.');
      }
    } catch (e, stack) {
      debugPrint('토큰 업데이트 오류: $e');
      debugPrint('스택 트레이스: $stack');
    }
  }

  Future<void> _saveToken(String token) async {
    debugPrint('FCM 토큰 저장 시작: ${token.substring(0, 10)}...');

    try {
      // 토큰을 Supabase에 저장
      await _supabaseService.updateDeviceToken(token);
      debugPrint('FCM 토큰 저장 완료');
    } catch (e, stack) {
      debugPrint('FCM 토큰 저장 오류: $e');
      debugPrint('스택 트레이스: $stack');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('포그라운드 메시지 수신: ${message.notification?.title}');

    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            '중요 알림',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['route'],
      );
    }
  }

  void _handleMessageOpened(RemoteMessage message) {
    debugPrint('알림 클릭: ${message.data}');
    // 알림 클릭 시 특정 화면으로 라우팅 처리
    final route = message.data['route'];
    if (route != null) {
      // 라우팅 처리 로직
    }
  }
}
