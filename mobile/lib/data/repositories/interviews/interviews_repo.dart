import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:ibex/config/end_points.dart';
import '../../../api_helper/api_base_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InterviewsRepo {
  Future<Map<String, dynamic>> createInterviews({
    int? candidateId,
    String? candidateName,
    int? interviewerId,
    String? interviewerName,
    String? round,
    String? scheduledAt,
    String? mode,
    String? location,
    String? status,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        if (candidateId != null) 'candidate_id': candidateId,
        if (interviewerId != null) 'interviewer_id': interviewerId,
        if (round != null) 'round': round,
        if (scheduledAt != null) 'scheduled_at': scheduledAt,
        if (mode != null) 'mode': mode,
        if (location != null) 'location': location,
        if (status != null) 'status': status,
      });

      final response = await ApiBaseHelper.formPost(
        url: createInterviewsUrl,
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

  Future<Map<String, dynamic>> InterviewsList({
    int? limit,
    int? offset,
    String? search = "",
    int? id,
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
      if (id != null) {
        body["candidate_id"] = id;
      }
      var url = getInterviewsUrl;
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

  Future<Map<String, dynamic>> deleteInterviews({
    required int id,
    required bool token,
  }) async {
    try {
      final response = await ApiBaseHelper.deleteApi(
        url: "$deleteInterviewsUrl/$id",
        useAuthToken: true,
        body: {},
      );
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updateInterviews({
    required int id,
    int? candidateId,
    String? candidateName,
    int? interviewerId,
    String? interviewerName,
    String? round,
    String? scheduledAt,
    String? mode,
    String? location,
    String? status,
  }) async {
    try {
      if (kDebugMode) {
        logger.d('Updating interview with values:');
      }
      if (kDebugMode) {
        logger.d('id: $id');
      }
      if (kDebugMode) {
        logger.d('candidateId: $candidateId');
      }
      if (kDebugMode) {
        logger.d('candidateName: $candidateName');
      }
      if (kDebugMode) {
        logger.d('interviewerId: $interviewerId');
      }
      if (kDebugMode) {
        logger.d('interviewerName: $interviewerName');
      }
      if (kDebugMode) {
        logger.d('round: $round');
      }
      if (kDebugMode) {
        logger.d('scheduledAt: $scheduledAt');
      }
      if (kDebugMode) {
        logger.d('mode: $mode');
      }
      if (kDebugMode) {
        logger.d('location: $location');
      }
      if (kDebugMode) {
        logger.d('status: $status');
      }

      Map<String, dynamic> body = {
        'id': id,
        if (candidateId != null) 'candidate_id': candidateId,
        if (interviewerId != null) 'interviewer_id': interviewerId,
        if (round != null) 'round': round,
        if (scheduledAt != null) 'scheduled_at': scheduledAt,
        if (mode != null) 'mode': mode,
        if (location != null) 'location': location,
        if (status != null) 'status': status,
      };

      final response = await ApiBaseHelper.post(
        url: "$updateInterviewsUrl/$id",
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
