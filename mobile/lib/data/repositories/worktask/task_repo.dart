import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkTaskRepo {
  Future<Map<String, dynamic>> createTask(
      {required String title,
      int? statusId,
      int? parentId,
      bool? subtask,
      int? priorityId,
      int? canClientDiscuss,
      String? startDate,
      String? dueDate,
      String? desc,
      int? project,
      String? note,
      String? billingType,
      int? completionPercentage,
      String? enableReminder,
      String? enableRecurringTask,
      String? taskValue,
      String? template_type,
      int? dayOfWeek,
      int? dayOfMonth,
      String? timeOfDay,
      String? recurrenceFrequency,
      int? recurrenceDayOfWeek,
      int? recurrenceDayOfMonth,
      int? recurrenceMonthOfYear,
      String? recurrrenceStartsFrom,
      String? frequencyType,
      String? recurrringFrequenctType,
      int? recurenceOccurences,
      List<int>? userId,
      String? search}) async {
    try {
      // Optional: Print for debugging
      int templateType = 5;
      if (template_type == 'Check') {
        templateType = 5;
      } else if (template_type == 'Input') {
        templateType = 7;
      }

      Map<String, dynamic> body = {
        "name": title,
        "wo_status": statusId,
        "priority_id": priorityId,
        "start_date": startDate,
        "due_date": dueDate,
        "template_type": templateType,
        "value": taskValue,
        "description": desc,
        "active": 1,
        "workorder": project,
        "note": note,
        "created_type": billingType == "" ? "user" : billingType,
      };

      if (subtask == true && parentId != null && parentId != 0) {
        body["parent_id"] = parentId;
      }
      if (search != null) {
        body["search"] = search;
      }

      // print("Create Task_Body: $body");
      final response = await ApiBaseHelper.post(
        url: createTaskUrl,
        useAuthToken: true,
        body: body,
      );
      // print("sedfghjnkm${response['data']}");
      // rows = response['data'] as List<dynamic>;
      // for (var row in rows) {
      //   task.add(CreateTaskModel.fromJson(row as Map<String, dynamic>));
      // }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> getTask(
      {int? offset,
      int? limit,
      required bool token,
      String? search,
      List<int>? userId,
      List<int>? projectId,
      List<int>? clientId,
      List<int>? priorityId,
      List<int>? statusId,
      String? toDate,
      String? fromDate,
      int? id,
      bool? subtask,
      bool includeChildren = true, // ← Шинэ parameter нэмэх

      int? isFav}) async {
    try {
      Map<String, dynamic> body = {};

      // print("iD $fromDate");
      // print("iD $toDate");
      // print("iD $statusId");
      // print("iD $clientId");
      // print("iD $projectId");
      // print("iD $userId");
      // print("iD priorityId $priorityId");
      // print("iD $search");
      // print("iD $token");
      // print("subtask $subtask");
      if (kDebugMode) {
        logger.d("iD drgty $id");
      }
      // Adding data to the body only if it's not null
      if (subtask == true && id != null) {
        body["filter[parent][_eq]"] = id;
      }

      if (search?.isNotEmpty ?? false) {
        body["search"] = search;
      }
      if (limit != null) {
        body["limit"] = limit;
      }
      if (isFav != null) {
        body["is_favorites"] = isFav;
      }
      if (offset != null) {
        body["offset"] = offset;
      }
      if (userId != null && userId.isNotEmpty) {
        body["user_ids[]"] = userId;
      }
      if (clientId != null && clientId.isNotEmpty) {
        body["client_ids[]"] = clientId;
      }
      if (projectId != null && projectId.isNotEmpty) {
        body["filter[workorder][_in]"] = projectId;
        body["filter[active][_in]"] = [1]; // Only active tasks

        body["sort[]"] = 'pos';
      }

      if (statusId != null && statusId.isNotEmpty) {
        body["status_ids[]"] = statusId;
      }
      if (priorityId != null && priorityId.isNotEmpty) {
        body["priority_ids[]"] = priorityId;
      }
      if (toDate?.isNotEmpty ?? false) {
        body["task_end_date_to"] = toDate;
      }
      if (fromDate?.isNotEmpty ?? false) {
        body["task_start_date_from"] = fromDate;
      }
      // print("BODY TASK $body");
      // Making the API request with the parameters that are available
      Map<String, dynamic> response = {};
      if (subtask == true && id != null) {
        body["filter[parent][_eq]"] = id;

        // print("fsrjn kgfmvc,  $subtask}");
        // Handle case where there's no specific ID
        response = await ApiBaseHelper.getApi(
          url: getAllTaskUrl,
          useAuthToken: true,
          params: body,
        );
      } else if (id != null) {
        body["id"] = id;

        response = await ApiBaseHelper.getApi(
          url: "$getAllTaskUrl/$id",
          useAuthToken: true,
          params: body,
        );
        // ✅ Нэг task ирсэн бол List болгож буцаах
        if (response['data'] is Map) {
          response['data'] = [response['data']];
        }
      } else {
        if (kDebugMode) {
          logger.d("no_id");
        }

        // Handle case where there's no specific ID
        response = await ApiBaseHelper.getApi(
          url: getAllTaskUrl,
          useAuthToken: true,
          params: body,
        );
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error fetching work tasks: ${error.toString()}");
      }

      if (error is DioException) {
        if (kDebugMode) {
          logger.d("❌ DioException type: ${error.type}");
        }
      }

      return {
        'errors': [
          {'message': error.toString()}
        ]
      };
    }
  }

  Future<Map<String, dynamic>> getTasksFav({
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

      // Make API call based on whether an id is provided
      final response = await ApiBaseHelper.getApi(
        url: getAllTaskUrl,
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

  Future<Map<String, dynamic>> getDeleteTask({
    required String id,
    required bool token,
  }) async {
    // Map<String, dynamic> rows;

    try {
      final response = await ApiBaseHelper.patch(
          url: "$deleteTask/$id", useAuthToken: true, body: {"active": 0});

      // rows = response as Map<String, dynamic>;
      // for (var row in rows) {
      //   Todos.add(TodosModel.fromJson(row as Map<String, dynamic>));
      // }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updateTask({
    required int id,
    required String title,
    int? statusId,
    int? priorityId,
    int? canClientDiscuss,
    String? startDate,
    String? desc,
    String? note,
    String? billingType,
    int? completionPercentage,
    required String enableReminder,
    String? dueDate,
    String? taskValue,
    String? frequencyType,
    String? template_type,
    String? recurrringFrequenctType,
    required String enableRecurringTask,
    List<int>? userId,
    int? dayOfWeek,
    int? dayOfMonth,
    int? parentId,
    bool? subtask,
    String? timeOfDay,
    String? recurrenceFrequency,
    int? recurrenceDayOfWeek,
    int? recurrenceDayOfMonth,
    int? recurrenceMonthOfYear,
    String? recurrrenceStartsFrom,
    int? recurenceOccurences,
  }) async {
    try {
      // Optional: Print for debugging
      Map<String, dynamic> body = {};

      if (id != "") body["id"] = id;
      if (title != "") body["name"] = title;
      if (statusId != "") body["status_id"] = statusId;
      if (priorityId != "") body["priority_id"] = priorityId;
      if (startDate != "") body["start_date"] = startDate;
      if (dueDate != "") body["due_date"] = dueDate;
      if (desc != "") body["description"] = desc;
      if (taskValue != "") body["value"] = taskValue;

      if (canClientDiscuss != "") body["canClientDiscuss"] = canClientDiscuss;
      if (note != "") body["note"] = note;
      if (billingType != "") body["billing_type"] = billingType;
      if (completionPercentage != "")
        body["completion_percentage"] = completionPercentage;
      if (userId != "") body["user_id"] = userId;
      if (dayOfWeek != "") body["day_of_week"] = dayOfWeek;
      if (dayOfMonth != "") body["day_of_month"] = dayOfMonth;
      if (timeOfDay != "") body["time_of_day"] = timeOfDay;
      if (recurrenceFrequency != null)
        body["recurrence_frequency"] = recurrenceFrequency.toLowerCase();
      if (frequencyType != null)
        body["frequency_type"] = frequencyType.toLowerCase();
      if (template_type != null) {
        if (template_type.toLowerCase() == 'check')
          body["template_type"] = 5; //static-aar
        else
          body["template_type"] = 7; //static-aar
      } else {
        body["template_type"] = 5;
      }
      if (recurrenceDayOfWeek != null)
        body["recurrence_day_of_week"] = recurrenceDayOfWeek;
      if (recurrenceDayOfMonth != null)
        body["recurrence_day_of_month"] = recurrenceDayOfMonth;
      if (recurrenceDayOfWeek != null)
        body["recurrence_month_of_year"] =
            recurrenceDayOfWeek; // double-check this
      if (recurrrenceStartsFrom != null)
        body["recurrence_starts_from"] = recurrrenceStartsFrom;
      if (recurenceOccurences != null)
        body["recurrence_occurrences"] = recurenceOccurences;
      // Conditionally add these fields only if they are not "off"
      if (enableReminder.toLowerCase() != "off") {
        body["enable_reminder"] = enableReminder;
      }
      if (subtask == true && parentId != null) {
        body["parent_id"] = parentId;
      }
      if (enableRecurringTask.toLowerCase() != "off") {
        body["enable_recurring_task"] = enableRecurringTask;
      }

      final response = await ApiBaseHelper.patch(
          url: "$updateTaskUrl/$id", useAuthToken: true, body: body);

      // rows = response['data']['data'] as Map<String, dynamic>;

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updateTaskPinned({
    required int id,
    required int isPinned,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "is_pinned": isPinned,
      };

      final response = await ApiBaseHelper.patch(
        url: "$getAllTaskUrl/$id/pinned",
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

  Future<Map<String, dynamic>> updateTaskFavorite({
    required int id,
    required int isFavorite,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("u gkujg 4=$isFavorite");
      }
      Map<String, dynamic> body = {
        "id": id,
        "is_favorite": isFavorite,
      };

      final response = await ApiBaseHelper.patch(
        url: "$getAllTaskUrl/$id/favorite",
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

  Future<Map<String, dynamic>> getTaskMedia({
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
        url: "$taskMediaUrl/$id",
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

  Future<Map<String, dynamic>> getTaskTimeLineStatus({
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
        url: "$taskTimelineStatusUrl$id/status-timelines",
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

  Future<Map<String, dynamic>> getDeleteTaskMedia({
    bool? token,
    required String id,
    // required int id,
  }) async {
    try {
      final response = await ApiBaseHelper.delete(
          url: "$deleteTaskMediaUrl/$id", useAuthToken: true, body: {});

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> uploadTaskMedia({
    required int id,
    required List<File> media,
  }) async {
    try {
      // Convert List<File> into List<MultipartFile>
      List<MultipartFile> mediaFiles = await Future.wait(
        media.map(
          (file) async => await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );
      mediaFiles.asMap().forEach((index, file) {
        if (kDebugMode) {
          logger.d('File $index:');
        }
        if (kDebugMode) {
          logger.d('  - Length: ${file.length}');
        }
        if (kDebugMode) {
          logger.d('  - Filename: ${file.filename}');
        }
      });

      FormData formData = FormData.fromMap({
        "id": id.toString(),
        "media_files[]": mediaFiles,
      });

      // Make API call
      final response = await ApiBaseHelper.postMedia(
        url: "$uploadTaskMediaUrl",
        useAuthToken: true,
        formData: formData,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  // ✅ Update task completion/value
  Future<Map<String, dynamic>> updateTaskCompletion({
    required int taskId,
    required String value,
  }) async {
    try {
      Map<String, dynamic> body = {
        "value": value,
      };

      final response = await ApiBaseHelper.patch(
        url: "$getAllTaskUrl/$taskId",
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error updating task completion: ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
}
