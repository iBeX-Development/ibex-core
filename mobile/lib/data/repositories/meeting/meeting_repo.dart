import 'package:flutter/foundation.dart';
import 'package:ibex/config/end_points.dart';
import '../../../api_helper/api_base_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class MeetingRepo {
  Future<Map<String, dynamic>> meetingList({
    int? limit,
    int? offset,
    String? search = "",
  }) async {
    try {
      if (kDebugMode) {
        logger.d("dfgvhbjkm,l");
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
      final response = await ApiBaseHelper.getApi(
        url: listMeetingUrl,
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

  Future<Map<String, dynamic>> createMeeting({
    required String title,
    required String startDate,
    required String endDate,
    required String startTime,
    required String endTime,
    required List<int> userId,
    required List<int> clientIds,
    required bool token,
  }) async {
    try {
      Map<String, dynamic> body = {
        "title": title,
        "start_date": startDate,
        "end_date": endDate,
        "start_time": startTime,
        "end_time": endTime,
        "user_ids": userId,
        "client_ids": clientIds,
      };
      if (kDebugMode) {
        logger.d("tghyjkl,");
      }
      if (kDebugMode) {
        logger.d("tghyjkl, $body");
      }
      final response = await ApiBaseHelper.post(
        url: createMeetingUrl,
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

  Future<Map<String, dynamic>> deleteMeeting({
    required int id,
    required bool token,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("rftgyhujikl Id $id");
      }
      final response = await ApiBaseHelper.delete(
        url: "$deleteMeetingUrl/$id",
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

  Future<Map<String, dynamic>> updateMeeting({
    required int id,
    required String title,
    required String startDate,
    required String endDate,
    required String startTime,
    required String endTime,
    required List<int> userId,
    required List<int> clientIds,
    required bool token,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "title": title,
        "start_date": startDate,
        "end_date": endDate,
        "start_time": startTime,
        "end_time": endTime,
        "user_ids": userId,
        "client_ids": clientIds,
      };
      final response = await ApiBaseHelper.post(
        url: updateMeetingUrl,
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
