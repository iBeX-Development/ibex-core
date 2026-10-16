import 'package:flutter/foundation.dart';
import 'package:ibex/config/end_points.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../model/asset/asset_model.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AssetRepo {
  Future<Map<String, dynamic>> assetList({
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

      final Map<String, dynamic> response;
      if (id != null) {
        response = await ApiBaseHelper.getApi(
          url: "$getassetUrl/$id",
          useAuthToken: true,
          params: body,
        );
      } else {
        response = await ApiBaseHelper.getApi(
          url: getassetUrl,
          useAuthToken: true,
          params: body,
        );
      }
      return response;
    } catch (error) {
      return {"error": true, "message": "Unexpected error occurred."};
    }
  }

  Future<Map<String, dynamic>> assetIds({
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
          url: "$getassetIdsUrl/$id",
          useAuthToken: true,
          params: body,
        );
      } else {
        response = await ApiBaseHelper.getApi(
          url: getassetIdsUrl,
          useAuthToken: true,
          params: body,
        );
      }

      return response;
    } catch (error) {
      return {"error": true, "message": "Unexpected error occurred."};
    }
  }

  Future<void> assetRemove({required int id}) async {
    try {
      // final response = await ApiBaseHelper.delete(
      //   url: "$removeassetUrl/$id",
      //   useAuthToken: true,
      //   body: {},
      // );

      final response = await ApiBaseHelper.patch(
        url: "$updaetassetUrl/$id",
        useAuthToken: true,
        body: {"status": 0},
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

  Future<void> removeFromAsset({required bool token}) async {
    try {
      await ApiBaseHelper.delete(
        url: removeassetMeassetUrl,
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

  Future<Map<String, dynamic>> createAsset({required AssetModel asset}) async {
    try {
      Map<String, dynamic> body = asset.toJson();

      final response = await ApiBaseHelper.post(
        url: createassetUrl,
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
        "message": "Error occurred",
      }; // ← алдаатай үед буцаах
    }
  }

  Future<Map<String, dynamic>> getAssetPrimary({
    required int id,
    required int defaultPrimary,
  }) async {
    try {
      Map<String, dynamic> body = {"is_default": defaultPrimary};
      final response = await ApiBaseHelper.patch(
        url: "$getassetUrl/$id/default",
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

  Future<Map<String, dynamic>> updateAsset({
    required int id,
    required String name,
    List<int>? userId,
    int? location,
    String? assetCode,
    String? description,
    List<String>? createTeamLeaderIds,
    List<String>? updateTeamLeaderIds,
    List<int>? deleteTeamLeaderIds,
    List<String>? createTeamUserIds,
    List<String>? updateTeamUserIds,
    List<int>? deleteTeamUserIds,
    String? imageId,
  }) async {
    try {
      Map<String, dynamic> body = {};

      body = {"name": name ?? '', "description": description ?? ""};

      // Add image if provided
      if (imageId != null && imageId.isNotEmpty) {
        body["file"] = imageId;
      }

      final response = await ApiBaseHelper.patch(
        url: "$updaetassetUrl/$id",
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
