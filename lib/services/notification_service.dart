import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Top-level background handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: the notification is displayed by the system tray automatically
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _initialized = false;

  /// Call once after Firebase.initializeApp()
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Request permission (required on Android 13+ and iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Initialize local notifications for foreground display
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'bivfarm_notifications',
      'BFarm Notifications',
      description: 'Notifications for bids, orders, and messages',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Store the FCM token for the given user in Firestore
  Future<void> storeToken(String userId) async {
    if (kIsWeb) return;
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(userId).update({'fcmToken': token});
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _db.collection('users').doc(userId).update({'fcmToken': newToken});
      });
    } catch (e) {
      print('FCM Token Error: $e');
    }
  }

  /// Display a local notification when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'bivfarm_notifications',
          'BFarm Notifications',
          channelDescription: 'Notifications for bids, orders, and messages',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Can navigate to specific screens based on message.data
    // For now, the app opens and user sees the notifications tab
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle local notification tap
  }
}
