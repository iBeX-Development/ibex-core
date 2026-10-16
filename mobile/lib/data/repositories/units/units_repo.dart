import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:ibex/config/end_points.dart';
import '../../../api_helper/api_base_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class UnitsRepo {
  Future<Map<String, dynamic>> createUnit({
    required String title,
    required String desc,
    required bool token,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        "title": title,
        "description": desc,
      });
      final response = await ApiBaseHelper.formPost(
        url: createUnitUrl,
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

  Future<Map<String, dynamic>> UnitList({
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
      final response = await ApiBaseHelper.getApi(
        url: unitUrl,
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

  Future<Map<String, dynamic>> deleteUnit({
    required int id,
    required bool token,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("rftgyhujikl Id $id");
      }
      final response = await ApiBaseHelper.deleteApi(
        url: "$deleteUnitUrl/$id",
        useAuthToken: true,
        body: {},
      );

      // for (var row in rows) {
      //   Units.add(UnitsModel.fromJson(row as Map<String, dynamic>));
      // }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updateUnit({
    required int id,
    required String title,
    required String desc,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "title": title,
        "description": desc,
      };
      final response = await ApiBaseHelper.post(
        url: updateUnitUrl,
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
