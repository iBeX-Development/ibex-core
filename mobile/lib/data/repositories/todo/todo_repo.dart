import 'package:flutter/foundation.dart';
import 'package:ibex/config/end_points.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../../utils/user_id_mapper.dart';
import '../../localStorage/hive.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class TodosRepo {
  static Future<Map<String, dynamic>> createTodo({
    required String title,
    required String desc,
    required String priority,
    required bool token,
  }) async {
    try {
      int myIntId = await HiveStorage.getUserId();
      String myUuid = UserIdMapper().convertIntsToUuids([myIntId]).first;
      Map<String, dynamic> body = {
        "title": title,
        "priority": priority,
        "description": desc,
        "user_created": myUuid,
      };
      final response = await ApiBaseHelper.post(
        url: tododsUrl,
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

  Future<Map<String, dynamic>> todoList({
    int? limit,
    int? offset,
    String? search = "",
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

      int myIntId = await HiveStorage.getUserId();
      String myUuid = UserIdMapper().convertIntsToUuids([myIntId]).first;
      body["user_id"] = myUuid;
      final response = await ApiBaseHelper.getApi(
        url: tododsUrl,
        useAuthToken: true,
        params: body,
      );
      // print(' TODO RESPONSE: $response');
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> todoStatus({int? id, int? status}) async {
    try {
      Map<String, dynamic> body = {};
      if (status != null) {
        body["isCompleted"] = status;
      }
      // print("BODY OF TODOS UPDATE: $body");
      final response = await ApiBaseHelper.patch(
        url: "$tododsUrl/$id",
        useAuthToken: true,
        body: body,
      );
      // print("RESPONSE OF TODOS UPDATE: $response");
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> deleteTodo({
    required String id,
    required bool token,
  }) async {
    // Map<String, dynamic> rows;

    try {
      if (kDebugMode) {
        logger.d("rftgyhujikl Id $id");
      }
      final response = await ApiBaseHelper.delete(
        url: "$tododsUrl/$id",
        useAuthToken: true,
        body: {},
      );

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

  Future<Map<String, dynamic>> updateTodo({
    required int id,
    required String title,
    required String priority,
    required String desc,
    required bool token,
  }) async {
    try {
      int myIntId = await HiveStorage.getUserId();
      String myUuid = UserIdMapper().convertIntsToUuids([myIntId]).first;
      Map<String, dynamic> body = {
        "id": id,
        "title": title,
        "priority": priority,
        "description": desc,
        "user_created": myUuid,
      };
      final response = await ApiBaseHelper.post(
        url: tododsUrl,
        useAuthToken: true,
        body: body,
      );
      // print("xdctfvgybhnjmk,l ${response['data']['data']}");
      // rows = response['data']['data'] as Map<String, dynamic>;

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
}
