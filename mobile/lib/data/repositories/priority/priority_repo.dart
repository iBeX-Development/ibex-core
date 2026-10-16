import 'package:flutter/foundation.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import '../../../config/constants.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class PriorityRepo {
  Future<Map<String, dynamic>> getPriorities(
      {int? offset = 0,
      int? limit = 20,
      String type = "",
      required bool token,
      String? search}) async {
    try {
      final response = getContstantPriorities();
      List<Map<String, dynamic>> filtered = response;
      if (search != null && search.isNotEmpty) {
        filtered = filtered
            .where((item) =>
                (item['text'] as String)
                    .toLowerCase()
                    .contains(search.toLowerCase()) ||
                (item['label'] as String)
                    .toLowerCase()
                    .contains(search.toLowerCase()))
            .toList();
      }

      // Pagination
      int start = offset ?? 0;
      int end = (limit != null && (start + limit) < filtered.length)
          ? start + limit
          : filtered.length;
      List<Map<String, dynamic>> paged = filtered.sublist(start, end);

      // Map хэлбэрт оруулж буцаана
      return {
        "data": paged,
        "total": filtered.length,
      };

      // Map<String, dynamic> body = {
      //   "type": type,
      //   "limit": limit,
      //   "offset": offset
      // };
      // if(search !=null){
      //   body["search"] = search;
      // }

      // final response = await ApiBaseHelper.getApi(
      //   url: getPriorityUrl,
      //   params: body,
      //   useAuthToken: true,
      // );
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> createPriority({
    required String title,
    required String color,
  }) async {
    try {
      Map<String, dynamic> body = {
        "title": title,
        "color": color,
      };
      if (kDebugMode) {
        logger.d("tghyjkl,");
      }
      if (kDebugMode) {
        logger.d("tghyjkl, $body");
      }
      final response = await ApiBaseHelper.post(
          url: createPriorityUrl, useAuthToken: true, body: body);
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> deletePriority({
    required int id,
    required bool token,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("rftgyhujikl Id $id");
      }
      final response = await ApiBaseHelper.delete(
          url: "$deletePriorityUrl/$id", useAuthToken: true, body: {});

      return response as Map<String, dynamic>;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updatePriority({
    required int id,
    required String title,
    required String color,
  }) async {
    if (kDebugMode) {
      logger.d("kdfjfkln $id");
    }
    if (kDebugMode) {
      logger.d("kdfjfkln $title");
    }
    if (kDebugMode) {
      logger.d("kdfjfkln $color");
    }

    try {
      Map<String, dynamic> body = {
        "id": id,
        "title": title,
        "color": color,
      };
      final response = await ApiBaseHelper.post(
          url: updatePriorityUrl, useAuthToken: true, body: body);
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
}
