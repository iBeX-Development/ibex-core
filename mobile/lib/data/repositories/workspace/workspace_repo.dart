import 'package:flutter/foundation.dart';
import 'package:ibex/config/end_points.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../model/workspace/workspace_model.dart';
import '../../../utils/user_id_mapper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkspaceRepo {
  Future<Map<String, dynamic>> workspaceList({
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

        logger.d('workspaceList body: $body');

      }

      final Map<String, dynamic> response;
      if (id != null) {
        response = await ApiBaseHelper.getApi(
          url: "$getWorkSpaceUrl/$id",
          useAuthToken: true,
          params: body,
        );
      } else {
        response = await ApiBaseHelper.getApi(
          url: getWorkSpaceUrl,
          useAuthToken: true,
          params: body,
        );
      }

      if (kDebugMode) {

        logger.d('✅ workspaceList response received: ${response.keys}');

      }
      if (response['data'] != null) {
        logger.d(
            '📊 workspaceList data count: ${(response['data'] as List).length}');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d('❌ workspaceList error: $error');
      }
      return {"error": true, "message": "Unexpected error occurred: $error"};
    }
  }

  Future<Map<String, dynamic>> workspaceIds({
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
        body["filter[Teams_id][_eq]"] = id;
        response = await ApiBaseHelper.getApi(
          url: "$getmyWorkSpaceIdsUrl",
          useAuthToken: true,
          params: body,
        );
      } else {
        response = await ApiBaseHelper.getApi(
          url: getmyWorkSpaceIdsUrl,
          useAuthToken: true,
          params: body,
        );
      }

      return response;
    } catch (error) {
      return {"error": true, "message": error.toString()};
    }
  }

  Future<void> workspaceRemove({required int id}) async {
    try {
      // final response = await ApiBaseHelper.delete(
      //   url: "$removeWorkSpaceUrl/$id",
      //   useAuthToken: true,
      //   body: {},
      // );

      final response = await ApiBaseHelper.patch(
        url: "$updaetWorkSpaceUrl/$id",
        useAuthToken: true,
        body: {"active": 0},
      );
      if (kDebugMode) {
        logger.d("workspaceRemove SEEE ${response}");
      }
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

  Future<void> removeFromWorkspace({required bool token}) async {
    try {
      await ApiBaseHelper.delete(
        url: removeMeWorkSpaceUrl,
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

  Future<Map<String, dynamic>> createWorkspace({
    required WorkspaceModel work,
  }) async {
    try {
      Map<String, dynamic> body = work.toJson();
      // print('Request Body: ${work.toJson()}');

      Map<String, dynamic> usersOps = {};
      UserIdMapper mapper = UserIdMapper();

      if (body['user_ids'] != null && body['user_ids'].isNotEmpty) {
        usersOps["create"] = body['user_ids']
            .map((userId) => {
                  "Teams_id": "+",
                  "directus_users_id": {
                    "id": mapper.getUuid(userId) ?? userId.toString()
                  }
                })
            .toList();
      }

      if (usersOps.isNotEmpty) {
        body["users"] = usersOps;
      }
      if (kDebugMode) {
        logger.d('createWorkspace body: $body');
      }

      final response = await ApiBaseHelper.post(
        url: createWorkSpaceUrl,
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

  Future<Map<String, dynamic>> getWorkspacePrimary({
    required int id,
    required int defaultPrimary,
  }) async {
    try {
      Map<String, dynamic> body = {"is_default": defaultPrimary};
      final response = await ApiBaseHelper.patch(
        url: "$getWorkSpaceUrl/$id/default",
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

  Future<Map<String, dynamic>> updateWorkspace({
    required int id,
    required String title,
    required List<int> userId,
    int? primaryWorkSpace,
    List<int>? clientId,
    String? name,
    String? description,
    List<String>? createTeamLeaderIds,
    List<String>? updateTeamLeaderIds,
    List<int>? deleteTeamLeaderIds,
    List<String>? createTeamUserIds,
    List<String>? updateTeamUserIds,
    List<int>? deleteTeamUserIds,
    String? imageId,
    bool isTeamUpdate = false,
  }) async {
    try {
      Map<String, dynamic> body = {};

      if (isTeamUpdate) {
        // Team update structure
        body = {
          "name": name ?? title,
          "description": description ?? "",
        };

        // Handle team leaders operations
        Map<String, dynamic> teamLeadersOps = {};
        if (kDebugMode) {
          logger.d('createTeamLeaderIds: $createTeamLeaderIds');
        }

        if (createTeamLeaderIds != null && createTeamLeaderIds.isNotEmpty) {
          teamLeadersOps["create"] = createTeamLeaderIds
              .map((leaderId) => {
                    "Teams_id": id.toString(),
                    "directus_users_id": {"id": leaderId}
                  })
              .toList();
        }

        if (updateTeamLeaderIds != null && updateTeamLeaderIds.isNotEmpty) {
          teamLeadersOps["update"] = updateTeamLeaderIds
              .map((leaderId) => {
                    "Teams_id": id.toString(),
                    "directus_users_id": {"id": leaderId}
                  })
              .toList();
        }

        if (deleteTeamLeaderIds != null && deleteTeamLeaderIds.isNotEmpty) {
          teamLeadersOps["delete"] = deleteTeamLeaderIds;
        }

        if (teamLeadersOps.isNotEmpty) {
          body["team_leaders"] = teamLeadersOps;
        }

        // Handle users operations
        Map<String, dynamic> usersOps = {};
        UserIdMapper mapper = UserIdMapper();

        List<String> userUuids = userId.map((intId) {
          String? uuid = mapper.getUuid(intId);
          if (uuid != null) {
            return uuid;
          } else {
            if (kDebugMode) {
              logger.d("⚠️ Warning: No UUID found for user ID: $intId");
            }
            return intId.toString(); // fallback to string ID
          }
        }).toList().cast<String>();

        if (createTeamUserIds != null && createTeamUserIds.isNotEmpty) {
          usersOps["create"] = createTeamUserIds
              .map((userId) => {
                    "Teams_id": id.toString(),
                    "directus_users_id": {"id": userId}
                  })
              .toList();
        }

        if (updateTeamUserIds != null && updateTeamUserIds.isNotEmpty) {
          usersOps["update"] = [];
        }

        if (deleteTeamUserIds != null && deleteTeamUserIds.isNotEmpty) {
          usersOps["delete"] = deleteTeamUserIds;
        }

        if (usersOps.isNotEmpty) {
          body["users"] = usersOps;
        }

        // Add image if provided
        if (imageId != null && imageId.isNotEmpty) {
          body["_image"] = imageId;
        }
      }

      // print('updateWorkspace body: $body');

      final response = await ApiBaseHelper.patch(
        url: "$updaetWorkSpaceUrl/$id",
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
