import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ibex/config/end_points.dart';
import '../../../api_helper/api_base_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class CandidatesRepo {
  Future<Map<String, dynamic>> createCandidate({
    required String name,
    required String email,
    required String phone,
    required String position,
    required String source,
    required int statusId,
    required List<File> media,
  }) async {
    try {
      List<MultipartFile> mediaFiles = await Future.wait(
        media.map(
          (file) async => await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );
      FormData formData = FormData.fromMap({
        "name": name,
        'email': email,
        "phone": phone,
        "position": position,
        "source": source,
        "status_id": statusId,
        "attachments[]": mediaFiles,
      });
      final response = await ApiBaseHelper.formPost(
        url: createCandidateUrl,
        useAuthToken: true,
        body: formData,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> CandidateList({
    int? id,
    int? limit,
    int? offset,
    String? search = "",
  }) async {
    try {
      if (kDebugMode) {
        logger.d("dfgvhbjkm,lqsa $limit");
      }
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l$offset");
      }
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
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l rt $body");
      }
      final url = id != null
          ? "$getCandidateUrl/$id/upload-attachment"
          : getCandidateUrl;

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

  Future<Map<String, dynamic>> getCandidateInterviewList({int? id}) async {
    try {
      Map<String, dynamic> body = {};

      final url = id != null
          ? "$getCandidateInteviewUrl/$id/interviews?isApi=1"
          : getCandidateUrl;

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

  Future<Map<String, dynamic>> CandidateAttachmentList({
    int? id,
    int? limit,
    int? offset,
    String? search = "",
  }) async {
    try {
      if (kDebugMode) {
        logger.d("dfgvhbjkm,lqsa $limit");
      }
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l$offset");
      }
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
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l rt $body");
      }
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l rt $id");
      }
      final url = id != null
          ? "$getAttachmentCandidateUrl$id/attachments/list"
          : getCandidateUrl;
      if (kDebugMode) {
        logger.d("fvgbhnjk$url");
      }
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

  Future<Map<String, dynamic>> CandidateAttachmentUpload({
    int? id,
    int? limit,
    int? offset,
    String? search = "",
    required List<File> media,
  }) async {
    try {
      // Convert files to MultipartFile list
      List<MultipartFile> mediaFiles = await Future.wait(
        media.map(
          (file) async => await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );

      // Debug each file
      for (var file in mediaFiles) {
        if (kDebugMode) {
          logger.d('Prepared MultipartFile: ${file.filename}');
        }
      }

      // Build form data
      FormData formData = FormData.fromMap({
        if (mediaFiles.isNotEmpty) "attachments[]": mediaFiles,
      });
      final url = id != null
          ? "$getAttachmentCandidateUrl$id/upload-attachment"
          : getCandidateUrl;
      if (kDebugMode) {
        logger.d("fvgbhnjk de $url");
      }
      final response = await ApiBaseHelper.formPost(
        url: url,
        useAuthToken: true,
        body: formData,
      );
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> CandidateInterviewList({
    int? id,
    int? limit,
    int? offset,
    String? search = "",
  }) async {
    try {
      if (kDebugMode) {
        logger.d("dfgvhbjkm,lqsa $limit");
      }
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l$offset");
      }
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
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l rt $body");
      }
      final url = id != null
          ? "${getInterviewCandidateUrl}list$id"
          : getCandidateUrl;

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

  Future<Map<String, dynamic>> deleteCandidate({
    required int id,
    required bool token,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("rftgyhujikl Id $id");
      }
      final response = await ApiBaseHelper.deleteApi(
        url: "$deleteCandidateUrl/$id",
        useAuthToken: true,
        body: {},
      );

      // for (var row in rows) {
      //   Candidates.add(CandidatesModel.fromJson(row as Map<String, dynamic>));
      // }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> deleteCandidateAttachment({
    required int id,
    required bool token,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("rftgyhujikl Id $id");
      }
      final response = await ApiBaseHelper.deleteApi(
        url: "$deleteCandidateAttachmentUrl/$id",
        useAuthToken: true,
        body: {},
      );

      // for (var row in rows) {
      //   Candidates.add(CandidatesModel.fromJson(row as Map<String, dynamic>));
      // }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updateCandidate({
    required int id,
    required String name,
    required String email,
    required String phone,
    required String position,
    required String source,
    required int statusId,
    required List<File> media,
  }) async {
    if (kDebugMode) {
      logger.d("MEDIA (Raw Files): $media");
    }

    try {
      // Convert files to MultipartFile list
      List<MultipartFile> mediaFiles = await Future.wait(
        media.map(
          (file) async => await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );

      // Debug each file
      for (var file in mediaFiles) {
        if (kDebugMode) {
          logger.d('Prepared MultipartFile: ${file.filename}');
        }
      }

      // Build form data
      FormData formData = FormData.fromMap({
        "name": name,
        "email": email,
        "phone": phone,
        "position": position,
        "source": source,
        "status_id": statusId,
        if (mediaFiles.isNotEmpty) "attachments[]": mediaFiles,
      });

      if (kDebugMode) {

        logger.d("Sending to URL: $updateCandidateUrl/$id");

      }

      // Send the request using ApiBaseHelper (assumes Dio under the hood)
      final response = await ApiBaseHelper.formPost(
        url: "$updateCandidateUrl/$id",
        useAuthToken: true,
        body: formData,
      );

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d(" Error in updateCandidate: ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
}
