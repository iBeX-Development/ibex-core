import 'package:firebase_core/firebase_core.dart';

// Public client configuration supplied per build; never place server credentials here.
class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment('CORE_FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('CORE_FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment('CORE_FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('CORE_FIREBASE_PROJECT_ID');
  static bool get isConfigured => _apiKey.isNotEmpty && _appId.isNotEmpty && _senderId.isNotEmpty && _projectId.isNotEmpty;
  static FirebaseOptions get currentPlatform {
    if (!isConfigured) throw StateError('Firebase integration disabled: client configuration missing');
    return const FirebaseOptions(apiKey: _apiKey, appId: _appId, messagingSenderId: _senderId, projectId: _projectId);
  }
}
