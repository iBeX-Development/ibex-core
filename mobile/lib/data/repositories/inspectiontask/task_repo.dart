import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionTaskRepo {
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
      String? createType,
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
        "created_type": createType == "" ? "user" : createType,
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
        logger.d("iD inspextion_getTaskId $id");
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
          url: inspectionItem,
          useAuthToken: true,
          params: body,
        );
      } else if (id != null) {
        body["id"] = id;
        // print("gettask_id  $id}");
        // print("gettask_id_body  $id}");

        response = await ApiBaseHelper.getApi(
          url: "$inspectionItem/$id",
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
          url: inspectionItem,
          useAuthToken: true,
          params: body,
        );
      }
      // print("InspectionTaskRepo urls,  $inspectionItem}");

      // print("==InspectionTaskRepo body $body=====");
      // print("==InspectionTaskRepo response $response=====");
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("❌ Error fetching work tasks: ${error.toString()}");
      }

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
          logger.d("❌ Request path: ${error.requestOptions.path}");
        }
        // print("❌ Request headers: ${error.requestOptions.headers}");
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

      // print("Request body: $body");

      // Make API call based on whether an id is provided
      final response = await ApiBaseHelper.getApi(
        url: inspectionItem,
        useAuthToken: true,
        params: body,
      );

      // print("BODY $body RESPONSE PROJECT $response");
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
          url: "$inspectionItem/$id", useAuthToken: true, body: {"active": 0});

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
    String? createType,
    int? completionPercentage,
    String? enableReminder,
    String? dueDate,
    String? taskValue,
    String? frequencyType,
    String? template_type,
    String? recurrringFrequenctType,
    String? enableRecurringTask,
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
    if (kDebugMode) {
      logger.d("_onInspectionUpdateTask $recurrringFrequenctType}");
    }

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

      if (note != "") body["note"] = note;
      if (completionPercentage != "")
        body["completion_percentage"] = completionPercentage;
      if (userId != "") body["user_id"] = userId;
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

      if (subtask == true && parentId != null) {
        body["parent_id"] = parentId;
      }

      if (kDebugMode) {

        logger.d("_onInspectionUpdateTask_action_body $body");

      }

      final response = await ApiBaseHelper.patch(
          url: "$inspectionItem/$id", useAuthToken: true, body: body);

      if (kDebugMode) {

        logger.d("_onInspectionUpdateTask_action_response $response");

      }

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
        url: "$inspectionItem/$id/pinned",
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
        url: "$inspectionItem/$id/favorite",
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

  Future<Map<String, dynamic>> updateTaskCompletion({
    required int taskId,
    required String value,
  }) async {
    try {
      Map<String, dynamic> body = {
        "value": value,
      };

      if (kDebugMode) {

        logger.d("🔥 Updating task $taskId with value: $value");

      }

      final response = await ApiBaseHelper.patch(
        url: "$inspectionItem/$taskId",
        useAuthToken: true,
        body: body,
      );

      if (kDebugMode) {

        logger.d("🔥 Task update response: $response");

      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error updating task completion: ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> getTaskMedia({
    int? id,
    int? limit,
    int? offset,
    String? filter,
    String? search = "",
    String? fields,
  }) async {
    try {
      Map<String, dynamic> body = {};
      if (kDebugMode) {
        logger.d("InspectionTaskMedia_start $inspectionItem");
      }
// Add parameters to the request body, avoiding null values
      if (search?.isNotEmpty ?? false) body["search"] = search;
      if (limit != null) body["limit"] = limit;
      if (offset != null) body["offset"] = offset;
      body['filter[active]'] = 1;
      body['filter[id]'] = '${id}';
      body['fields'] = fields ?? '*, photos.id, photos.directus_files_id.*';

      if (kDebugMode) {

        logger.d("InspectionTaskMedia_body $body");

      }

      final response = await ApiBaseHelper.getApi(
        url: "$inspectionItem",
        useAuthToken: true,
        params: body,
      );

      // print("BODY $body RESPONSE PROJECT $response");
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
        url: "$inspectionTimelineStatusUrl$id/status-timelines",
        useAuthToken: true,
        params: body,
      );

      // print("BODY $body RESPONSE PROJECT $response");
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> getDeleteTaskMedia({
    required int id,
  }) async {
    try {
      if (kDebugMode) {
        logger.d(' Deleting task media with ID: $id');
      }
      final response = await ApiBaseHelper.delete(
          url: "$inspectionItemDeleteTaskMediaUrl/$id",
          useAuthToken: true,
          body: {});

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
      if (kDebugMode) {
        logger.d("fvgNDJGvhn ${mediaFiles.length}");
      }
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
          if (kDebugMode) {
            logger.d('✅ Uploaded file ID: $fileId');
          }
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

      if (kDebugMode) {

        logger.d('✅ Updating Work_inspection_item with photos: $updateBody');

      }

      final response = await ApiBaseHelper.patch(
        url: '$inspectionItem/$id',
        body: updateBody,
        useAuthToken: true,
      );

      logger.d(
          '✅ Updated Work_inspection_item with ${photosCreate.length} photos');

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
}
