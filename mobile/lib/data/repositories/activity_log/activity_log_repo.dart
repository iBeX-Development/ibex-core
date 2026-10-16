import 'package:flutter/foundation.dart';
import 'package:ibex/config/end_points.dart';
import '../../../api_helper/api_base_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ActivityLogRepo {
  Future<Map<String, dynamic>> activityLogList({
    int? limit,
    int? offset,
    String? search = "",
    String? type,
    int? typeId,
    int? workId,
  }) async {
    try {
      Map<String, dynamic> body = {};
      if (search != null) {
        body["search"] = search;
      }
      if (limit != null) {
        body["limit"] = limit;
      }
      if (offset != null) {
        body["offset"] = offset;
      }
      if (type != null) {
        body["type"] = type;
      }
      if (typeId != null) {
        body["type_id"] = typeId;
      }
      if (workId != null || typeId != null) {
        body["filter[wo_id]"] = typeId;
        body["filter[wo_id]"] = typeId;
        body["fields"] =
            '*, first_user.id,first_user.first_name,first_user.last_name, first_user.email, first_user.avatar, next_user.id,next_user.first_name,next_user.last_name, next_user.email, next_user.avatar';
      }

      final response = await ApiBaseHelper.getApi(
        url: activityUrl,
        useAuthToken: true,
        params: body,
      );
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> deleteActivityLog({
    required String id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.deleteApi(
        url: "$deleteActivityUrl/$id",
        useAuthToken: true,
        body: {},
      );
      if (response['status_code'] == 401) {
        return response;
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
