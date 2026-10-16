import 'package:flutter/foundation.dart';
import 'package:ibex/config/end_points.dart';
import '../../../api_helper/api_base_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class TagRepo {
  Future<Map<String, dynamic>> getTags({
    int? offset,
    int? limit,
    String? search,
    required bool token,
  }) async {
    try {
      Map<String, dynamic> body = {"limit": limit, "offset": offset};
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
        logger.d("USER REPO ");
      }
      final response = await ApiBaseHelper.getApi(
        url: getTagUrl,
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

  Future<Map<String, dynamic>> createTags({
    required String title,
    required String color,
  }) async {
    try {
      Map<String, dynamic> body = {"title": title, "color": color};
      if (kDebugMode) {
        logger.d("tghyjkl,");
      }
      if (kDebugMode) {
        logger.d("tghyjkl, $body");
      }
      final response = await ApiBaseHelper.post(
        url: createTagUrl,
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

  Future<Map<String, dynamic>> deleteTags({
    required int id,
    required bool token,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("rftgyhujikl Id $id");
      }
      final response = await ApiBaseHelper.delete(
        url: "$deleteTagUrl/$id",
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

  Future<Map<String, dynamic>> updateTags({
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
      Map<String, dynamic> body = {"id": id, "title": title, "color": color};
      final response = await ApiBaseHelper.post(
        url: updateTagUrl,
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
