import 'package:flutter/foundation.dart';
import '../../../utils/user_id_mapper.dart';
import 'package:logger/logger.dart';
import 'package:ibex/config/constants.dart';

final logger = Logger();

class Workspace {
  bool? error;
  String? message;
  int? total;
  List<WorkspaceModel>? data;

  Workspace({this.error, this.message, this.total, this.data});

  Workspace.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    message = json['message'];
    total = json['total'];
    if (json['data'] != null) {
      data = <WorkspaceModel>[];
      json['data'].forEach((v) {
        data!.add(WorkspaceModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['error'] = error;
    data['message'] = message;
    data['total'] = total;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class WorkspaceModel {
  int? id;
  String? title;
  String? userCreated;
  DateTime? dateCreated;
  String? userUpdated;
  DateTime? dateUpdated;
  int? active;
  String? image;
  String? description;
  dynamic stats;
  String? role;
  int? primaryWorkspace;
  int? defaultWorkspace;
  List<UsersWorkspace>? users;
  List<int>? userIds;
  List<ClientsWorkspace>? clients;
  List<int>? clientIds;
  List<UsersWorkspace>? teamLeaders;
  List<int>? teamLeaderIds;
  String? createdAt;
  String? updatedAt;

  WorkspaceModel({
    this.id,
    this.title,
    this.userCreated,
    this.dateCreated,
    this.userUpdated,
    this.dateUpdated,
    this.active,
    this.image,
    this.description,
    this.stats,
    this.role,
    this.primaryWorkspace,
    this.defaultWorkspace,
    this.users,
    this.userIds,
    this.clients,
    this.clientIds,
    this.teamLeaders,
    this.teamLeaderIds,
    this.createdAt,
    this.updatedAt,
  });

  WorkspaceModel.fromJson(Map<String, dynamic> json) {
    try {
      id = json['id'];
      title = json['name'] ?? json['title']; // Directus uses 'name'
      userCreated = json['user_created'];

      // Safe DateTime parsing
      if (json['date_created'] != null) {
        try {
          String dateString = json['date_created'].toString();
          dateCreated = DateTime.parse(dateString);
        } catch (e) {
          if (kDebugMode) {
            logger.d("Error parsing date_created: $e");
          }
          dateCreated = null;
        }
      } else {
        dateCreated = null;
      }

      userUpdated = json['user_updated'];

      // Safe DateTime parsing for updated date
      if (json['date_updated'] != null) {
        try {
          String updatedDateString = json['date_updated'].toString();
          dateUpdated = DateTime.parse(updatedDateString);
        } catch (e) {
          if (kDebugMode) {
            logger.d("Error parsing date_updated: $e");
          }
          dateUpdated = null;
        }
      } else {
        dateUpdated = null;
      }

      active = json['active'];
      image = json['_image'];
      description = json['description'];
      stats = json['stats'];
      role = json['role'];
      primaryWorkspace = json['primaryWorkspace'];
      defaultWorkspace = json['defaultWorkspace'];
    } catch (e) {
      if (kDebugMode) {
        logger.d("Error in WorkspaceModel.fromJson: $e");
      }
      if (kDebugMode) {
        logger.d("JSON data: $json");
      }
      rethrow;
    }

    // Handle Directus Many-to-Many junction table format
    try {
      if (json['users'] != null && json['users'] is List) {
        users = <UsersWorkspace>[];
        userIds = <int>[];

        for (var item in json['users']) {
          if (item is Map<String, dynamic>) {
            try {
              // Extract user data from directus_users_id nested object
              var userData = item['directus_users_id'];
              if (userData != null && userData is Map<String, dynamic>) {
                users!.add(UsersWorkspace.fromJson(userData));

                // Extract int ID from junction table 'id' field
                if (item['id'] != null && item['id'] is int) {
                  userIds!.add(item['id']);
                }
              }
            } catch (e) {
              if (kDebugMode) {
                logger.d("Error parsing user data: $e");
              }
              if (kDebugMode) {
                logger.d("User item: $item");
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("Error parsing users array: $e");
      }
      users = null;
      userIds = null;
    }

    // Fallback for user_ids
    if (json['user_ids'] != null) {
      userIds = (json['user_ids'] as List).cast<int>();
    }

    // Handle clients similarly
    try {
      if (json['clients'] != null && json['clients'] is List) {
        clients = <ClientsWorkspace>[];
        clientIds = <int>[];

        for (var item in json['clients']) {
          if (item is Map<String, dynamic>) {
            try {
              var clientData = item['directus_users_id'];
              if (clientData != null && clientData is Map<String, dynamic>) {
                clients!.add(ClientsWorkspace.fromJson(clientData));

                if (item['id'] != null && item['id'] is int) {
                  clientIds!.add(item['id']);
                }
              }
            } catch (e) {
              if (kDebugMode) {
                logger.d("Error parsing client data: $e");
              }
              if (kDebugMode) {
                logger.d("Client item: $item");
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("Error parsing clients array: $e");
      }
      clients = null;
      clientIds = null;
    }

    if (json['client_ids'] != null) {
      clientIds = (json['client_ids'] as List).cast<int>();
    }

    // Handle team_leaders similarly
    try {
      if (json['team_leaders'] != null && json['team_leaders'] is List) {
        teamLeaders = <UsersWorkspace>[];
        teamLeaderIds = <int>[];

        for (var item in json['team_leaders']) {
          if (item is Map<String, dynamic>) {
            try {
              var leaderData = item['directus_users_id'];
              if (leaderData != null && leaderData is Map<String, dynamic>) {
                var leaderUser = UsersWorkspace.fromJson(leaderData);
                teamLeaders!.add(leaderUser);

                // team_leaders junction table doesn't have 'id' field, use user's int ID instead
                if (leaderUser.id != null) {
                  teamLeaderIds!.add(leaderUser.id!);
                } else if (item['id'] != null && item['id'] is int) {
                  // Fallback to junction table ID if exists
                  teamLeaderIds!.add(item['id']);
                }
              }
            } catch (e) {
              if (kDebugMode) {
                logger.d("Error parsing team leader data: $e");
              }
              if (kDebugMode) {
                logger.d("Team leader item: $item");
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("Error parsing team_leaders array: $e");
      }
      teamLeaders = null;
      teamLeaderIds = null;
    }

    if (json['team_leader_ids'] != null) {
      teamLeaderIds = (json['team_leader_ids'] as List).cast<int>();
    }

    createdAt = json['date_created'] ?? json['created_at'];
    updatedAt = json['date_updated'] ?? json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    if (id != null) {
      data['id'] = id;
    }
    data['name'] = title;
    data['user_created'] = userCreated;
    data['date_created'] = dateCreated?.toIso8601String();
    data['user_updated'] = userUpdated;
    data['date_updated'] = dateUpdated?.toIso8601String();
    data['active'] = active;
    data['_image'] = image;
    data['description'] = description;
    data['stats'] = stats;
    data['role'] = role;
    data['primaryWorkspace'] = primaryWorkspace;
    data['defaultWorkspace'] = defaultWorkspace;

    if (users != null) {
      data['users'] = users!.map((v) => v.toJson()).toList();
    }
    data['user_ids'] = userIds;

    if (clients != null) {
      data['clients'] = clients!.map((v) => v.toJson()).toList();
    }
    data['client_ids'] = clientIds;

    if (teamLeaders != null) {
      data['team_leaders'] = teamLeaders!.map((v) => v.toJson()).toList();
    }
    data['team_leader_ids'] = teamLeaderIds;

    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class UsersWorkspace {
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  String? photo;

  UsersWorkspace({this.id, this.firstName, this.lastName, this.photo});

  UsersWorkspace.fromJson(Map<String, dynamic> json) {
    try {
      // Handle UUID → int conversion
      var idValue = json['id'];
      if (idValue is String && idValue.contains('-')) {
        // UUID format
        id = UserIdMapper().getIntId(idValue);
      } else if (idValue is int) {
        id = idValue;
      }

      firstName = json['first_name'];
      lastName = json['last_name'];

      // Handle avatar UUID
      var photoValue = json['avatar'] ?? json['photo'];
      if (photoValue is String && photoValue.isNotEmpty) {
        if (photoValue.contains('-') && !photoValue.startsWith('http')) {
          photo = '$activePictureUrl/$photoValue';
        } else {
          photo = photoValue;
        }
      } else {
        photo = null;
      }

      email = json['email'];
    } catch (e) {
      if (kDebugMode) {
        logger.d("Error in UsersWorkspace.fromJson: $e");
      }
      if (kDebugMode) {
        logger.d("JSON data: $json");
      }
      // Set default values on error
      id = null;
      firstName = null;
      lastName = null;
      photo = null;
      email = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['photo'] = photo;
    data['email'] = email;
    return data;
  }
}

class ClientsWorkspace {
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  String? photo;

  ClientsWorkspace({this.id, this.firstName, this.lastName, this.photo});

  ClientsWorkspace.fromJson(Map<String, dynamic> json) {
    try {
      // Handle UUID → int conversion
      var idValue = json['id'];
      if (idValue is String && idValue.contains('-')) {
        // UUID format
        id = UserIdMapper().getIntId(idValue);
      } else if (idValue is int) {
        id = idValue;
      }

      firstName = json['first_name'];
      lastName = json['last_name'];

      // Handle avatar UUID
      var photoValue = json['avatar'] ?? json['photo'];
      if (photoValue is String && photoValue.isNotEmpty) {
        if (photoValue.contains('-') && !photoValue.startsWith('http')) {
          photo = '$activePictureUrl/$photoValue';
        } else {
          photo = photoValue;
        }
      } else {
        photo = null;
      }

      email = json['email'];
    } catch (e) {
      if (kDebugMode) {
        logger.d("Error in ClientsWorkspace.fromJson: $e");
      }
      if (kDebugMode) {
        logger.d("JSON data: $json");
      }
      // Set default values on error
      id = null;
      firstName = null;
      lastName = null;
      photo = null;
      email = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['photo'] = photo;
    data['email'] = email;
    return data;
  }
}
