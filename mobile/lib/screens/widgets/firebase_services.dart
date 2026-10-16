import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/model/Project/all_project.dart';
import '../../routes/routes.dart';
import 'package:logger/logger.dart';

final logger = Logger();

Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    logger.d("📥 Background FCM received: ${message.messageId}");
  }
}

class NotificationService {
  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initFirebaseMessaging(BuildContext context) async {
    if (Firebase.apps.isEmpty) return;
    await _requestNotificationPermissions();
    await _getAPNSToken();
    String? fcmToken = await _firebaseMessaging.getToken();

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    // App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    // App opened from terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }

    // Token refresh
    _firebaseMessaging.onTokenRefresh.listen((String newToken) {});

    await _initLocalNotificationPlugin();
  }

  Future<void> _getAPNSToken() async {
    if (Platform.isIOS) {
      try {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
      } catch (e) {
        if (kDebugMode) {
          logger.d("❌ Error getting APNS token: $e");
        }
      }
    }
  }

  Future<void> _initLocalNotificationPlugin() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNotificationTap(data);
          } catch (e) {
            if (kDebugMode) {
              logger.d('❌ Error parsing notification payload: $e');
            }
          }
        }
      },
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'ibex_channel',
          'ibex Notifications',
          description: 'Notifications for ibex app',
          importance: Importance.max,
        ),
      );
    }
  }

  Future<void> _requestNotificationPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    logger.d(
        '📋 Notification permission status: ${settings.authorizationStatus}');

    if (Platform.isIOS) {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void setupFirebaseMessaging() async {
    if (Firebase.apps.isEmpty) return;
    await _firebaseMessaging.requestPermission();
    if (Platform.isIOS) {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });
  }

  void _showForegroundNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'ibex_channel',
      'ibex Notifications',
      channelDescription: 'Notifications for ibex app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      actions: [
        AndroidNotificationAction(
          'DECLINE_ACTION',
          'Decline',
          cancelNotification: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode(message.data);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'ibex',
      message.notification?.body ?? '',
      notificationDetails,
      payload: payload,
    );
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    try {
      // Parse data['item'] if it exists
      Map<String, dynamic> payload = {};
      if (data.containsKey('item')) {
        if (data['item'] is String) {
          payload = jsonDecode(data['item']);
        } else if (data['item'] is Map<String, dynamic>) {
          payload = data['item'];
        } else {
          router.push('/notifications', extra: {'fromNoti': true});
          return;
        }
      } else {
        router.push('/notifications', extra: {'fromNoti': true});
        return;
      }

      // Extract type from the parsed payload
      final String? type = payload['type'];
      if (type == null) {
        router.push('/notifications', extra: {'fromNoti': true});
        return;
      }

      // Extract nested item for project/task details
      Map<String, dynamic> item = payload['item'] is Map<String, dynamic>
          ? payload['item']
          : (payload['item'] is String ? jsonDecode(payload['item']) : {});

      switch (type) {
        case "project":
          if (item['id'] != null) {
            router.push(
              '/projectdetails',
              extra: {
                "id": item['id'], // Convert to string to handle int
                "fromNoti": true,
                "projectModel": ProjectModel.empty(),
              },
            );
          } else {
            router.push('/notifications', extra: {'fromNoti': true});
          }
          break;
        case "task":
          if (item['id'] != null) {
            router.push(
              '/taskdetail',
              extra: {
                "id": item['id'], // Convert to string to handle int
                "fromNoti": true,
              },
            );
          } else {
            router.push('/notifications', extra: {'fromNoti': true});
          }
          break;
        case "meeting":
          router.push('/meetings', extra: {"fromNoti": true});
          break;
        case "leave_request":
          router.push('/leaverequest', extra: {"fromNoti": true});
          break;
        case "workspace":
          router.push('/workspaces', extra: {"fromNoti": true});
          break;
        default:
          router.push('/notifications', extra: {'fromNoti': true});
      }
    } catch (e) {
      //debugPrint('❌ Error handling notification tap: $e');
      router.push('/notifications', extra: {'fromNoti': true});
    }
  }

  static void handleNavigation(Map<String, dynamic> payload) {
    _handleNotificationTap(payload);
  }
}
