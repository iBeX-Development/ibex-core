import 'package:flutter/foundation.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import '../../../config/strings.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

import '../../../utils/user_id_mapper.dart';
import '../../localStorage/hive.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ProfileRepo {
  Future<Map<String, dynamic>> getProfile({
    required bool token,
    required String id,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("USER REPO ");
      }
      var box = await Hive.openBox(userBox);
      var id = box.get('user_id');
      final response = await ApiBaseHelper.getApi(
        url: "$getUser/$id",
        useAuthToken: true,
        params: {},
      );
      // print('User Profile: $response');
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> getUserProfileDetails() async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: getUserDetailUrl,
        useAuthToken: true,
        params: {},
      );
      // print('User Profile Details: $response');
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updateProfile(
      {required File profile, required type, required id}) async {
    try {
      if (kDebugMode) {
        logger.d("FILE PHTOT $profile");
      }
      if (kDebugMode) {
        logger.d("FILE PHTOT  ID $id");
      }
      if (kDebugMode) {
        logger.d("FILE PHTOT  ID $type");
      }

      // await ApiBaseHelper.postProfile(
      //    url: "$updateProfileurl/$id/photo",
      //    useAuthToken: true,
      //    profile: profile,
      //
      //  );
      await Future.delayed(Duration(seconds: 2));
      final response = await ApiBaseHelper.postProfile(
          url: "$updateProfileUrl/photo",
          useAuthToken: true,
          profile: profile,
          type: type,
          id: id);
      if (kDebugMode) {
        logger.d(response);
      }
      return response as Map<String, dynamic>;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      return {
        'data': {'error': true, 'message': error.toString()}
      };
    }
  }

  Future<Map<String, dynamic>> updateProfileDeatils({
    required String firstname,
    required String lastname,
    required String email,
    String? address,
    int? role,
    String? password,
    String? conPassword,
    String? phone,
    String? countryCode,
    String? countryIsoCode,
    String? city,
  }) async {
    try {
      Map<String, dynamic> body = {
        "first_name": firstname,
        "last_name": lastname,
        "email": email,
        "phone": phone,
        // "role": role, // Removed - role should not be updated by user
        // "address": address,
        // "country_code": countryCode,
        // "country_iso_code": countryIsoCode,
        // "city": city,
      };

      // Only add password field if password is not empty
      if (password != null && password.isNotEmpty) {
        body["password"] = password;
      }

      var box = await Hive.openBox(userBox);
      var id = box.get('user_id');
      int myIntId = await HiveStorage.getUserId();
      String myUuid = UserIdMapper().convertIntsToUuids([myIntId]).first;
      // print("USER ID IN UPDATE PROFILE REPO: $id myUuid: $myUuid");
      if (kDebugMode) {
        logger.d("UPDATE PROFILE BODY: $body");
      }

      final response = await ApiBaseHelper.patch(
        url: "$updateProfilDetailsUrl/$myUuid",
        useAuthToken: true,
        body: body,
      );
      if (kDebugMode) {
        logger.d("UPDATE PROFILE RESPONSE:$response");
      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
}
