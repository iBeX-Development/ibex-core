import 'package:flutter/foundation.dart';
import 'package:ibex/config/end_points.dart';
import '../../../api_helper/api_base_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ExpenseRepo {
  Future<Map<String, dynamic>> ExpenseList({
    int? limit,
    int? offset,
    String? search = "",
    required List<int> userId,
    required List<int> type,
    required String toDate,
    required String fromDate,
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
      if (type.isNotEmpty) {
        body["type_ids[]"] = type;
      }

      if (userId.isNotEmpty) {
        body["user_ids[]"] = userId;
      }
      if (toDate != "") {
        body["date_to"] = toDate;
      }
      if (fromDate != "" && fromDate != "") {
        body["date_from"] = fromDate;
      }
      final response = await ApiBaseHelper.getApi(
        url: expenseUrl,
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

  Future<Map<String, dynamic>> createExpense({
    required String title,
    required int expenseTypeId,
    required int userId,
    required String amount,
    required String expenseDate,
    required String note,
  }) async {
    try {
      Map<String, dynamic> body = {
        "title": title,
        "expense_type_id": expenseTypeId,
        "amount": amount,
        "expense_date": expenseDate,
        "note": note,
        "user_id": userId,
      };
      if (kDebugMode) {
        logger.d("tghyjkl,");
      }
      if (kDebugMode) {
        logger.d("tghyjkl, $body");
      }
      final response = await ApiBaseHelper.post(
        url: createExpenseUrl,
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

  Future<Map<String, dynamic>> deleteExpense({
    required int id,
    required bool token,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("rftgyhujikl Id $id");
      }
      final response = await ApiBaseHelper.delete(
        url: "$deleteExpenseUrl/$id",
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

  Future<Map<String, dynamic>> updateExpense({
    required int id,
    required String title,
    required int expenseTypeId,
    required int userId,
    required String amount,
    required String expenseDate,
    required String note,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "title": title,
        "expense_type_id": expenseTypeId,
        "amount": amount,
        "expense_date": expenseDate,
        "note": note,
        "user_id": userId,
      };
      final response = await ApiBaseHelper.post(
        url: updateExpenseUrl,
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
