import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ibex/data/GlobalVariable/globalvariable.dart';
import '../config/constants.dart';
import '../config/strings.dart';
import '../data/localStorage/hive.dart';
import '../firebase_options.dart';
import '../screens/widgets/firebase_services.dart';
import '../utils/user_id_mapper.dart';
import '../utils/role_id_mapper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

bool isDarkTheme = false;

Future<void> initializeApp() async {
  try {
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      if (kDebugMode) {
        logger.i('Firebase initialized successfully');
      }
    } else {
      logger.i('Firebase integration disabled: client configuration missing');
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      if (kDebugMode) {
        logger.d('⚠️ Firebase already initialized, skipping...');
      }
    } else {
      logger.e('⛔ ❌ Firebase initialization failed: $e');
    }
  }

  // Initialize Hive first
  await Hive.initFlutter();
  GlobalUserData();

  // Open Hive boxes
  await Future.wait([
    Hive.openBox(authBox),
    Hive.openBox(themeBox),
    Hive.openBox(userBox),
    Hive.openBox(headerBox),
    Hive.openBox(permissionsBox),
    Hive.openBox(languageBoxName),
    Hive.openBox(settingsBox),
  ]);

  // Initialize UserIdMapper for UUID to int mapping
  await UserIdMapper().initialize();
  if (kDebugMode) {
    logger.i('🗺️  UserIdMapper initialized successfully');
  }

  // Initialize RoleIdMapper for role UUID to int mapping
  await RoleIdMapper().initialize();
  if (kDebugMode) {
    logger.i('🎭 RoleIdMapper initialized successfully');
  }

  // Load theme preference
  final themeBoxIs = Hive.box(themeBox);
  isDarkTheme = themeBoxIs.get(isDarkThemeKey, defaultValue: false);

  // Restore active base URL based on the saved user email
  final savedEmail = await HiveStorage.getUserEmail();
  if (savedEmail != null && savedEmail.isNotEmpty) {
    setBaseUrlByEmail(savedEmail);
  }

  // Configure system UI
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

// Create a separate function to initialize notifications after the app starts
Future<void> initializeNotifications(BuildContext context) async {
  if (Firebase.apps.isEmpty) return;
  final notificationService = NotificationService();
  await notificationService.initFirebaseMessaging(context);

  // Set up FCM token refresh listener
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    if (kDebugMode) {
      logger.i("New FCM Token: $newToken");
    }
    // Uncomment these if you have the methods available:
    // HiveStorage.setFcm(newToken);
    // AuthRepository().getFcmId(fcmId: newToken);
  });
}
