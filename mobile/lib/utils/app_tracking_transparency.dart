import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Request App Tracking Transparency permission on iOS
/// This is required by Apple's App Store guidelines when the app collects data for tracking
Future<void> requestAppTrackingPermission() async {
  // Only request on iOS
  if (!Platform.isIOS) {
    logger.i('🍎 ATT: Not iOS, skipping tracking permission request');
    return;
  }

  try {
    // Get current tracking authorization status
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    logger.i('🍎 ATT: Current tracking status: $status');

    // If permission is not determined, request it
    if (status == TrackingStatus.notDetermined) {
      // Show the tracking authorization dialog
      final newStatus =
          await AppTrackingTransparency.requestTrackingAuthorization();
      logger.i('🍎 ATT: User responded with: $newStatus');

      switch (newStatus) {
        case TrackingStatus.authorized:
          logger.i('🍎 ATT: ✅ Tracking authorized');
          break;
        case TrackingStatus.denied:
          logger.i('🍎 ATT: ❌ Tracking denied');
          break;
        case TrackingStatus.restricted:
          logger.i('🍎 ATT: ⚠️ Tracking restricted');
          break;
        case TrackingStatus.notDetermined:
          logger.i('🍎 ATT: ❓ Tracking not determined');
          break;
        default:
          logger.w('🍎 ATT: Unknown status: $newStatus');
      }
    } else {
      logger.i('🍎 ATT: Permission already determined: $status');
    }
  } catch (e) {
    logger.e('🍎 ATT: ❌ Error requesting tracking permission: $e');
    if (kDebugMode) {
      logger.d('App Tracking Transparency error: $e');
    }
  }
}

/// Get the current tracking authorization status
Future<TrackingStatus> getTrackingStatus() async {
  if (!Platform.isIOS) {
    return TrackingStatus.notSupported;
  }

  try {
    return await AppTrackingTransparency.trackingAuthorizationStatus;
  } catch (e) {
    logger.e('🍎 ATT: Error getting tracking status: $e');
    return TrackingStatus.notDetermined;
  }
}

/// Get the app tracking transparency identifier (IDFA)
/// This will be null if tracking is not authorized
Future<String?> getAdvertisingIdentifier() async {
  if (!Platform.isIOS) {
    return null;
  }

  try {
    final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
    logger.i('🍎 ATT: Advertising Identifier: $uuid');
    return uuid;
  } catch (e) {
    logger.e('🍎 ATT: Error getting advertising identifier: $e');
    return null;
  }
}
