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

class WorkRepo {
  Future<Map<String, dynamic>> getWorks({
    int? id,
    int? isFav,
    int? limit,
    int? active,
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
    String? fromDate,
    String? toDate,
    String? createType,
    String? workType,
    Map<String, dynamic>? actionStatus,
    List<int>?
        workOrderIds, // ✅ Filter by work order IDs from Work_order_task_users
  }) async {
    try {
      Map<String, dynamic> body = {};

      int myIntId = await HiveStorage.getUserId();
      String myUuid = UserIdMapper().convertIntsToUuids([myIntId]).first;
      // ✅ If fetching specific ID, skip most filters
      if (id != null) {
        // Only include essential fields
        body["fields"] =
            '*, assigned_team.name, assigned_team.id, assigned_team._image';
        body["fields"] += ', asset.name, asset.id, asset.asset_code';
        body["fields"] +=
            ', assigned_to.first_name, assigned_to.last_name, assigned_to.email, assigned_to.role.name, assigned_to.avatar';

        // Make simple API call with ID
        final response = await ApiBaseHelper.getApi(
          url: "$workUrl/$id",
          useAuthToken: true,
          params: body,
        );

        return response;
      }

      // ✅ For list queries, apply filters

      // Get effective team IDs
      List<int>? effectiveTeamIds = teamIds;
      if (effectiveTeamIds == null || effectiveTeamIds.isEmpty) {
        effectiveTeamIds = await HiveStorage.getTeamsIdList();
      }

      // Build fields
      body["fields"] =
          '*, assigned_team.name, assigned_team.id, assigned_team._image';
      body["fields"] += ', asset.name, asset.id, asset.asset_code';
      body["fields"] +=
          ', assigned_to.first_name, assigned_to.last_name, assigned_to.email, assigned_to.role.name, assigned_to.avatar';

      // Basic params
      body["sort[]"] = "-started_at";
      body["meta"] = "filter_count";

      if (limit != null) body["limit"] = limit;
      if (offset != null) body["offset"] = offset;
      if (search?.isNotEmpty ?? false) body["search"] = search;
      if (userId?.isNotEmpty ?? false) body["user_ids[]"] = userId;

      // Location filter
      // if (location != null) {
      //   body["filter[location]"] = location;
      // } else {
      //   location = await HiveStorage.getLocationId();
      //   body["filter[location]"] = location;
      // }

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

      // Work order status filter
      // if (woStatus != null && woStatus.isNotEmpty) {
      //   if (workType == 'assigned') {
      //     print('🔹 Skipping wo_status filter for assigned workType');
      //   } else {
      //     print('🔹 Applying wo_status filter: $woStatus');
      //   }
      //   // for (int i = 0; i < woStatus.length; i++) {
      //   //   body["filter[wo_status][_in][$i]"] = woStatus[i];
      //   // }
      // }

      if (workType?.isNotEmpty ?? false) {
        List<int> statusIds = await _getWoStatusIds(workType);

        if (workType == "assigned") {
          body["filter[assigned_to][_in]"] = [myUuid];
          body["filter[action_status][_in]"] = [4];
          // ✅ Don't filter by action_status with UUID - assigned_to is enough
        } else if (statusIds.isNotEmpty) {
          // for (int i = 0; i < statusIds.length; i++) {
          //   body["filter[wo_status][_in][$i]"] = statusIds[i];
          // }
          body["filter[wo_status][_in]"] = statusIds;
        }
      }

      // Created type filter
      if (createType?.isNotEmpty ?? false) {
        if (createType == "request") {
          body["filter[created_type]"] = createType;

          body["filter[request_user][_in]"] = [myUuid];
          body["filter[request_user][_null]"] = false;

          // Action status filter for requests
          if (actionStatus != null) {
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
        } else if (createType == "assigned") {
          body.remove("filter[location]");
          body["filter[assigned_to][_in]"] = [myUuid];
          // ✅ For assigned type, optionally filter by action_status integers only
          if (actionStatus != null && actionStatus.containsKey('_in')) {
            final inValues = actionStatus['_in'] as List<int>;
            for (int i = 0; i < inValues.length; i++) {
              body["filter[action_status][_in][$i]"] = inValues[i];
            }
          }
        } else if (createType == "open" || createType == "completed") {
          // ✅ If workOrderIds is null or empty, fetch them
          List<int>? effectiveWorkOrderIds = workOrderIds;
          if (effectiveWorkOrderIds == null || effectiveWorkOrderIds.isEmpty) {
            effectiveWorkOrderIds = await getMyAssignedWorkOrderIds();
          }

          // ✅ Filter by work order IDs OR team IDs (show both personal and team work orders)
          if (effectiveWorkOrderIds.isNotEmpty && effectiveTeamIds.isNotEmpty) {
            // Use _or to combine: work orders where user is assigned OR team is assigned
            body["filter[_or][0][id][_in]"] = effectiveWorkOrderIds;
            body["filter[_or][1][assigned_team][_in]"] = effectiveTeamIds;
          } else if (effectiveWorkOrderIds.isNotEmpty) {
            // Only user assignments
            body["filter[id][_in]"] = effectiveWorkOrderIds;
          } else if (effectiveTeamIds.isNotEmpty) {
            // Only team assignments
            body["filter[assigned_team][_in]"] = effectiveTeamIds;
          } else {
            // no teams or work orders - return none
            body["filter[assigned_team][_in]"] = [0];
          }
        }
      } else {
        // Default team filter
        if (effectiveTeamIds.isNotEmpty) {
          body["filter[assigned_team][_in]"] = effectiveTeamIds;
        }
      }


      // logger.d("🔹 Final API Request Body: $body");

      // Make API call
      final response = await ApiBaseHelper.getApi(
        url: workUrl,
        useAuthToken: true,
        params: body,
      );
      // logger.d("🔹 Final API response response: $response");


      // ✅ Deduplicate response data by id (_or filter may return duplicates)
      if (response['data'] is List) {
        final List rawList = response['data'] as List;
        final seen = <dynamic>{};
        final deduped = rawList.where((item) {
          if (item is Map) {
            final id = item['id'];
            return seen.add(id);
          }
          return true;
        }).toList();
        // logger.d("🔹 Deduplicated API response data count: ${seen}");
        response['data'] = deduped;
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error in getWorks: ${error.toString()}");
      }

      if (error is DioException) {
        if (kDebugMode) {
          logger.d("❌ DioException type: ${error.type}");
        }

        // ✅ Handle 403 Forbidden
        if (error.response?.statusCode == 403) {
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

  Future<Map<String, dynamic>> getWorksFav({
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
        url: workUrl,
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

  Future<Map<String, dynamic>> updateWork({
    required int id,
    required String title,
    required int statusId,
    required int priorityId,
    required String startDate,
    required String endDate,
    required String desc,
    required String taskAccess,
    required String note,
    required String budget,
    required List<int> userId,
    required List<int> clientId,
    List<int>? assetId,
    required List<int> tagId,
    required int canClientDiscuss,
    required int enable,
    required Map<String, dynamic>? customFieldValues, // Nullable parameter
  }) async {
    try {
      // Safely unwrap and prepare the custom fields

      int team_id = userId[0] ?? 0;
      int asset = assetId?[0] ?? 0;

      // Construct the request body
      Map<String, dynamic> body = {
        "id": id,
        "name": title,
        "wo_status": statusId,
        "priority": priorityId,
        "started_at": startDate,
        "due": endDate,
        "history_description": desc,
        "budget": budget,
        "safety_notes": note,
        "assigned_team": team_id,
        "asset": asset,
        // "task_accessibility": taskAccess,
        // "user_id": userId,
        // "client_id": clientId,
        // "tag_ids": tagId,
      };

      // Make the API request
      final response = await ApiBaseHelper.patch(
        url: "$updateWorkUrl/$id",
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

  Future<Map<String, dynamic>> createWork(
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
        url: createWorkUrl,
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

  Future<Map<String, dynamic>> getDeleteWork({
    required String id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.delete(
          url: "$deleteWorkUrl/$id", useAuthToken: true, body: {});

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<void> updateWorkActionStatus({
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
        url: "$updateWorkUrl/$id",
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

  // ✅ NEW: Update work assignment with action_status and assigned_to
  Future<void> updateWorkAssignment({
    required int id,
    required int actionStatus,
    required String assignedTo,
  }) async {
    try {
      Map<String, dynamic> body = {
        "action_status": actionStatus,
        "assigned_to": assignedTo,
      };

      // Make the API request
      final response = await ApiBaseHelper.patch(
        url: "$updateWorkUrl/$id",
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        logger.d('❌ Error updating work assignment: $e');
      }
      rethrow;
    }
  }

// ✅ NEW: Create Work Order Actions
  Future<Map<String, dynamic>> createWorkOrderActions({
    required int woId,
    required String firstUser,
    required int actionStatus,
    required String type,
    String? nextUser,
  }) async {
    try {
      Map<String, dynamic> body = {
        "wo_id": woId,
        "first_user": firstUser,
        "action_status": actionStatus,
        "type": type,
      };

      if (nextUser != null) {
        body["next_user"] = nextUser;
      }

      final response = await ApiBaseHelper.post(
        url: baseUrl + 'items/Work_order_actions',
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error creating Work_order_actions: ${error.toString()}");
      }
      return {
        'errors': [
          {'message': error.toString()}
        ]
      };
    }
  }

// ✅ NEW: Create Work Order Item
  Future<Map<String, dynamic>> createWorkOrderItem({
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
        url: baseUrl + 'items/Work_order_item',
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error creating Work_order_item: ${error.toString()}");
      }
      return {
        'errors': [
          {'message': error.toString()}
        ]
      };
    }
  }

  //Part
  Future<Map<String, dynamic>> getWorksPart({
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
        body["filter[status][_eq]"] = '1';
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
        logger.d("❌ getWorksPart Error: ${error.toString()}");
      }

      // ✅ Better error handling
      if (error is DioException) {
        if (kDebugMode) {
          logger.d("❌ DioException type: ${error.type}");
        }

        // Return more specific error
        throw Exception(
            'API Error ${error.response?.statusCode}: ${error.response?.data}');
      }

      throw Exception('Error fetching work parts: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateWorkPart(
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

  Future<Map<String, dynamic>> createWorkPart(
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

  Future<Map<String, dynamic>> getDeleteWorkPart({
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
  Future<Map<String, dynamic>> getWorksTrade({
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
        body["filter[status][_eq]"] = '1';
      }

      // ✅ Search in parts name or description
      if (search != null && search.isNotEmpty) {
        body["filter[_or][0][trade][name][_icontains]"] = search;
        body["filter[_or][1][trade][description][_icontains]"] = search;
      }

      // ✅ Date filters
      if (dateBetweenFrom != null && dateBetweenFrom.isNotEmpty) {
        body["filter[created_at][_gte]"] = dateBetweenFrom;
      }
      if (dateBetweenTo != null && dateBetweenTo.isNotEmpty) {
        body["filter[created_at][_lte]"] = dateBetweenTo;
      }

      // ✅ Include nested trade fields
      body["fields"] = "*, trade.*";

      // ✅ Sort by date created descending
      body["sort"] = "-created_at";

      // Make API call
      final response = await ApiBaseHelper.getApi(
        url: workTradeUrl,
        useAuthToken: true,
        params: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ getWorksTrade Error: ${error.toString()}");
      }

      // ✅ Better error handling
      if (error is DioException) {
        if (kDebugMode) {
          logger.d("❌ DioException type: ${error.type}");
        }

        // Return more specific error
        throw Exception(
            'API Error ${error.response?.statusCode}: ${error.response?.data}');
      }

      throw Exception('Error fetching work trade: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateWorkTrade(
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
        logger.d("❌ updateWorkTrade Error: ${error.toString()}");
      }
      throw Exception('Error updating work trade: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> createWorkTrade(
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
        logger.d("❌ createWorkTrade Error: ${error.toString()}");
      }
      throw Exception('Error creating work trade: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> getDeleteWorkTrade({
    required String id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.delete(
          url: "$workTradeUrl/$id", useAuthToken: true, body: {});

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ getDeleteWorkTrade Error: ${error.toString()}");
      }
      throw Exception('Error deleting work trade: ${error.toString()}');
    }
  }

// Milestone
  Future<Map<String, dynamic>> getWorksMilestone({
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

  Future<Map<String, dynamic>> updateWorkMilestone(
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
          url: updateWorkMilestoneUrl, useAuthToken: true, body: body);

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception(error.toString());
    }
  }

  Future<Map<String, dynamic>> createWorkMilestone(
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
        url: createWorkMilestoneUrl,
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

  Future<Map<String, dynamic>> getDeleteWorkMilestone({
    required String id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.delete(
          url: "$deleteWorkMilestoneUrl/$id", useAuthToken: true, body: {});

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> getWorkMedia({
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
        url: workMediaUrl,
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

  Future<Map<String, dynamic>> getWorkMindMap({
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

  Future<Map<String, dynamic>> getWorkTimeLineStatus({
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

  Future<Map<String, dynamic>> getDeleteWorkMedia({
    required String id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.delete(
          url: "$deleteWorkMediaUrl/$id", useAuthToken: true, body: {});

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> uploadWorkMedia({
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
          url: uploadWorkMediaUrl, // Directus files endpoint
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
          url: workMediaUrl,
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

  Future<Map<String, dynamic>> updateWorkPinned({
    required int id,
    required int isPinned,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "is_pinned": isPinned,
      };

      final response = await ApiBaseHelper.patch(
        url: "$updatePinnedWorkUrl/$id/pinned",
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

  Future<Map<String, dynamic>> updateWorkFavorite({
    required int id,
    required int isFavorite,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "is_favorite": isFavorite,
      };

      final response = await ApiBaseHelper.patch(
        url: "$updatePinnedWorkUrl/$id/favorite",
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

  // ✅ Update work order percent
  Future<Map<String, dynamic>> updateWorkOrderPercent({
    required int workOrderId,
    required String woPercent,
  }) async {
    try {
      Map<String, dynamic> body = {
        "wo_percent": woPercent,
      };

      final response = await ApiBaseHelper.patch(
        url: "$workUrl/$workOrderId",
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

  Future<Map<String, dynamic>> addUsersToWorkOrder({
    required int workOrderId,
    required List<dynamic> userIds,
  }) async {
    try {
      List<Map<String, dynamic>> responses = [];
      List<String> errors = [];

      // Send individual request for each userId
      for (var userId in userIds) {
        try {
          Map<String, dynamic> body = {
            "work_order": workOrderId,
            "user_id": userId,
          };

          final response = await ApiBaseHelper.post(
            url: addUsersToWork,
            useAuthToken: true,
            body: body,
          );

          responses.add(response);
        } catch (error) {
          if (kDebugMode) {
            logger.d("❌ Error adding user $userId: ${error.toString()}");
          }
          errors.add("User $userId: ${error.toString()}");
        }
      }

      // Return combined result
      if (errors.isEmpty) {
        return {
          'error': false,
          'message': 'All users added successfully',
          'data': responses,
        };
      } else {
        return {
          'error': true,
          'message': 'Some users failed to add',
          'errors': errors,
          'data': responses,
        };
      }
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error adding users to work order: ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  // ✅ Get work order IDs where current user is assigned
  Future<List<int>> getMyAssignedWorkOrderIds() async {
    try {
      int myIntId = await HiveStorage.getUserId();
      String myUuid = UserIdMapper().convertIntsToUuids([myIntId]).first;

      Map<String, dynamic> params = {
        "fields": "work_order",
        "filter[user_id][_eq]": myUuid,
      };

      final response = await ApiBaseHelper.getApi(
        url: getUsersToWork,
        useAuthToken: true,
        params: params,
      );

      if (response['data'] != null && response['data'] is List) {
        final List<int> workOrderIds = (response['data'] as List)
            .map((item) => item['work_order'] as int)
            .where((id) => id != null)
            .toList();

        return workOrderIds;
      }

      return [];
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error getting assigned work order IDs: ${error.toString()}");
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> getUsersToWorkOrder(
      {required int workOrderId}) async {
    try {
      Map<String, dynamic> params = {
        "fields":
            "*, user_id.first_name, user_id.last_name, user_id.email, user_id.avatar, user_id.id",
        "filter[work_order][_eq]": workOrderId,
      };

      final response = await ApiBaseHelper.getApi(
        url: getUsersToWork,
        useAuthToken: true,
        params: params,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error getting users to work order: ${error.toString()}");
      }
      return {
        'error': true,
        'message': 'Error occurred: ${error.toString()}',
        'data': [],
      };
    }
  }

  Future<Map<String, dynamic>> getTeamLeader(
      {List<dynamic>? users_id, int? teams_id}) async {
    try {
      Map<String, dynamic> params = {
        "fields": "*",
        "filter[directus_users_id][_in]": users_id,
        "filter[Teams_id][_eq]": teams_id,
      };

      final response = await ApiBaseHelper.getApi(
        url: getTeamLeaderUrl,
        useAuthToken: true,
        params: params,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error getting team leaders: ${error.toString()}");
      }

      return {
        'error': true,
        'message': 'Error occurred: ${error.toString()}',
        'data': [],
        'permission_error':
            error is DioException && error.response?.statusCode == 403,
      };
    }
  }

  // ✅ Update work order status
  Future<Map<String, dynamic>> updateWorkOrderStatus({
    required int workOrderId,
    required int statusId,
  }) async {
    try {
      Map<String, dynamic> body = {
        "wo_status": statusId,
      };

      final response = await ApiBaseHelper.patch(
        url: "$workUrl/$workOrderId",
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error updating work order status: ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  // ✅ Get teams for work order
  Future<Map<String, dynamic>> getTeamsForWorkOrder({
    required int workOrderId,
  }) async {
    try {
      // Fetch work order to get its teams
      Map<String, dynamic> params = {
        "fields": "teams.id, teams.name, teams.email, teams.avatar",
        "filter[id][_eq]": workOrderId,
      };

      final response = await ApiBaseHelper.getApi(
        url: workUrl,
        useAuthToken: true,
        params: params,
      );

      // Extract teams from work order response
      if (response['data'] != null && response['data'] is List) {
        final workOrders = response['data'] as List;
        if (workOrders.isNotEmpty) {
          final workOrder = workOrders[0];
          final teams = workOrder['teams'] ?? [];

          return {
            'error': false,
            'data': teams,
          };
        }
      }

      return {
        'error': false,
        'data': [],
      };
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error getting teams for work order: ${error.toString()}");
      }
      return {
        'error': true,
        'message': 'Error occurred: ${error.toString()}',
        'data': [],
      };
    }
  }

  // ✅ Remove user from work order
  Future<Map<String, dynamic>> removeUserFromWorkOrder({
    required int workOrderId,
    required String userId,
  }) async {
    try {
      // Find the Work_order_task_users record to delete
      Map<String, dynamic> params = {
        "filter[work_order][_eq]": workOrderId,
        "filter[user_id][_eq]": userId,
      };

      final response = await ApiBaseHelper.getApi(
        url: getUsersToWork,
        useAuthToken: true,
        params: params,
      );

      if (response['data'] != null && response['data'] is List) {
        final records = response['data'] as List;
        if (records.isNotEmpty) {
          final recordId = records[0]['id'];

          // Delete the record
          final deleteResponse = await ApiBaseHelper.delete(
            url: "$getUsersToWork/$recordId",
            useAuthToken: true,
            body: {},
          );

          return deleteResponse;
        }
      }

      return {
        'error': false,
        'message': 'User not found in work order',
      };
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error removing user from work order: ${error.toString()}");
      }
      return {
        'error': true,
        'message': 'Error occurred: ${error.toString()}',
      };
    }
  }
}
