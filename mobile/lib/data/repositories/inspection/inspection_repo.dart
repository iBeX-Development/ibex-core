import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ibex/config/constants.dart';
import 'package:ibex/utils/user_id_mapper.dart';

import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import '../../localStorage/hive.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionRepo {
  Future<Map<String, dynamic>> getInspections({
    int? id,
    int? isFav,
    int? limit,
    String? active,
    int? location,
    int? assetId,
    int? offset,
    String? search = "",
    List<int>? userId,
    List<int>? tagId,
    List<int>? clientId,
    List<int>? woStatus,
    List<int>? teamIds,
    List<int>? priorityId,
    List<int>? statusId,
    List<int>? ids,
    String? fromDate,
    String? toDate,
    String? createType,
    String? workType,
    Map<String, dynamic>? actionStatus,
  }) async {
    try {
      Map<String, dynamic> body = {};

      // ✅ If fetching specific ID, skip most filters
      if (id != null) {
        // Only include essential fields
        body["fields"] = '*, picture.*, asset.*, template.* ';

        // Make simple API call with ID
        final response = await ApiBaseHelper.getApi(
          url: "$inspectionUrl/$id",
          useAuthToken: true,
          params: body,
        );

        return response;
      }

      // Build fields
      body["fields"] = '*, picture.*, asset.*, template.* ';

      // Basic params
      body["sort[]"] = "-created_at";
      body["meta"] = "filter_count";

      if (limit != null) body["limit"] = limit;
      if (offset != null) body["offset"] = offset;
      if (search?.isNotEmpty ?? false) body["search"] = search;
      if (userId?.isNotEmpty ?? false) body["user_ids[]"] = userId;
      if (active != null) body["filter[active]"] = active;

      // Action status filter - properly parse the map
      if (actionStatus != null && actionStatus.isNotEmpty) {
        if (actionStatus.containsKey('_in')) {
          final inValues = actionStatus['_in'] as List<int>;
          for (int i = 0; i < inValues.length; i++) {
            body["filter[action_status][_in][$i]"] = inValues[i];
          }
        } else if (actionStatus.containsKey('_nin')) {
          final ninValues = actionStatus['_nin'] as List<int>;
          for (int i = 0; i < ninValues.length; i++) {
            body["filter[action_status][_nin][$i]"] = ninValues[i];
          }
        } else if (actionStatus.containsKey('_eq')) {
          body["filter[action_status][_eq]"] = actionStatus['_eq'];
        }
      }

      // Location filter
      // if (location != null) {
      //   body["filter[location]"] = location;
      // } else {
      //   location = await HiveStorage.getLocationId();
      //   body["filter[location]"] = location;
      // }

      if (workType?.isNotEmpty ?? false) {
        List<int> statusIds = await _getWoStatusIds(workType);

        if (statusIds.isNotEmpty) {
          body["filter[wo_status][_in]"] = statusIds;
        }
      }

      if (ids != null && ids.isNotEmpty) {
        body["filter[id][_in]"] = ids;
      }

      // Created type filter
      if (createType != null && createType.isNotEmpty && createType == 'open') {
        // body["filter[created_type]"] = "system";
        body["filter[pm_type][_in]"] = ["delivered", "generated"];
      }
      // Created type filter
      if (createType != null &&
          createType.isNotEmpty &&
          createType == 'completed') {
        // body["filter[created_type]"] = "system";
        body["filter[pm_type][_in]"] = ["completed", "generated"];
      }

      final response = await ApiBaseHelper.getApi(
        url: inspectionUrl,
        useAuthToken: true,
        params: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error in getInspections: ${error.toString()}");
      }

      if (error is DioException) {
        if (kDebugMode) {
          logger.d("❌ DioException type: ${error.type}");
        }
        if (kDebugMode) {
          logger.d("❌ Status code: ${error.response?.statusCode}");
        }
        if (kDebugMode) {
          logger.d("❌ Response getInspectionsdata: ${error.response?.data}");
        }
        if (kDebugMode) {
          logger.d("❌ Request URL: ${error.requestOptions.uri}");
        }
        if (kDebugMode) {
          logger.d("❌ Request params: ${error.requestOptions.queryParameters}");
        }

        // ✅ Handle 403 Forbidden
        if (error.response?.statusCode == 403) {
          if (kDebugMode) {
            logger.d("❌ 403 Forbidden - Check permissions or token");
          }

          String? token = await HiveStorage.getToken();
          if (token == null || token.isEmpty) {
            throw Exception('Authentication required. Please login again.');
          }

          // Log more details about the 403 error
          if (kDebugMode) {
            logger.d("❌ 403 Error details: ${error.response?.data}");
          }

          throw Exception(
              'Access forbidden. You may not have permission to view this data.');
        }
      }

      throw Exception('Error occurred: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> getInspectionsUsers({
    int? id,
    int? limit,
    int? active,
    int? location,
    int? offset,
    String? search = "",
    String? fields = "",
    int? userId,
  }) async {
    try {
      Map<String, dynamic> body = {};

      int myIntId = await HiveStorage.getUserId();
      String myUuid = UserIdMapper().convertIntsToUuids([myIntId]).first;

      // Build fields
      if (fields != null && fields.isNotEmpty) {
        body["fields"] = fields;
      } else {
        body["fields"] = '*, user.* ';
      }
      body["meta"] = "filter_count";

      if (limit != null) body["limit"] = limit;
      if (offset != null) body["offset"] = offset;
      if (search != null && search.isNotEmpty) body["search"] = search;
      if (active != null) body["filter[status]"] = active;

      if (id != null) {
        body["filter[work_order]"] = id;
      }

      if (userId != null) {
        body["filter[user][_in]"] = UserIdMapper().convertIntsToUuids([userId]);
      } else {
        body["filter[user][_in]"] = [myUuid];
      }

      // Make API call
      final response = await ApiBaseHelper.getApi(
        url: inspectionUsers,
        useAuthToken: true,
        params: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error in inspectionUsers: ${error.toString()}");
      }

      if (error is DioException) {
        if (kDebugMode) {
          logger.d("❌ DioException type: ${error.type}");
        }
        if (kDebugMode) {
          logger.d("❌ Status code: ${error.response?.statusCode}");
        }
        if (kDebugMode) {
          logger.d("❌ Response inspectionUsers data: ${error.response?.data}");
        }
        if (kDebugMode) {
          logger.d("❌ Request URL: ${error.requestOptions.uri}");
        }
        if (kDebugMode) {
          logger.d("❌ Request params: ${error.requestOptions.queryParameters}");
        }

        // ✅ Handle 403 Forbidden
        if (error.response?.statusCode == 403) {
          if (kDebugMode) {
            logger.d("❌ 403 Forbidden - Check permissions or token");
          }

          String? token = await HiveStorage.getToken();
          if (token == null || token.isEmpty) {
            throw Exception('Authentication required. Please login again.');
          }

          // Log more details about the 403 error

          throw Exception(
              'Access forbidden. You may not have permission to view this data.');
        }
      }

      throw Exception('Error occurred: ${error.toString()}');
    }
  }

// ✅ Helper method to get status IDs based on work type
  Future<List<int>> _getWoStatusIds(String? type) async {
    if (type == null || type.isEmpty) {
      return await HiveStorage.getAllStatusIds();
    }

    switch (type.toLowerCase()) {
      case "open":
        List<int> openIds = await HiveStorage.getOpenStatusIds();
        return openIds;

      case "completed":
        List<int> closedIds = await HiveStorage.getClosedStatusIds();
        return closedIds;

      case "request":
        return [1];

      default:
        List<int> allIds = await HiveStorage.getAllStatusIds();
        return allIds;
    }
  }

  Future<Map<String, dynamic>> getInspectionsFav({
    int? limit,
    int? offset,
    String? search = "",
    int? isFav,
  }) async {
    try {
      Map<String, dynamic> body = {};

// Add parameters to the request body, avoiding null values
      if (search?.isNotEmpty ?? false) body["search"] = search;
      if (limit != null) body["limit"] = limit;
      if (offset != null) body["offset"] = offset;
      if (isFav != null) body["is_favorites"] = isFav;

      // Add search, limit, and offset to the body if they are not null
      // if (search != null && search.isNotEmpty) {
      //   body["search"] = search;
      // }
      // if (limit != null) {
      //   body["limit"] = limit;
      // }
      // if (offset != null) {
      //   body["offset"] = offset;
      // }
      // if ( userId != null) {
      //   body["user_ids[]"] = userId;
      // }
      // if ( clientId != null) {
      //   body["client_ids[]"] = clientId;
      // }
      // if ( tagId != null) {
      //   body["tag_ids[]"] = tagId;
      // }
      // if ( statusId != null) {
      //   body["status_ids[]"] = statusId;
      // }
      // if ( priorityId != null) {
      //   body["priority_ids[]"] = priorityId;
      // }
      // if ( toDate != null) {
      //   body["project_end_date_to"] = toDate;
      // }
      // if (fromDate != null) {
      //   body["project_start_date_from"] = fromDate;
      // }

      // Make API call based on whether an id is provided
      final response = await ApiBaseHelper.getApi(
        url: inspectionUrl,
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

  // ✅ Update work order percentage
  Future<Map<String, dynamic>> updateWorkOrderPercent({
    required int workOrderId,
    required String woPercent,
  }) async {
    try {
      Map<String, dynamic> body = {
        "wo_percent": woPercent,
      };

      final response = await ApiBaseHelper.patch(
        url: "$inspectionUrl/$workOrderId",
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error updating work order percent: ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updateInspection({
    required int id,
    String? title,
    int? statusId,
    int? priorityId,
    String? startDate,
    String? endDate,
    String? desc,
    String? taskAccess,
    String? note,
    String? budget,
    List<int>? userId,
    List<int>? clientId,
    List<int>? assetId,
    List<int>? tagId,
    int? canClientDiscuss,
    int? enable,
    Map<String, dynamic>? customFieldValues, // Nullable parameter
  }) async {
    try {
      // Safely unwrap and prepare the custom fields

      int? team_id = (userId != null && userId.isNotEmpty) ? userId[0] : null;
      int? asset = (assetId != null && assetId.isNotEmpty) ? assetId[0] : null;

      // ✅ Construct the request body - only include non-null/non-empty values
      Map<String, dynamic> body = {};

      if (title != null && title.isNotEmpty && title != '') {
        body["name"] = title;
      }

      if (statusId != null && statusId != '') {
        body["wo_status"] = statusId;
      }

      if (priorityId != null && priorityId != '') {
        body["priority"] = priorityId;
      }

      if (startDate != null && startDate.isNotEmpty && startDate != '') {
        body["started_at"] = startDate;
      }

      if (endDate != null && endDate.isNotEmpty && endDate != '') {
        body["due"] = endDate;
      }

      // ✅ Only add description if not empty
      if (desc != null && desc.isNotEmpty) {
        body["history_description"] = desc;
      }

      // ✅ Only add budget if not empty
      if (budget != null && budget.isNotEmpty) {
        body["budget"] = budget;
      }

      // ✅ Only add note if not empty
      if (note != null && note.isNotEmpty) {
        body["safety_notes"] = note;
      }

      // ✅ Only add team_id if valid
      if (team_id != null && team_id > 0) {
        body["assigned_team"] = team_id;
      }

      // ✅ Only add asset if valid
      if (asset != null && asset > 0) {
        body["asset"] = asset;
      }

      // Make the API request
      final response = await ApiBaseHelper.patch(
        url: "$updateInspectionUrl/$id",
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d(" Error: ${error.toString()}");
      }
      throw Exception(error.toString());
    }
  }

  Future<Map<String, dynamic>> createInspection(
      {required String title,
      required int statusId,
      required int priorityId,
      required String startDate,
      required String endDate,
      required String desc,
      required String note,
      String? taskAccess,
      String? budget,
      int? actionStatus,
      int? workType,
      String? createdType,
      String? team_id,
      List<int>? userId,
      List<int>? locationId,
      List<int>? assetId,
      List<int>? clientId,
      String? requestUser,
      List<int>? tagId,
      int? canClientDiscuss,
      int? enable,
      Map<String, dynamic>? customFieldValues, // Nullable parameter

      String? search}) async {
    try {
      // ✅ Convert userId list to single team_id
      int? teamId = (userId != null && userId.isNotEmpty) ? userId[0] : null;
      int? locationIdValue =
          (locationId != null && locationId.isNotEmpty) ? locationId[0] : null;

      // ✅ Build request body - only include non-null/non-empty values
      Map<String, dynamic> body = {
        "name": title,
        "wo_status": statusId,
        "priority": priorityId,
        "type": workType ?? 1,
        "action_status": actionStatus ?? 1,
      };
// ✅ FIX: Only add dates if they are valid and not empty
      if (startDate.isNotEmpty && startDate != '') {
        body["started_at"] = startDate;
      }

      if (endDate.isNotEmpty && endDate != '') {
        body["due"] = endDate;
      }

      if (desc.isNotEmpty) {
        body["history_description"] = desc;
      }

      if (note.isNotEmpty) {
        body["safety_notes"] = note;
      }

      // if (phone != null && phone.isNotEmpty) {
      //   body["phone"] = phone;
      // }

      if (createdType != null && createdType.isNotEmpty) {
        body["created_type"] = createdType;
      }

      if (createdType == 'request' &&
          requestUser != null &&
          requestUser.isNotEmpty) {
        body["request_user"] = requestUser;
      } else {
        if (teamId != null) {
          body["assigned_team"] = teamId;
        }
      }

      if (locationIdValue != null) {
        body["location"] = locationIdValue;
      }

      if (budget != null && budget.isNotEmpty) {
        body["budget"] = budget;
      }

      if (assetId != null && assetId.isNotEmpty) {
        body["asset"] = assetId[0];
      }

      if (clientId != null && clientId.isNotEmpty) {
        body["client"] = clientId;
      }

      if (tagId != null && tagId.isNotEmpty) {
        body["tags"] = tagId;
      }

      if (canClientDiscuss != null) {
        body["can_client_discuss"] = canClientDiscuss;
      }

      if (enable != null) {
        body["enable_time_entries"] = enable;
      }

      if (customFieldValues != null && customFieldValues.isNotEmpty) {
        body.addAll(customFieldValues);
      }

      final response = await ApiBaseHelper.post(
        url: createInspectionUrl,
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

  Future<Map<String, dynamic>> getDeleteInspection({
    required String id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.delete(
          url: "$deleteInspectionUrl/$id", useAuthToken: true, body: {});

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<void> updateInspectionActionStatus({
    required int id,
    required int actionStatus,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "action_status": actionStatus,
      };

      // Make the API request
      final response = await ApiBaseHelper.patch(
        url: "$updateInspectionUrl/$id",
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        logger.d('❌ Error updating work action status: $e');
      }
      rethrow;
    }
  }

// ✅ NEW: Create Inspection Order Actions
  Future<Map<String, dynamic>> createInspectionOrderActions({
    required int woId,
    required String firstUser,
    required int actionStatus,
    required String type,
  }) async {
    try {
      Map<String, dynamic> body = {
        "wo_id": woId,
        "first_user": firstUser,
        "action_status": actionStatus,
        "type": type,
      };

      final response = await ApiBaseHelper.post(
        url: baseUrl + 'items/Work_inspection_actions',
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error creating Work_inspection_actions: ${error.toString()}");
      }
      return {
        'errors': [
          {'message': error.toString()}
        ]
      };
    }
  }

// ✅ NEW: Create Inspection Order Item
  Future<Map<String, dynamic>> createInspectionOrderItem({
    required int status,
    required String label,
    required int workorder,
    required String name,
    required String requestInfo,
    required String createdType,
  }) async {
    try {
      Map<String, dynamic> body = {
        "status": status,
        "label": label,
        "workorder": workorder,
        "name": name,
        "request_info": requestInfo,
        "created_type": createdType,
      };

      final response = await ApiBaseHelper.post(
        url: baseUrl + 'items/Work_inspection_item',
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error creating Work_inspection_item: ${error.toString()}");
      }
      return {
        'errors': [
          {'message': error.toString()}
        ]
      };
    }
  }

  //Part
  Future<Map<String, dynamic>> getInspectionsPart({
    int? id,
    int? limit,
    int? offset,
    String? search = "",
    String? dateBetweenFrom,
    String? dateBetweenTo,
    String? startDateFrom,
    String? startDateTo,
    String? endDateFrom,
    String? endDateTo,
    String? status,
  }) async {
    try {
      Map<String, dynamic> body = {};

      // ✅ Add parameters to the request body, avoiding null values
      if (limit != null) body["limit"] = limit;
      if (offset != null) body["offset"] = offset;
      body["meta"] = "filter_count,total_count";

      // ✅ Filter by work_order (required)
      if (id != null) {
        body["filter[work_order][_eq]"] = id;
      }

      // ✅ Filter by status if provided
      if (status != null && status.isNotEmpty) {
        body["filter[status][_eq]"] = status;
      }

      // ✅ Search in parts name or description
      if (search != null && search.isNotEmpty) {
        body["filter[_or][0][parts][name][_icontains]"] = search;
        body["filter[_or][1][parts][description][_icontains]"] = search;
      }

      // ✅ Date filters
      if (dateBetweenFrom != null && dateBetweenFrom.isNotEmpty) {
        body["filter[date_created][_gte]"] = dateBetweenFrom;
      }
      if (dateBetweenTo != null && dateBetweenTo.isNotEmpty) {
        body["filter[date_created][_lte]"] = dateBetweenTo;
      }

      if (startDateFrom != null && startDateFrom.isNotEmpty) {
        body["filter[start_date][_gte]"] = startDateFrom;
      }
      if (startDateTo != null && startDateTo.isNotEmpty) {
        body["filter[start_date][_lte]"] = startDateTo;
      }

      if (endDateFrom != null && endDateFrom.isNotEmpty) {
        body["filter[end_date][_gte]"] = endDateFrom;
      }
      if (endDateTo != null && endDateTo.isNotEmpty) {
        body["filter[end_date][_lte]"] = endDateTo;
      }

      // ✅ Include nested parts fields
      body["fields"] = "*, parts.*";

      // ✅ Sort by date created descending
      body["sort"] = "-date_created";

      // Make API call
      final response = await ApiBaseHelper.getApi(
        url: workPartUrl,
        useAuthToken: true,
        params: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ getInspectionsPart Error: ${error.toString()}");
      }

      // ✅ Better error handling
      if (error is DioException) {
        if (kDebugMode) {
          logger.d("❌ DioException type: ${error.type}");
        }
        if (kDebugMode) {
          logger.d("❌ Status code: ${error.response?.statusCode}");
        }
        if (kDebugMode) {
          logger.d("❌ Response data: ${error.response?.data}");
        }
        if (kDebugMode) {
          logger.d("❌ Request data: ${error.requestOptions.data}");
        }
        if (kDebugMode) {
          logger.d("❌ Request params: ${error.requestOptions.queryParameters}");
        }

        // Return more specific error
        throw Exception(
            'API Error ${error.response?.statusCode}: ${error.response?.data}');
      }

      throw Exception('Error fetching work parts: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateInspectionPart(
      {required int id,
      required int projectId,
      required String title,
      required String status,
      required String startDate,
      required String endDate,
      required String cost,
      required String desc,
      int? progress}) async {
    try {
      Map<String, dynamic> body = {
        "project_id": projectId,
        "id": id,
        "title": title,
        "status": status,
        "start_date": startDate,
        "end_date": endDate,
        "description": desc,
        "cost": cost,
        "progress": progress ?? null
      };
      final response = await ApiBaseHelper.post(
          url: workPartUrl, useAuthToken: true, body: body);

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception(error.toString());
    }
  }

  Future<Map<String, dynamic>> createInspectionPart(
      {required int id,
      required String title,
      required String status,
      required String startDate,
      required String endDate,
      required String cost,
      required String desc}) async {
    try {
      Map<String, dynamic> body = {
        "project_id": id,
        "title": title,
        "status": status,
        "start_date": startDate,
        "end_date": endDate,
        "description": desc,
        "cost": cost,
      };

      final response = await ApiBaseHelper.post(
        url: workPartUrl,
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

  Future<Map<String, dynamic>> getDeleteInspectionPart({
    required String id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.delete(
          url: "$workPartUrl/$id", useAuthToken: true, body: {});

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  //Trade
  Future<Map<String, dynamic>> getInspectionsTrade({
    int? id,
    int? limit,
    int? offset,
    String? search = "",
    String? dateBetweenFrom,
    String? dateBetweenTo,
    String? startDateFrom,
    String? startDateTo,
    String? endDateFrom,
    String? endDateTo,
    String? status,
  }) async {
    try {
      Map<String, dynamic> body = {};

      // ✅ Add parameters to the request body, avoiding null values
      if (limit != null) body["limit"] = limit;
      if (offset != null) body["offset"] = offset;
      body["meta"] = "filter_count,total_count";

      // ✅ Filter by work_order (required)
      if (id != null) {
        body["filter[work_order][_eq]"] = id;
      }

      // ✅ Filter by status if provided
      if (status != null && status.isNotEmpty) {
        body["filter[status][_eq]"] = status;
      }

      // ✅ Search in parts name or description
      if (search != null && search.isNotEmpty) {
        body["filter[_or][0][parts][name][_icontains]"] = search;
        body["filter[_or][1][parts][description][_icontains]"] = search;
      }

      // ✅ Date filters
      if (dateBetweenFrom != null && dateBetweenFrom.isNotEmpty) {
        body["filter[date_created][_gte]"] = dateBetweenFrom;
      }
      if (dateBetweenTo != null && dateBetweenTo.isNotEmpty) {
        body["filter[date_created][_lte]"] = dateBetweenTo;
      }

      if (startDateFrom != null && startDateFrom.isNotEmpty) {
        body["filter[start_date][_gte]"] = startDateFrom;
      }
      if (startDateTo != null && startDateTo.isNotEmpty) {
        body["filter[start_date][_lte]"] = startDateTo;
      }

      if (endDateFrom != null && endDateFrom.isNotEmpty) {
        body["filter[end_date][_gte]"] = endDateFrom;
      }
      if (endDateTo != null && endDateTo.isNotEmpty) {
        body["filter[end_date][_lte]"] = endDateTo;
      }

      // ✅ Include nested parts fields
      body["fields"] = "*, parts.*";

      // ✅ Sort by date created descending
      body["sort"] = "-date_created";

      // Make API call
      final response = await ApiBaseHelper.getApi(
        url: workTradeUrl,
        useAuthToken: true,
        params: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ getInspectionsTrade Error: ${error.toString()}");
      }

      // ✅ Better error handling
      if (error is DioException) {
        if (kDebugMode) {
          logger.d("❌ DioException type: ${error.type}");
        }
        if (kDebugMode) {
          logger.d("❌ Status code: ${error.response?.statusCode}");
        }
        if (kDebugMode) {
          logger.d("❌ Response data: ${error.response?.data}");
        }
        if (kDebugMode) {
          logger.d("❌ Request data: ${error.requestOptions.data}");
        }
        if (kDebugMode) {
          logger.d("❌ Request params: ${error.requestOptions.queryParameters}");
        }

        // Return more specific error
        throw Exception(
            'API Error ${error.response?.statusCode}: ${error.response?.data}');
      }

      throw Exception('Error fetching work parts: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateInspectionTrade(
      {required int id,
      required int projectId,
      required String title,
      required String status,
      required String startDate,
      required String endDate,
      required String cost,
      required String desc,
      int? progress}) async {
    try {
      Map<String, dynamic> body = {
        "project_id": projectId,
        "id": id,
        "title": title,
        "status": status,
        "start_date": startDate,
        "end_date": endDate,
        "description": desc,
        "cost": cost,
        "progress": progress ?? null
      };
      final response = await ApiBaseHelper.post(
          url: workTradeUrl, useAuthToken: true, body: body);

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception(error.toString());
    }
  }

  Future<Map<String, dynamic>> createInspectionTrade(
      {required int id,
      required String title,
      required String status,
      required String startDate,
      required String endDate,
      required String cost,
      required String desc}) async {
    try {
      Map<String, dynamic> body = {
        "project_id": id,
        "title": title,
        "status": status,
        "start_date": startDate,
        "end_date": endDate,
        "description": desc,
        "cost": cost,
      };

      final response = await ApiBaseHelper.post(
        url: workTradeUrl,
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

  Future<Map<String, dynamic>> getDeleteInspectionTrade({
    required String id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.delete(
          url: "$workTradeUrl/$id", useAuthToken: true, body: {});

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

// Milestone
  Future<Map<String, dynamic>> getInspectionsMilestone({
    int? id,
    int? limit,
    int? offset,
    String? search = "",
    String? dateBetweenFrom,
    String? dateBetweenTo,
    String? startDateFrom,
    String? startDateTo,
    String? endDateFrom,
    String? endDateTo,
    String? status,
  }) async {
    try {
      Map<String, dynamic> body = {};

// Add parameters to the request body, avoiding null values
      if (search?.isNotEmpty ?? false) body["search"] = search;
      if (limit != null) body["limit"] = limit;
      if (offset != null) body["offset"] = offset;
      if (dateBetweenFrom != null) body["date_between_from"] = dateBetweenFrom;
      if (dateBetweenTo != null) body["date_between_to"] = dateBetweenTo;
      if (startDateFrom != null) body["start_date_from"] = startDateFrom;
      if (startDateTo != null) body["start_date_to"] = startDateTo;
      if (endDateFrom != null) body["end_date_from"] = endDateFrom;
      if (endDateTo != null) body["end_date_to"] = endDateTo;
      if (status != null) body["status"] = status;

      // Make API call based on whether an id is provided
      final response = await ApiBaseHelper.getApi(
        url: id != null ? "$workMilestoneUrl/$id" : workMilestoneUrl,
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

  Future<Map<String, dynamic>> createInspectionMilestone(
      {required int id,
      required String title,
      required String status,
      required String startDate,
      required String endDate,
      required String cost,
      required String desc}) async {
    try {
      Map<String, dynamic> body = {
        "project_id": id,
        "title": title,
        "status": status,
        "start_date": startDate,
        "end_date": endDate,
        "description": desc,
        "cost": cost,
      };

      final response = await ApiBaseHelper.post(
        url: inspectionUrl,
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

  Future<Map<String, dynamic>> getDeleteInspectionMilestone({
    required String id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.delete(
          url: "$inspectionUrl/$id", useAuthToken: true, body: {});

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> getInspectionMedia({
    int? id,
    int? limit,
    int? offset,
    String? search = "",
  }) async {
    try {
      Map<String, dynamic> body = {};
// Add parameters to the request body, avoiding null values
      if (search?.isNotEmpty ?? false) body["search"] = search;
      if (limit != null) body["limit"] = limit;
      if (offset != null) body["offset"] = offset;
      // if (id != null) body["id"] = id;
      if (id != null) {
        body["fields"] = '*, file.*';
        body["filter[work_order][_eq]"] = id;
        body["filter[status][_eq]"] = 1;
      }

      final response = await ApiBaseHelper.getApi(
        url: inspectionItemUploadTaskMediaUrl,
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

  Future<Map<String, dynamic>> getInspectionMindMap({
    int? id,
  }) async {
    try {
      Map<String, dynamic> body = {};

      final response = await ApiBaseHelper.getApi(
        url: "${workMindMapUrl}projects/$id/mind-map",
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

  Future<Map<String, dynamic>> getInspectionTimeLineStatus({
    int? id,
    int? limit,
    int? offset,
    String? search = "",
  }) async {
    try {
      Map<String, dynamic> body = {};

// Add parameters to the request body, avoiding null values
      if (search?.isNotEmpty ?? false) body["search"] = search;
      if (limit != null) body["limit"] = limit;
      if (offset != null) body["offset"] = offset;

      final response = await ApiBaseHelper.getApi(
        url: id != null
            ? "$workTimelineStatusUrl$id/status-timelines"
            : workTimelineStatusUrl,
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

  Future<Map<String, dynamic>> getDeleteInspectionMedia({
    required String id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.delete(
          url: "$deleteInspectionMediaUrl/$id", useAuthToken: true, body: {});

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> uploadInspectionMedia({
    required int id,
    required List<File> media,
  }) async {
    try {
      List<String> uploadedFileIds = [];

      // ✅ Step 1: Upload files to Directus /files endpoint
      for (final file in media) {
        FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        });

        final uploadResponse = await ApiBaseHelper.postMedia(
          url: uploadInspectionMediaUrl, // Directus files endpoint
          formData: formData,
          useAuthToken: true,
        );

        if (uploadResponse['data'] != null) {
          final fileId = uploadResponse['data']['id'];
          uploadedFileIds.add(fileId);
        }
      }

      // ✅ Step 2: Create work_media records linking files to work_order
      List<Map<String, dynamic>> mediaRecords = [];
      for (final fileId in uploadedFileIds) {
        final response = await ApiBaseHelper.post(
          url: inspectionItemUploadTaskMediaUrl,
          body: {
            'work_order': id,
            'file': fileId,
            'status': '1',
          },
          useAuthToken: true,
        );
        mediaRecords.add(response);
      }

      return {
        'error': false,
        'message': 'Files uploaded successfully',
        'data': mediaRecords,
      };
      // return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error files ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> uploadInspectionTaskMedia({
    required int id,
    required List<File> media,
  }) async {
    try {
      List<String> uploadedFileIds = [];

      // ✅ Step 1: Upload files to Directus /files endpoint
      for (final file in media) {
        FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        });

        final uploadResponse = await ApiBaseHelper.postMedia(
          url: uploadInspectionMediaUrl, // Directus files endpoint
          formData: formData,
          useAuthToken: true,
        );

        if (uploadResponse['data'] != null) {
          final fileId = uploadResponse['data']['id'];
          uploadedFileIds.add(fileId);
        }
      }

      // ✅ Step 2: Update Work_inspection_item with nested photos structure
      List<Map<String, dynamic>> photosCreate = [];
      for (final fileId in uploadedFileIds) {
        photosCreate.add({
          'Work_inspection_item_id': id,
          'directus_files_id': {
            'id': fileId,
          },
        });
      }

      Map<String, dynamic> updateBody = {
        'photos': {
          'create': photosCreate,
        },
      };

      final response = await ApiBaseHelper.patch(
        url: '$inspectionItem/$id',
        body: updateBody,
        useAuthToken: true,
      );

      return {
        'error': false,
        'message': 'Files uploaded successfully',
        'data': response,
      };
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error uploading task files: ${error.toString()}");
      }
      throw Exception('Error occurred: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateInspectionPinned({
    required int id,
    required int isPinned,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "is_pinned": isPinned,
      };

      final response = await ApiBaseHelper.patch(
        url: "$updatePinnedInspectionUrl/$id/pinned",
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

  Future<Map<String, dynamic>> updateInspectionFavorite({
    required int id,
    required int isFavorite,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "is_favorite": isFavorite,
      };

      final response = await ApiBaseHelper.patch(
        url: "$updatePinnedInspectionUrl/$id/favorite",
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
