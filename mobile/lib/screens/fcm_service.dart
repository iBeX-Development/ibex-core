import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';

final logger = Logger();

Future<String?> getFCMToken() async {
  if (Platform.isIOS) {
    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo;
    if (!iosInfo.isPhysicalDevice) {
      return null;
    }
  }

  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    if (!androidInfo.isPhysicalDevice) {
      return null;
    }
  }

  if (Firebase.apps.isEmpty) return null;
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission (iOS only)
  await messaging.requestPermission();

  // IMPORTANT: For iOS, get APNS token first
  if (Platform.isIOS) {
    try {
      String? apnsToken = await messaging.getAPNSToken();
      if (kDebugMode) {
        logger.d("🍎 APNS Token: $apnsToken");
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error getting APNS token: $e");
      }
      return null;
    }
  }

  // Now get the FCM token
  try {
    final token = await messaging.getToken();
    return token;
  } catch (e) {
    if (kDebugMode) {
      logger.d("❌ Error getting FCM token: $e");
    }
    return null;
  }
}
