import 'package:flutter/foundation.dart';
import 'package:ibex/data/localStorage/hive.dart';
import 'package:ibex/utils/user_id_mapper.dart';

import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class NotificationRepo {
  Future<Map<String, dynamic>> getNoti({
    int? offset,
    int? limit,
    required bool token,
    String? search,
    String? notificationType,
    String? toDate,
    String? fromDate,
  }) async {
    try {
      Map<String, dynamic> body = {};
      if (search != null) {
        body["search"] = search;
      }
      if (toDate != null) {
        body["task_start_date_from"] = toDate;
      }
      if (fromDate != null) {
        body["task_start_date_to"] = fromDate;
      }
      if (limit != null) {
        body["limit"] = limit;
      }
      if (offset != null) {
        body["offset"] = offset;
      }
      // if (notificationType != null) {
      //   body["notification_type"] = notificationType;
      // }

      int myIntId = await HiveStorage.getUserId();
      String myUuid = UserIdMapper().convertIntsToUuids([myIntId]).first;
      body["sort"] = '-date_created';
      body["to_user"] = myUuid;
      body["fields"] =
          '*,from_user.last_name,from_user.first_name, from_user.avatar';

      final response = await ApiBaseHelper.getApi(
        url: getNotificationUrl,
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

  Future<Map<String, dynamic>> getUnreadNotiCount({
    String? notificationType,
    int? offset,
    int? limit,
    required bool token,
    String? search,
  }) async {
    try {
      Map<String, dynamic> body = {};
      // print("harshad: ${offset+limit}");
      if (notificationType != null) {
        body["notification_type"] = notificationType;
      }
      body['status'] = 'unread';
      final response = await ApiBaseHelper.getApi(
        url: getNotificationUrl,
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

  Future<Map<String, dynamic>> getDeleteNoti({
    required String id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.delete(
        url: "$deleteNotificationUrl/$id",
        useAuthToken: true,
        body: {},
      );

      // rows = response as Map<String, dynamic>;
      // for (var row in rows) {
      //   Todos.add(TodosModel.fromJson(row as Map<String, dynamic>));
      // }
      return response;
    } catch (e, stacktrace) {
      if (kDebugMode) {
        logger.d('Exception: $e');
      }
      if (kDebugMode) {
        logger.d('Stacktrace: $stacktrace');
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> markAsReadNoti({required int id}) async {
    try {
      final response = await ApiBaseHelper.patch(
        url: "$markAsReadNotificationUrl/$id",
        useAuthToken: true,
        body: {},
      );
      return response as Map<String, dynamic>;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
}
