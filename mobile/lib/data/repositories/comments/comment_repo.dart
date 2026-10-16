import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ibex/config/end_points.dart';
import '../../../api_helper/api_base_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class DiscussionRepo {
  Future<Map<String, dynamic>> createDiscussion({
    required String modelType,
    required int modelId,
    required String content,
    int? work_order,
    String? parentId,
    String? model,
    bool? isProject, // Change to nullable to handle empty case
    List<File>? media,
  }) async {
    try {
      // Only include non-empty fields in FormData
      final formData = FormData.fromMap({
        "model_type": modelType,
        "model_id": modelId.toString(),
        "content": content,
        if (parentId != null && parentId.isNotEmpty) "parent_id": parentId,
      });

      final payloaData = {
        "model_type": modelType,
        "model": model,
        "model_id": modelId.toString(),
        "content": content,
        "status": 1,
        "text": content,
        "work_order": work_order,
        if (parentId != null && parentId.isNotEmpty) "parent_id": parentId,
      };

      // Only add media files if the media list is not empty
      if (media != null && media.isNotEmpty) {
        List<MultipartFile> mediaFiles = await Future.wait(
          media.map(
            (file) async => await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
        // Add each file individually with the key "attachments[]"
        for (var file in mediaFiles) {
          formData.files.add(MapEntry("attachments[]", file));
        }
      }
      // print("payloaData Fields:$payloaData");
      // formData.fields.forEach((entry) {
      //   print("${entry.key}: ${entry.value}");
      // });
      String url = "$createDiscussionUrl/$modelId/comments";

      if (model == 'inspectioncomment') {
        url = "$inspectionComments";
      } else if (model == 'workcomment') {
        url = "$workComments";
      } else if (isProject == false) {
        url = "$createTasksDiscussionUrl/$modelId/comments";
      }

      final response = await ApiBaseHelper.post(
        url: url,
        useAuthToken: true,
        body: payloaData,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred: $error');
    }
  }

  Future<Map<String, dynamic>> DiscussionList({
    int? id,
    int? work_order,
    int? limit,
    int? offset,
    String? search = "",
    String? model = "",
    String? filter = "",
    bool? isProject,
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

      String url = "$getDiscussionUrl/$id/comments/list";
      if (isProject == true) {
        url = "$getDiscussionUrl/$id/comments/list";
      } else if (model == 'projecttaskcomment') {
        url = "$getTaskDiscussionUrl/$id/comments/list";
      } else if (model == 'workcomment') {
        url = "$workComments";
      } else if (model == 'inspectioncomment') {
        url = "$inspectionComments";
        body["fields"] =
            '*,user_created.id,user_created.first_name,user_created.last_name, user_created.email,user_created.avatar.*, user_created.role.id, user_created.role.name';
        body["sort[]"] = 'id';
        body["filter[status]"] = 1;
        body["filter[work_order]"] = work_order;
      }

      // print("Comment_List Body: $body");
      // print("Comment_List URl: $url");
      final response = await ApiBaseHelper.getApi(
        url: url,
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

  Future<Map<String, dynamic>> updateDiscussion({
    required int DiscussionId,
    required String content,
    bool? isProject,
  }) async {
    // print("rftyhuik $DiscussionId");
    try {
      FormData formData = FormData.fromMap({
        "comment_id": DiscussionId,
        "content": content,
      });
      String url = isProject == true
          ? "$updateDiscussionUrl"
          : "$updateTasksDiscussionUrl";

      // Send the request using ApiBaseHelper (assumes Dio under the hood)
      final response = await ApiBaseHelper.formPost(
        url: url,
        useAuthToken: true,
        body: formData,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d(" Error in updateDiscussion: ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> deleteComment({
    required String CommentId,
    required bool token,
    bool? isProject,
    String? model,
  }) async {
    try {
      // For inspection comments, use PATCH to set status to 0 instead of DELETE
      if (model == 'inspectioncomment') {
        String url = "$inspectionComments/$CommentId";

        final response = await ApiBaseHelper.patch(
          url: url,
          useAuthToken: true,
          body: {"status": 0},
        );

        if (response['status_code'] == 401) {
          return response;
        }
        return response;
      }

      // For other types, use the original DELETE method
      String url = isProject == true
          ? "$deleteDiscussionUrl?comment_id=$CommentId"
          : "$deleteTasksDiscussionUrl?comment_id=$CommentId";

      final response = await ApiBaseHelper.deleteApi(
        url: url,
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

  Future<Map<String, dynamic>> deleteCommentAttachment({
    required String id,
    required bool token,
    bool? isProject,
  }) async {
    try {
      String url = isProject == true
          ? "$deleteDiscussionAttachmentUrl/$id"
          : "$deleteTasksDiscussionAttachmentUrl/$id";

      final response = await ApiBaseHelper.deleteApi(
        url: url,
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
