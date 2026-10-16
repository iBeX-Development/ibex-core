import 'package:flutter/foundation.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import '../../localStorage/hive.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class PermissionRepo {
  Future<Map<String, dynamic>> getPermissions({
    String? permissionFor,
    required bool token,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      final my_role_id = await HiveStorage.getRole();
      params['fields'] = '*';
      params['filter[id][_eq]'] = my_role_id ?? '0';

      final response = await ApiBaseHelper.get(
        url: assignedPermissionsurl,
        useAuthToken: true,
        params: params,
      );

      return response.data as Map<String, dynamic>;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> getAllPermissions({
    String? permissionFor,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.get(
        url: getAllPermissionsListUrl,
        useAuthToken: true,
        params: {},
      );

      return response.data as Map<String, dynamic>;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
}
