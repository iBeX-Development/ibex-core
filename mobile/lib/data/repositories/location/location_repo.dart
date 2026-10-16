import 'package:flutter/foundation.dart';
import 'package:ibex/config/end_points.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../model/location/location_model.dart';
import '../../../utils/user_id_mapper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class LocationRepo {
  Future<Map<String, dynamic>> LocationList({
    int? limit,
    int? offset,
    String? search = "",
    String? fields = "",
    int? id,
    Map<String, dynamic>? filter,
  }) async {
    try {
      Map<String, dynamic> body = {};

      if (limit != null) {
        body["limit"] = limit;
      }
      if (offset != null) {
        body["offset"] = offset;
      }
      if (search != null && search.isNotEmpty) {
        body["search"] = search;
      }

      if (fields != null && fields.isNotEmpty) {
        body["fields"] = fields;
      }

      // Handle Directus filter - use JSON string format
      if (filter != null) {
        body["filter"] = filter;
      }


      if (kDebugMode) {
        logger.d("body $body");
      }
      final Map<String, dynamic> response;
      if (id != null) {
        response = await ApiBaseHelper.getApi(
          url: "$getLocationUrl/$id",
          useAuthToken: true,
          params: body,
        );
      } else {
        response = await ApiBaseHelper.getApi(
          url: getLocationUrl,
          useAuthToken: true,
          params: body,
        );
      }

      if (kDebugMode) {
        logger.d("response $response");
      }

      return response;
      
    } catch (error) {
      return {"error": true, "message": "Unexpected error occurred."};
    }
  }

  Future<Map<String, dynamic>> LocationIds({
    int? limit,
    int? offset,
    String? search = "",
    int? id,
  }) async {
    try {
      Map<String, dynamic> body = {};

      if (limit != null) {
        body["limit"] = limit;
      }
      if (offset != null) {
        body["offset"] = offset;
      }
      if (search != null && search.isNotEmpty) {
        body["search"] = search;
      }

      final Map<String, dynamic> response;
      if (id != null) {
        response = await ApiBaseHelper.getApi(
          url: "$getLocationUrl/$id",
          useAuthToken: true,
          params: body,
        );
      } else {
        response = await ApiBaseHelper.getApi(
          url: getLocationUrl,
          useAuthToken: true,
          params: body,
        );
      }

      return response;
    } catch (error) {
      return {"error": true, "message": "Unexpected error occurred."};
    }
  }

  Future<void> LocationRemove({required int id}) async {
    try {
      // final response = await ApiBaseHelper.delete(
      //   url: "$removeLocationUrl/$id",
      //   useAuthToken: true,
      //   body: {},
      // );

      final response = await ApiBaseHelper.patch(
        url: "$updaetLocationUrl/$id",
        useAuthToken: true,
        body: {"active": 0},
      );
      if (response.containsKey('errors')) {
        flutterToastCustom(msg: "${response['message']}");
      }
      return;
    } catch (e, stacktrace) {
      if (kDebugMode) {
        logger.d('Exception: $e');
      }
      if (kDebugMode) {
        logger.d('Stacktrace: $stacktrace');
      }
      return;
    }
  }

  Future<void> removeFromLocation({required bool token}) async {
    try {
      await ApiBaseHelper.delete(
        url: getLocationUrl,
        useAuthToken: true,
        body: {},
      );
    } catch (e, stacktrace) {
      if (kDebugMode) {
        logger.d('Exception: $e');
      }
      if (kDebugMode) {
        logger.d('Stacktrace: $stacktrace');
      }
    }
  }

  Future<Map<String, dynamic>> createLocation({
    required LocationModel work,
  }) async {
    try {
      Map<String, dynamic> body = work.toJson();

      Map<String, dynamic> usersOps = {};
      UserIdMapper mapper = UserIdMapper();

      final response = await ApiBaseHelper.post(
        url: createLocationUrl,
        useAuthToken: true,
        body: body,
      );
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      return {
        "error": true,
        "message": "Error occurred"
      }; // ← алдаатай үед буцаах
    }
  }

  Future<Map<String, dynamic>> getLocationPrimary({
    required int id,
    required int defaultPrimary,
  }) async {
    try {
      Map<String, dynamic> body = {"is_default": defaultPrimary};
      final response = await ApiBaseHelper.patch(
        url: "$getLocationUrl/$id/default",
        useAuthToken: true,
        body: body,
      );
      return response as Map<String, dynamic>;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updateLocation({
    required int id,
    required String title,
  }) async {
    try {
      Map<String, dynamic> body = {};

      final response = await ApiBaseHelper.patch(
        url: "$updaetLocationUrl/$id",
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
