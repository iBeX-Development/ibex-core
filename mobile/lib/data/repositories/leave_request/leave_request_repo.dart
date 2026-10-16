import 'package:flutter/foundation.dart';
import 'package:ibex/config/end_points.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';
import '../../../api_helper/api_base_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class LeaveRequestRepo {
  Future<Map<String, dynamic>> leaveRequestList({
    int? offset,
    int? limit,
    required bool token,
    String? toDate,
    int? upcomingDays,
    List<int>? userId,
    String? fromDate,
    String? search,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l sed $search");
      }
      Map<String, dynamic> body = {
        "limit": limit,
        "search": search,
        "offset": offset,
        "upcoming_days": upcomingDays,
      };
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l $body");
      }
      if (limit != null) {
        body["limit"] = limit;
      }
      if (fromDate != null) {
        body["start_date_to"] = toDate;
      }
      if (search != null) {
        body["search"] = search;
      }
      if (toDate != null) {
        body["start_date_from"] = fromDate;
      }
      if (offset != null) {
        body["offset"] = offset;
      }
      if (upcomingDays != 0) {
        body["upcoming_days"] = upcomingDays;
      }

      if (userId != null) {
        body["user_ids[]"] = userId;
      }
      final response = await ApiBaseHelper.getApi(
        url: listLeaveRequestUrl,
        useAuthToken: true,
        params: body,
      );
      if (kDebugMode) {
        logger.d("Response  $response");
      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> memberOnLeaveRequestList({
    int? offset,
    int? limit,
    required bool token,
    String? toDate,
    int? upcomingDays,
    List<int>? userId,
    String? fromDate,
    String? search,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l sed $upcomingDays");
      }
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l sed $userId");
      }
      Map<String, dynamic> body = {};
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l $body");
      }
      if (limit != null) {
        body["limit"] = limit;
      }
      if (fromDate != null) {
        body["start_date_to"] = toDate;
      }
      if (search != null) {
        body["search"] = search;
      }
      if (toDate != null) {
        body["start_date_from"] = fromDate;
      }
      if (offset != null) {
        body["offset"] = offset;
      }
      if (upcomingDays != 0) {
        body["upcoming_days"] = upcomingDays;
      }
      if (userId != null) {
        body["user_ids[]"] = userId;
      }
      final response = await ApiBaseHelper.getApi(
        url: memberOnLeaveRequestUrl,
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

  Future<int?> leaveRequestPending() async {
    try {
      int? statusPending;

      Map<String, dynamic> body = {"status": "pending"};
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l $body");
      }

      final response = await ApiBaseHelper.getApi(
        url: listLeaveRequestUrl,
        useAuthToken: true,
        params: body,
      );
      if (response['data'] != null) {
        if (kDebugMode) {
          logger.d("Responsedfdf dsrd $response");
        }
        if (kDebugMode) {
          logger.d("Responsedfdf  ${response['total']}");
        }
        statusPending = response['total'];
        if (kDebugMode) {
          logger.d("Responsedfdf wsaw ${response['total'].runtimeType}");
        }
      } else {
        if (kDebugMode) {
          logger.d("No data found in response or invalid response structure");
        }
      }
      if (kDebugMode) {
        logger.d("Responsedfdf  ${statusPending.toString()}");
      }
      return statusPending!;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> createLeaveRequest({
    required String reason,
    required String fromDate,
    required String toDate,
    required String fromTime,
    required String toTime,
    required String status,
    required String leaveVisibleToAll,
    required List<int> visibleToIds,
    required int userId,
    required String partialLeave,
    required bool token,
  }) async {
    try {
      Map<String, dynamic> body = {
        "reason": reason,
        "from_date": fromDate,
        "to_date": toDate,
        "from_time": fromTime,
        "to_time": toTime,
        "status": status,
        "leaveVisibleToAll": leaveVisibleToAll,
        "visible_to_ids": visibleToIds,
        "user_id": userId,
        "partialLeave": partialLeave,
      };
      final response = await ApiBaseHelper.post(
        url: createLeaveRequestUrl,
        useAuthToken: true,
        body: body,
      );
      if (kDebugMode) {
        logger.d("RESPONSE ${response['data']}");
      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> deleteLeaveRequest({
    required String id,
    required bool token,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("rftgyhujikl Id $id");
      }
      final response = await ApiBaseHelper.deleteApi(
        url: "$deleteLeaveRequestUrl/$id",
        useAuthToken: true,
      );

      if (kDebugMode) {

        logger.d("tgyhujikl $response");

      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      flutterToastCustom(msg: error.toString());
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updateLeaveRequest({
    required int id,
    required String reason,
    required String fromDate,
    required String toDate,
    required String fromTime,
    required String toTime,
    required String status,
    required String leaveVisibleToAll,
    required List<int> visibleToIds,
    required int userId,
    required String partialLeave,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "reason": reason,
        "from_date": fromDate,
        "to_date": toDate,
        "from_time": fromTime,
        "to_time": toTime,
        "status": status,
        "leaveVisibleToAll": leaveVisibleToAll,
        "visible_to_ids": visibleToIds,
        "user_id": userId,
        "partialLeave": partialLeave,
      };
      final response = await ApiBaseHelper.post(
        url: updateLeaveRequestUrl,
        useAuthToken: true,
        body: body,
      );
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
}
