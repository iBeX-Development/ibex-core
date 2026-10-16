import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../../config/constants.dart';
import '../../config/strings.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class HiveStorage {
  final String languageBoxName = 'languagebox';
  final String defaultLanguageBoxName = 'defaultLanguagebox';

  static putToken(String value) async {
    var box = await Hive.openBox(authBox);
    box.put(customToken, value);
  }

  static saveUserEmail(String email) async {
    var box = await Hive.openBox(authBox);
    box.put('user_email', email);
  }

  static Future<String?> getUserEmail() async {
    var box = await Hive.openBox(authBox);
    return box.get('user_email');
  }

  static putSMSGatewayHeader(List<Map<dynamic, dynamic>> headerList) async {
    var box = await Hive.openBox(headerBox);
    box.put('headerList', headerList);
  }

  static putSMSGatewayFormData(List<Map<String, String>> formDataList) async {
    var box = await Hive.openBox(headerBox);
    box.put('formDataList', formDataList);
  }

  static putSMSGatewayParam(List<Map<String, String>> paramList) async {
    var box = await Hive.openBox(headerBox);
    box.put('paramList', paramList);
  }

  static putSMSGatewayAuthToken(String authToken) async {
    var box = await Hive.openBox(headerBox);
    box.put('authToken', authToken);
  }

  static Future<String?> getToken() async {
    var box = await Hive.openBox(authBox);
    var token = await box.get(customToken) ?? false;
    return box.get(customToken) ?? "";
  }

  static Future<String?> getSMSGatewayToken() async {
    var box = await Hive.openBox(headerBox);
    var token = await box.get('authToken') ?? false;
    return box.get('authToken') ?? "";
  }

  static Future<String> getRole() async {
    var box = await Hive.openBox(userBox);
    var role = await box.get('role');
    return box.get('role') ?? "";
  }

  static Future<String> getRoleName() async {
    var box = await Hive.openBox(userBox);
    var role = await box.get('role_name');
    return box.get('role_name') ?? "";
  }

  static setWorkspaceId(int workspaceIdd) async {
    Box box = await Hive.openBox(userBox);
    await box.put('workspace_id', workspaceIdd);
  }

  static setUserId(int userId) async {
    Box box = await Hive.openBox(userBox);
    await box.put('user_id', userId);
  }

  static setHasAllDataAccess(bool hasAllDataAccess) async {
    Box box = await Hive.openBox(userBox);
    await box.put('hasAllDataAccess', hasAllDataAccess);
  }

  static setFcm(String fcm) async {
    var box = await Hive.openBox(fcmBox);
    await box.put('fcmTokenId', fcm);
    ;
  }

  static setRole(String role) async {
    Box box = await Hive.openBox(userBox);
    await box.put('role', role);
  }

  static setRoleName(String roleName) async {
    Box box = await Hive.openBox(userBox);
    await box.put('role_name', roleName);
  }

  static setLocationId(int locationId) async {
    Box box = await Hive.openBox(userBox);
    await box.put('location_id', locationId);
  }

  static setLocationName(String locationName) async {
    Box box = await Hive.openBox(userBox);
    await box.put('location_name', locationName);
  }

  static Future<void> setBiometricAuth(bool status) async {
    try {
      Box box = await Hive.openBox(biometricAuthBox);
      await box.put('biometric', status);
    } catch (e) {
      if (kDebugMode) {
        logger.d("Error in setBiometricAuth: $e");
      }
    }
  }

  static setWorkspaceTitle(String workspaceTitle) async {
    Box box = await Hive.openBox(userBox);
    await box.put('workspace_title', workspaceTitle);
  }

  static setTeamsIdList(List<int> teamsIdList) async {
    Box box = await Hive.openBox(userBox);
    await box.put('teams_id_list', teamsIdList);
  }

  static setLocationIdList(List<int> locationIdList) async {
    Box box = await Hive.openBox(userBox);
    await box.put('location_id_list', locationIdList);
  }

  static Future<int> getWorkspaceId() async {
    Box box = await Hive.openBox(userBox);
    int workspaceId = box.get('workspace_id') ?? 0; // or any default ID
    return workspaceId;
  }

  static Future<List<int>> getTeamsIdList() async {
    Box box = await Hive.openBox(userBox);
    List<dynamic>? rawList = box.get('teams_id_list');
    return rawList != null ? rawList.cast<int>() : [];
  }

  // Status Type IDs storage
  static setOpenStatusIds(List<int> openStatusIds) async {
    Box box = await Hive.openBox(userBox);
    await box.put('open_status_ids', openStatusIds);
  }

  static setClosedStatusIds(List<int> closedStatusIds) async {
    Box box = await Hive.openBox(userBox);
    await box.put('closed_status_ids', closedStatusIds);
  }

  static setPendingStatusIds(List<int> pendingStatusIds) async {
    Box box = await Hive.openBox(userBox);
    await box.put('pending_status_ids', pendingStatusIds);
  }

  static setAllStatusIds(List<int> allStatusIds) async {
    Box box = await Hive.openBox(userBox);
    await box.put('all_status_ids', allStatusIds);
  }

  static setAllStatusData(List<dynamic> allStatusData) async {
    Box box = await Hive.openBox(userBox);
    await box.put('all_status_data', allStatusData);
  }

  static Future<List<int>> getOpenStatusIds() async {
    Box box = await Hive.openBox(userBox);
    List<dynamic>? rawList = box.get('open_status_ids');
    return rawList != null ? rawList.cast<int>() : [];
  }

  static Future<List<int>> getAllStatusIds() async {
    Box box = await Hive.openBox(userBox);
    List<dynamic>? rawList = box.get('all_status_ids');
    return rawList != null ? rawList.cast<int>() : [];
  }

  static Future<List<Object>> getAllStatusData() async {
    Box box = await Hive.openBox(userBox);
    List<dynamic>? rawList = box.get('all_status_data');
    // ✅ Convert to List<Map<String, dynamic>> if stored as JSON maps
    return rawList != null
        ? rawList
            .map((item) {
              if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              return item;
            })
            .cast<Object>()
            .toList()
        : [];
    return [];
  }

  static Future<void> setUserInfoDatas(Map<String, dynamic> userData) async {
    try {
      // ✅ Validate userData before storing
      if (userData.isEmpty) {
        throw Exception("userData is empty");
      }

      // ✅ FIX: Use userBox instead of 'userInfo'
      final box = await Hive.openBox(userBox);
      await box.put('userInfoData', userData);
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error in setUserInfoDatas: $e");
      }
      rethrow; // Re-throw to be caught in auth_bloc
    }
  }

  // ✅ FIX: Return Map instead of List
  static Future<Map<String, dynamic>> getUserInfoDatas() async {
    try {
      Box box = await Hive.openBox(userBox);

      // ✅ Get as Map instead of List
      dynamic rawData = box.get('userInfoData');
      if (rawData != null && rawData is Map) {
        // Convert Map<dynamic, dynamic> to Map<String, dynamic>
        Map<String, dynamic> userData = Map<String, dynamic>.from(rawData);
        return userData;
      }

      return {};
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error in getUserInfoDatas: $e");
      }
      return {};
    }
  }

  // ✅ ADD: Helper method to get specific user info fields
  static Future<String?> getUserInfoField(String fieldName) async {
    try {
      Map<String, dynamic> userData = await getUserInfoDatas();
      return userData[fieldName]?.toString();
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error getting user info field '$fieldName': $e");
      }
      return null;
    }
  }

  // ✅ Clear all user info data from userBox
  static Future<void> clearUserInfoData() async {
    try {
      Box box = await Hive.openBox(userBox);

      // Explicitly delete all known keys
      await box.delete('userInfoData');
      await box.delete('profilepic');
      await box.delete('teams_id_list');
      await box.delete('workspace_id');
      await box.delete('user_id');
      await box.delete('role');
      await box.delete('role_name');
      await box.delete('location_id');
      await box.delete('location_name');
      await box.delete('workspace_title');
      await box.delete('location_id_list');
      // await box.delete('open_status_ids');
      // await box.delete('closed_status_ids');
      // await box.delete('pending_status_ids');
      // await box.delete('all_status_ids');
      // await box.delete('all_status_data');
      await box.delete('hasAllDataAccess');
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error clearing user info data: $e");
      }
    }
  }

  static Future<List<int>> getClosedStatusIds() async {
    Box box = await Hive.openBox(userBox);
    List<dynamic>? rawList = box.get('closed_status_ids');
    return rawList != null ? rawList.cast<int>() : [];
  }

  static Future<List<int>> getPendingStatusIds() async {
    Box box = await Hive.openBox(userBox);
    List<dynamic>? rawList = box.get('pending_status_ids');
    return rawList != null ? rawList.cast<int>() : [];
  }

  // Get status IDs by type
  static Future<List<int>> getStatusIdsByType(String type) async {
    switch (type.toLowerCase()) {
      case 'open':
        return await getOpenStatusIds();
      case 'closed':
        return await getClosedStatusIds();
      case 'pending':
        return await getPendingStatusIds();
      default:
        return await getAllStatusIds(); // Default to open
    }
  }

  static Future<bool> getBiometricAuth() async {
    try {
      Box box = await Hive.openBox(biometricAuthBox);
      bool isActive = box.get('biometric', defaultValue: defaultBiometric);
      return isActive;
    } catch (e) {
      if (kDebugMode) {
        logger.d("Error in getBiometricAuth: $e");
      }
      return defaultBiometric; // Fallback to default
    }
  }

  static Future<String> getWorkspaceTitle() async {
    Box box = await Hive.openBox(userBox);
    String workspaceTitle = await box.get('workspace_title');
    return workspaceTitle;
  }

  static Future<int> getLocationId() async {
    Box box = await Hive.openBox(userBox);
    int location_id = await box.get('location_id');
    return location_id;
  }

  static Future<bool> getHasAllDataAccess() async {
    Box box = await Hive.openBox(userBox);
    bool hasAllDataAccess = await box.get('hasAllDataAccess');
    return hasAllDataAccess;
  }

  static Future<int> getUserId() async {
    Box box = await Hive.openBox(userBox);
    int userId = await box.get('user_id');
    return userId;
  }

  static Future<bool> getAllDataAccess() async {
    Box box = await Hive.openBox(userBox);
    bool hasAllDataAccess = await box.get('hasAllDataAccess');
    return box.get('hasAllDataAccess') ?? "";
  }

  static Future<bool> isToken() async {
    var box = await Hive.openBox(authBox);
    var token = await box.get(customToken);
    if (token != null && token != "") {
      return true;
    } else {
      return false;
    }
  }

  static Future<void> clearToken() async {
    var authbox = await Hive.openBox(authBox);
    var userbox = await Hive.openBox(userBox);
    var themebox = await Hive.openBox(themeBox);
    var biometricbox = await Hive.openBox(biometricAuthBox);

    // Save Remember Me data before clearing
    final rememberMe = authbox.get('rememberMe');
    final savedEmail = authbox.get('savedEmail');
    final savedPassword = authbox.get('savedPassword');
    final isFirstTime = authbox.get(firstTimeUserKey);

    await authbox.clear();
    await userbox
        .clear(); // ✅ This already clears all user data including teams_id_list
    await themebox.clear();
    await biometricbox.clear();

    // Restore Remember Me data after clearing only if rememberMe is true
    if (rememberMe == true) {
      await authbox.put('rememberMe', rememberMe);
      if (savedEmail != null) {
        await authbox.put('savedEmail', savedEmail);
      }
      if (savedPassword != null) {
        await authbox.put('savedPassword', savedPassword);
      }
    }
    if (isFirstTime != null) {
      await authbox.put(firstTimeUserKey, isFirstTime);
    }
  }

  static setIsFirstTime(value) async {
    var box = await Hive.openBox(authBox);
    box.put(firstTimeUserKey, value);
    getIsFirstTime();
  }

  static Future<bool> getIsFirstTime() async {
    var box = await Hive.openBox(authBox);

    return box.get(firstTimeUserKey) ?? true;
  }

  static Future<bool> isFirstTime() async {
    var box = await Hive.openBox(authBox);
    var isFirst = await box.get(firstTimeUserKey);
    if (isFirst != null) {
      return false;
    } else {
      return true;
    }
  }

  //== Language Hive

  Future<Box> openBox(String boxName) async {
    return await Hive.openBox(boxName);
  }

  Future<String?> getLanguage() async {
    final box = await openBox(languageBoxName);
    return box.get(languageKey);
  }

  Future<void> storeLanguage(String languageCode) async {
    final box = await openBox(languageBoxName);

    await box.put(languageKey, languageCode);
  }

  Future<void> storeDefaultLanguage(String languageCode) async {
    final box = await openBox(defaultLanguageBoxName);
    await box.put(languageKey, languageCode);
  }

  Future<String?> getDefaultLanguage() async {
    final box = await openBox(defaultLanguageBoxName);
    return box.get(languageKey);
  }

  // Remember Me functionality
  static Future<void> saveRememberMe(bool value) async {
    var box = await Hive.openBox(authBox);
    await box.put('rememberMe', value);
  }

  static Future<bool?> getRememberMe() async {
    var box = await Hive.openBox(authBox);
    return box.get('rememberMe');
  }

  static Future<void> saveEmail(String email) async {
    var box = await Hive.openBox(authBox);
    await box.put('savedEmail', email);
  }

  static Future<String?> getSavedEmail() async {
    var box = await Hive.openBox(authBox);
    return box.get('savedEmail');
  }

  static Future<void> savePassword(String password) async {
    var box = await Hive.openBox(authBox);
    await box.put('savedPassword', password);
  }

  static Future<String?> getSavedPassword() async {
    var box = await Hive.openBox(authBox);
    return box.get('savedPassword');
  }

  static Future<void> clearSavedCredentials() async {
    var box = await Hive.openBox(authBox);
    await box.delete('savedEmail');
    await box.delete('savedPassword');
  }

  // ✅ Save last active timestamp
  static Future<void> saveLastActiveTime(int timestamp) async {
    var box = await Hive.openBox(authBox);
    await box.put('lastActiveTime', timestamp);
    if (kDebugMode) {
      logger.d('💾 Saved last active time: $timestamp');
    }
  }

  // ✅ Get last active timestamp
  static Future<int?> getLastActiveTime() async {
    var box = await Hive.openBox(authBox);
    return box.get('lastActiveTime');
  }
}
