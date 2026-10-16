import 'package:flutter/foundation.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import 'package:logger/logger.dart';


final logger = Logger();

class ExpenseTypeRepo{
  Future<Map<String, dynamic>> getExpenseType(
      {
        int? offset=0,
        int? limit=20,
        String type = "",
        required bool token,
        String? search
      }) async {

    try {

      Map<String, dynamic> body = {
        "type": type,
        "limit": limit,
        "offset": offset
      };
      if(search !=null){
        body["search"] = search;
      }

      final response = await ApiBaseHelper.getApi(
        url: expenseTypeListUrl,
        params: body,
        useAuthToken: true,
      );
      if (kDebugMode) {
        logger.d("Respomse of Expense $response");
      }
      return response;

    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
  Future<Map<String, dynamic>> createExpenseType({
    required String title,
    required String desc,
  }) async {

    try {
      Map<String, dynamic> body = {
        "title": title,
        "description": desc,

      };
      if (kDebugMode) {
        logger.d("tghyjkl,");
      }
      if (kDebugMode) {
        logger.d("tghyjkl, $body");
      }
      final response = await ApiBaseHelper.post(
          url: createExpenseTypeUrl, useAuthToken: true, body: body);
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> deleteExpenseType({
    required int id,
    required bool token,
  }) async {

    try {
      if (kDebugMode) {
        logger.d("rftgyhujikl Id $id");
      }
      final response = await ApiBaseHelper.delete(
          url: "$destroyExpenseTypeUrl/$id", useAuthToken: true, body: {});



      return response as Map<String, dynamic>;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updateExpenseType( {
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
          url: updateExpenseTypeUrl, useAuthToken: true, body: body);
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
}