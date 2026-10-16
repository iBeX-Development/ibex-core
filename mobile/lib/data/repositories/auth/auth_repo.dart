import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:ibex/api_helper/header.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../../config/constants.dart';
import '../../../config/end_points.dart';
import '../../../config/strings.dart';
import '../../../utils/widgets/toast_widget.dart';
import '../../../utils/user_id_mapper.dart';
import '../../localStorage/hive.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AuthRepository {
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Set the active base URL based on the email domain before making the request
      setBaseUrlByEmail(email);

      var box = await Hive.openBox(fcmBox);
      String? fcmToken = box.get('fcmTokenId');
      Map<String, dynamic> body = {'email': email, 'password': password};
      if (fcmToken != null && fcmToken.isNotEmpty) {
        body['fcm_token'] = fcmToken;
        body['token'] = fcmToken;
      }

      var responses = await ApiBaseHelper.loginPost(
        url: getUserLoginApi,
        body: body,
      );

      // Persist the email so the correct base URL is restored on next app start
      await HiveStorage.saveUserEmail(email);

      return responses;
    } catch (error) {
      throw Exception('Error occurred back-endees hariu irsen uuuuu?');
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String firstname,
    required String type,
    required String lastname,
    required String company,
    required int role,
    required String email,
    required String password,
    required String conpassword,
  }) async {
    try {
      var responses = await ApiBaseHelper.signUpPost(
        url: getUserSignUpApi,
        body: {
          "type": type,
          "password": password,
          "email": email,
          "first_name": firstname,
          "last_name": lastname,
          "company": company,
          "role": role,
          "password_confirmation": conpassword,
        },
      );

      return responses;
    } catch (error) {
      flutterToastCustom(msg: error.toString());
      throw Exception('Error occurred');
      // return error;
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
  }) async {
    try {
      var box = await Hive.openBox(fcmBox);
      String? fcmToken = box.get('fcmTokenId');
      Map<String, dynamic> body = {'email': email, 'password': password};

      return body;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  void getFcmId({String? fcmId}) async {
    try {
      final Map<String, String>? header = await headers;
      header?["Accept"] = "application/json";
      header?["Content-Type"] = "application/json"; // Ensure JSON content type

      await ApiBaseHelper.patch(
        isMultipart: false,
        url: getUserFcmApi,
        body: {'fcm_token': fcmId, 'token': fcmId, "device_type": "mobile"},
      );
    } catch (e, stacktrace) {
      if (kDebugMode) {
        logger.d('Exception_getUserFcmApi_patch: $e');
      }
      if (kDebugMode) {
        logger.d('Stacktrace: $stacktrace');
      }
    }
  }

  void createFcmId({String? fcmId}) async {
    try {
      final Map<String, String>? header = await headers;
      header?["Accept"] = "application/json";
      header?["Content-Type"] = "application/json"; // Ensure JSON content type

      // Get user_id from Hive storage (int)
      int userId = await HiveStorage.getUserId();

      // Convert int back to UUID string for API
      String? userIdUuid = UserIdMapper().getUuid(userId);

      if (userIdUuid == null) {
        return;
      }

      var response = await ApiBaseHelper.post(
        url: getUserFcmApi,
        body: {
          'fcm_token': fcmId,
          'token': fcmId,
          "user_id": userIdUuid, // Send UUID string to API
          "device_type": "mobile",
        },
      );
    } catch (e, stacktrace) {
      if (kDebugMode) {
        logger.d('Exception createUserFcm: $e');
      }
      if (kDebugMode) {
        logger.d('Stacktrace createUserFcm: $stacktrace');
      }
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final Map<String, String>? header = await headers;
      header?["Accept"] = "application/json";
      header?["Content-Type"] = "application/json"; // Ensure JSON content type

      // Add Directus fields parameter to expand role relationship
      var response = await ApiBaseHelper.get(
        url: getUserInfoUrl,
        useAuthToken: true,
        params: {'fields': '*,role.*,policies.*'},
      );

      // Extract data from Response object
      if (response is Map<String, dynamic>) {
        return response;
      } else {
        // If response is Response object, get the data property
        return response.data as Map<String, dynamic>;
      }
    } catch (e, stacktrace) {
      if (kDebugMode) {
        logger.d('Exception getUserInfo: $e');
      }
      if (kDebugMode) {
        logger.d('Stacktrace getUserInfo: $stacktrace');
      }
      throw Exception('Error occurred while fetching user info');
    }
  }

  //SIGN OUT METHOD

  static Future signOut() async {
    await HiveStorage.clearToken();
    await HiveStorage.clearUserInfoData();
  }
}
