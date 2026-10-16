import 'package:flutter/foundation.dart';
import 'package:ibex/data/localStorage/hive.dart';
import 'package:ibex/utils/date_format.dart';
import 'package:intl/intl.dart';
import '../../../config/constants.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AllWorkModel {
  bool? error;
  String? message;
  int? total;
  List<WorkModel>? data;
  List<Object>? woStatusData;

  AllWorkModel({
    this.error,
    this.message,
    this.total,
    this.data,
    this.woStatusData,
  });

  AllWorkModel.fromJson(Map<String, dynamic> json, List<Object>? woStatusData) {
    error = json['error'];
    message = json['message'];
    total = json['total'];
    if (json['data'] != null) {
      data = <WorkModel>[];
      json['data'].forEach((v) {
        data!.add(WorkModel.fromJson(v, woStatusData));
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

/// Backend-с String эсвэл int хэлбэрт ирж болох утгыг int? болгон хөрвүүлнэ.
int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class WorkModel {
  int? id;
  String? title;
  String? status;
  int? statusId;
  int? location;
  int? active;
  List<int>? woStatus;
  List<int>? teamIds;
  String? priority;
  int? taskCount;
  int? priorityId;
  List<WorkUsers>? users;
  List<int>? userId;
  List<WorkClients>? clients;
  List<int>? clientId;
  List<Tag>? tags;
  List<int>? tagIds;
  String? startDate;
  String? completedAt;
  String? endDate;
  String? budget;
  String? taskAccessibility;
  String? description;
  String? note;
  String? createdType;
  int? favorite;
  int? pinned;
  String? createdAt;
  int? clientCanDiscuss;
  int? enable;
  int? action_status;
  String? updatedAt;
  String? createType;
  String? workType;
  String? wo_prefix;
  List<CustomFields>? customFields;
  CustomFieldValues? customFieldValues;
  List<Object>? woStatusData;
  List<Object>? priorityDatas;
  Map<String, dynamic>? asset;
  int? assetId;
  int? req_number;
  int? wo_number;
  int? source_pm;
  int? source_pdm;
  int? source_ins;
  Map<String, dynamic>? actionStatus;

  Map<String, dynamic>? assigned_to;
  WorkModel({
    this.id,
    this.title,
    this.status,
    this.statusId,
    this.location,
    this.active,
    this.woStatus,
    this.teamIds,
    this.priority,
    this.priorityId,
    this.taskCount,
    this.users,
    this.userId,
    this.clients,
    this.clientId,
    this.tags,
    this.tagIds,
    this.startDate,
    this.completedAt,
    this.endDate,
    this.budget,
    this.enable,
    this.clientCanDiscuss,
    this.taskAccessibility,
    this.description,
    this.note,
    this.createdType,
    this.favorite,
    this.pinned,
    this.createdAt,
    this.asset,
    this.assetId,
    this.assigned_to,
    this.action_status,
    this.updatedAt,
    this.createType,
    this.workType,
    this.woStatusData,
    this.actionStatus,
    this.customFields,
    this.customFieldValues,
    this.req_number,
    this.wo_number,
    this.source_pm,
    this.source_pdm,
    this.source_ins,
    this.wo_prefix,
  });

  WorkModel.fromJson(Map<String, dynamic> json, List<Object>? woStatusData) {
    // neeh
    // loadStatusData();
    // this.woStatusData = woStatusData;

    id = json['id'] ?? 0;
    title = json['name'] ?? json['title'] ?? "";

    // ✅ Status fields - handle both wo_status and status
    statusId = json['wo_status'] is int
        ? json['wo_status']
        : (json['status'] is int ? json['status'] : 0);

    // ✅ Priority fields
    priorityId = json['priority'] is int
        ? json['priority']
        : (int.tryParse(json['priority']?.toString() ?? '0') ?? 0);

    // ✅ Action status - FIXED
    action_status = json['action_status'] is int
        ? json['action_status']
        : (int.tryParse(json['action_status']?.toString() ?? '0') ?? 0);

    // ✅ Location
    location = json['location'] is int
        ? json['location']
        : (int.tryParse(json['location']?.toString() ?? '0') ?? 0);

    // ✅ Active status
    active = json['active'] is int
        ? json['active']
        : (int.tryParse(json['active']?.toString() ?? '0') ?? 1);

    taskCount = json['task_count'] ?? 0;

    // ✅ Date parsing with null safety
    if (json['due'] != null) {
      final parsedEndDate = DateParser.parse(json['due']);
      endDate = parsedEndDate?.toIso8601String();
    } else {
      endDate = null;
    }

    if (json['created_at'] != null || json['date_created'] != null) {
      final createdAtDate = DateParser.parse(
        json['created_at'] ?? json['date_created'],
      );
      createdAt = createdAtDate?.toIso8601String();
    } else {
      createdAt = null;
    }

    if (json['modified_at'] != null || json['date_updated'] != null) {
      final modifiedAtDate = DateParser.parse(
        json['modified_at'] ?? json['date_updated'],
      );
      updatedAt = modifiedAtDate?.toIso8601String();
    } else {
      updatedAt = null;
    }

    if (json['started_at'] != null) {
      final startedAtDate = DateParser.parse(json['started_at']);
      startDate = startedAtDate?.toIso8601String();
    } else {
      startDate = null;
    }

    if (json['completed_at'] != null) {
      final completedAtDate = DateParser.parse(json['completed_at']);
      completedAt = completedAtDate?.toIso8601String();
    } else {
      completedAt = null;
    }

    // ✅ Budget - use wo_percent
    budget = json['wo_percent']?.toString() ?? "0";

    taskAccessibility = json['task_accessibility']?.toString() ?? "";
    clientCanDiscuss =
        json['can_client_discuss'] ?? json['client_can_discuss'] ?? 0;
    enable = 1;

    // ✅ Description fields - handle null safety_notes
    description = json['history_description']?.toString() ?? "";
    note = json['safety_notes'] ?? json['safety_notes']?.toString() ?? "";

    // ✅ Created type
    createdType = json['created_type']?.toString() ?? "";

    favorite = json['favorite'] ?? 0;
    pinned = json['pinned'] ?? 0;

    // ✅ Priority label lookup
    priorityDatas = getContstantPriorities();
    if (priorityDatas != null && priorityId != null && priorityId! > 0) {
      try {
        final priorityObj = priorityDatas!.firstWhere(
          (e) => (e is Map<String, dynamic>) && (e['value'] == priorityId),
          orElse: () => <String, dynamic>{},
        );
        if (priorityObj is Map<String, dynamic> && priorityObj.isNotEmpty) {
          priority = priorityObj['label']?.toString() ?? '';
        } else {
          priority = '';
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d("⚠️ Error getting priority label: $e");
        }
        priority = '';
      }
    } else {
      priority = '';
    }

    if (woStatusData == null) {
      loadStatusData();
    }

    // ✅ Status label lookup from Hive data
    if (woStatusData != null && statusId != null && statusId! > 0) {
      final statusList = woStatusData
          .where((e) {
            return e is Map;
          })
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (statusList.isNotEmpty) {
        // ✅ Try to find matching status by 'id' field
        final statusObj = statusList.firstWhere((e) {
          final statusValue = e['id']; // ✅ Use 'id' field from Statuses model
          if (statusValue is int) {
            return statusValue == statusId;
          } else if (statusValue is String) {
            return int.tryParse(statusValue) == statusId;
          }
          return false;
        }, orElse: () => <String, dynamic>{});

        if (statusObj.isNotEmpty) {
          status = statusObj['title']?.toString() ?? ''; // ✅ Use 'title' field
        } else {
          status = '';
        }
      } else {
        status = '';
      }
    } else {
      status = '';
      if (statusId == null || statusId == 0) {}
    }

    // ✅ FIXED: Assigned team parsing - handle null and safe type casting
    if (json['assigned_team'] != null && json['assigned_team'] is Map) {
      final team = json['assigned_team'] as Map<String, dynamic>;

      // ✅ Safe ID parsing - can be int or string
      int? teamId;
      if (team['id'] is int) {
        teamId = team['id'] as int;
      } else if (team['id'] is String) {
        teamId = int.tryParse(team['id'] as String);
      }

      userId = teamId != null ? [teamId] : [];

      users = [
        WorkUsers(
          id: teamId,
          firstName: team['name']?.toString(),
          lastName: '',
          team_name: team['name']?.toString(),
          photo: team['_image']?.toString(),
        ),
      ];
    } else {
      userId = [];
      users = [];
    }

    // ✅ Clients parsing - handle null or empty
    if (json['clients'] != null && json['clients'] is List) {
      clients = (json['clients'] as List)
          .map((v) => WorkClients.fromJson(v as Map<String, dynamic>))
          .toList();
      clientId = clients!.map((c) => c.id ?? 0).toList();
    } else {
      clients = [];
      clientId = [];
    }

    // ✅ Tags parsing - handle null or empty
    if (json['tags'] != null && json['tags'] is List) {
      tags = (json['tags'] as List)
          .map((v) => Tag.fromJson(v as Map<String, dynamic>))
          .toList();
      tagIds = tags!.map((t) => t.id ?? 0).toList();
    } else {
      tags = [];
      tagIds = [];
    }

    // ✅ Asset parsing - handle null or empty
    if (json['asset'] != null) {
      if (json['asset'] is Map && (json['asset'] as Map).isNotEmpty) {
        asset = Map<String, dynamic>.from(json['asset'] as Map);

        // ✅ Safe asset ID parsing
        if (asset!['id'] is int) {
          assetId = asset!['id'] as int;
        } else if (asset!['id'] is String) {
          assetId = int.tryParse(asset!['id'] as String);
        } else {
          assetId = null;
        }
      } else if (json['asset'] is List && (json['asset'] as List).isNotEmpty) {
        asset = Map<String, dynamic>.from((json['asset'] as List).first as Map);

        // ✅ Safe asset ID parsing
        if (asset!['id'] is int) {
          assetId = asset!['id'] as int;
        } else if (asset!['id'] is String) {
          assetId = int.tryParse(asset!['id'] as String);
        } else {
          assetId = null;
        }
      } else {
        asset = null;
        assetId = null;
      }
    } else {
      asset = null;
      assetId = null;
    }

    // ✅ Assigned to parsing - handle null or empty
    if (json['assigned_to'] != null) {
      if (json['assigned_to'] is Map &&
          (json['assigned_to'] as Map).isNotEmpty) {
        assigned_to = Map<String, dynamic>.from(json['assigned_to'] as Map);
      } else if (json['assigned_to'] is List &&
          (json['assigned_to'] as List).isNotEmpty) {
        assigned_to = Map<String, dynamic>.from(
          (json['assigned_to'] as List).first as Map,
        );
      } else {
        assigned_to = null;
      }
    } else {
      assigned_to = null;
    }

    // ✅ Action status object parsing (for status details)
    if (json['action_status'] != null &&
        json['action_status'] is Map<String, dynamic>) {
      actionStatus = Map<String, dynamic>.from(json['action_status'] as Map);
    } else {
      actionStatus = null;
    }

    // ✅ Create type
    createType = json['created_type']?.toString() ?? "";
    req_number = _toInt(json['req_number']);
    wo_number  = _toInt(json['wo_number']);
    source_pm  = _toInt(json['source_pm']);
    source_pdm = _toInt(json['source_pdm']);
    source_ins = _toInt(json['source_ins']);
    wo_prefix  = json['wo_prefix']?.toString() ?? "";

    // ✅ Custom fields parsing
    if (json['customFields'] != null && json['customFields'] is List) {
      customFields = (json['customFields'] as List)
          .map((v) => CustomFields.fromJson(v as Map<String, dynamic>))
          .toList();
    } else {
      customFields = [];
    }

    // ✅ Custom field values parsing
    if (json['customFieldValues'] != null) {
      if (json['customFieldValues'] is Map<String, dynamic>) {
        customFieldValues = CustomFieldValues.fromJson(
          json['customFieldValues'] as Map<String, dynamic>,
        );
      } else if (json['customFieldValues'] is List) {
        var list = json['customFieldValues'] as List;
        if (list.isNotEmpty && list.first is Map<String, dynamic>) {
          customFieldValues = CustomFieldValues.fromJson(
            list.first as Map<String, dynamic>,
          );
        } else {
          customFieldValues = null;
        }
      } else {
        customFieldValues = null;
      }
    } else {
      customFieldValues = null;
    }

    // print(
    //     "✅ WorkModel parsed: ID=$id, Title=$title, Status=$statusId, Priority=$priorityId, ActionStatus=$action_status");
  }

  // factory WorkModel.fromJson(
  //   Map<String, dynamic> json,
  //   List<dynamic>? woStatusData,
  // ) {
  //   try {

  //     // ✅ Parse basic fields
  //     int? id = json['id'] ?? 0;
  //     String? title = json['name'] ?? json['title'] ?? "";

  //     // ✅ Status fields - handle both wo_status and status
  //     int? statusId = json['wo_status'] is int
  //         ? json['wo_status']
  //         : (json['status'] is int ? json['status'] : 0);

  //     // ✅ Priority fields
  //     int? priorityId = json['priority'] is int
  //         ? json['priority']
  //         : (int.tryParse(json['priority']?.toString() ?? '0') ?? 0);

  //     // ✅ Action status - FIXED
  //     int? action_status = json['action_status'] is int
  //         ? json['action_status']
  //         : (int.tryParse(json['action_status']?.toString() ?? '0') ?? 0);

  //     // ✅ Location
  //     int? location = json['location'] is int
  //         ? json['location']
  //         : (int.tryParse(json['location']?.toString() ?? '0') ?? 0);

  //     // ✅ Active status
  //     int? active = json['active'] is int
  //         ? json['active']
  //         : (int.tryParse(json['active']?.toString() ?? '0') ?? 1);

  //     int? taskCount = json['task_count'] ?? 0;

  //     // ✅ Date parsing with null safety
  //     String? endDate;
  //     if (json['due'] != null) {
  //       final parsedEndDate = DateParser.parse(json['due']);
  //       endDate = parsedEndDate?.toIso8601String();
  //     }

  //     String? createdAt;
  //     if (json['created_at'] != null || json['date_created'] != null) {
  //       final createdAtDate =
  //           DateParser.parse(json['created_at'] ?? json['date_created']);
  //       createdAt = createdAtDate?.toIso8601String();
  //     }

  //     String? updatedAt;
  //     if (json['modified_at'] != null || json['date_updated'] != null) {
  //       final modifiedAtDate =
  //           DateParser.parse(json['modified_at'] ?? json['date_updated']);
  //       updatedAt = modifiedAtDate?.toIso8601String();
  //     }

  //     String? startDate;
  //     if (json['started_at'] != null) {
  //       final startedAtDate = DateParser.parse(json['started_at']);
  //       startDate = startedAtDate?.toIso8601String();
  //     }

  //     String? completedAt;
  //     if (json['completed_at'] != null) {
  //       final completedAtDate = DateParser.parse(json['completed_at']);
  //       completedAt = completedAtDate?.toIso8601String();
  //     }

  //     // ✅ Budget - use wo_percent
  //     String? budget = json['wo_percent']?.toString() ?? "0";

  //     String? taskAccessibility = json['task_accessibility']?.toString() ?? "";
  //     int? clientCanDiscuss =
  //         json['can_client_discuss'] ?? json['client_can_discuss'] ?? 0;
  //     int? enable = json['enable_time_entries'] ?? 1;

  //     // ✅ Description fields - handle null safety_notes
  //     String? description = json['history_description']?.toString() ?? "";
  //     String? note = json['safety_notes']?.toString() ?? "";

  //     // ✅ Created type
  //     String? createdType = json['created_type']?.toString() ?? "";
  //     String? createType = json['created_type']?.toString() ?? "";

  //     int? favorite = json['favorite'] ?? 0;
  //     int? pinned = json['pinned'] ?? 0;

  //     // ✅ Priority label lookup
  //     List<Object>? priorityDatas = getContstantPriorities();
  //     String? priority = '';
  //     if (priorityId != null && priorityId > 0) {
  //       try {
  //         final priorityObj = priorityDatas.firstWhere(
  //           (e) => (e is Map<String, dynamic>) && (e['value'] == priorityId),
  //           orElse: () => <String, dynamic>{},
  //         );
  //         if (priorityObj is Map<String, dynamic> && priorityObj.isNotEmpty) {
  //           priority = priorityObj['label']?.toString() ?? '';
  //         }
  //       } catch (e) {
  //         print("⚠️ Error getting priority label: $e");
  //       }
  //     }

  //     // ✅ Status label lookup
  //     String? status = '';
  //     if (woStatusData != null && statusId != null && statusId > 0) {
  //       try {
  //         final statusObj = woStatusData.firstWhere(
  //           (e) => (e is Map<String, dynamic>) && e['status_value'] == statusId,
  //           orElse: () => <String, dynamic>{},
  //         );
  //         if (statusObj is Map<String, dynamic> && statusObj.isNotEmpty) {
  //           status = statusObj['status_text']?.toString() ?? '';
  //         }
  //       } catch (e) {
  //         print("⚠️ Error getting status label: $e");
  //       }
  //     }

  //     // ✅ Assigned team parsing - handle null and safe type casting
  //     List<WorkUsers>? users = [];
  //     List<int>? userId = [];

  //     if (json['assigned_team'] != null && json['assigned_team'] is Map) {
  //       final team = json['assigned_team'] as Map<String, dynamic>;

  //       // ✅ Safe ID parsing - can be int or string
  //       int? teamId;
  //       if (team['id'] is int) {
  //         teamId = team['id'] as int;
  //       } else if (team['id'] is String) {
  //         teamId = int.tryParse(team['id'] as String);
  //       }

  //       if (teamId != null) {
  //         userId = [teamId];
  //         users = [
  //           WorkUsers(
  //             id: teamId,
  //             firstName: team['name']?.toString(),
  //             lastName: '',
  //             team_name: team['name']?.toString(),
  //             photo: team['_image']?.toString(),
  //           )
  //         ];
  //       }
  //     }

  //     // ✅ Clients parsing - handle null or empty
  //     List<WorkClients>? clients = [];
  //     List<int>? clientId = [];

  //     if (json['clients'] != null && json['clients'] is List) {
  //       clients = (json['clients'] as List)
  //           .map((v) => WorkClients.fromJson(v as Map<String, dynamic>))
  //           .toList();
  //       clientId = clients.map((c) => c.id ?? 0).toList();
  //     }

  //     // ✅ Tags parsing - handle null or empty
  //     List<Tag>? tags = [];
  //     List<int>? tagIds = [];

  //     if (json['tags'] != null && json['tags'] is List) {
  //       tags = (json['tags'] as List)
  //           .map((v) => Tag.fromJson(v as Map<String, dynamic>))
  //           .toList();
  //       tagIds = tags.map((t) => t.id ?? 0).toList();
  //     }

  //     // ✅ Asset parsing - handle null or empty
  //     Map<String, dynamic>? asset;
  //     int? assetId;

  //     if (json['asset'] != null) {
  //       if (json['asset'] is Map && (json['asset'] as Map).isNotEmpty) {
  //         asset = Map<String, dynamic>.from(json['asset'] as Map);

  //         // ✅ Safe asset ID parsing
  //         if (asset['id'] is int) {
  //           assetId = asset['id'] as int;
  //         } else if (asset['id'] is String) {
  //           assetId = int.tryParse(asset['id'] as String);
  //         }
  //       } else if (json['asset'] is List &&
  //           (json['asset'] as List).isNotEmpty) {
  //         asset =
  //             Map<String, dynamic>.from((json['asset'] as List).first as Map);

  //         // ✅ Safe asset ID parsing
  //         if (asset['id'] is int) {
  //           assetId = asset['id'] as int;
  //         } else if (asset['id'] is String) {
  //           assetId = int.tryParse(asset['id'] as String);
  //         }
  //       }
  //     }

  //     // ✅ Assigned to parsing - handle null or empty
  //     Map<String, dynamic>? assigned_to;

  //     if (json['assigned_to'] != null) {
  //       if (json['assigned_to'] is Map &&
  //           (json['assigned_to'] as Map).isNotEmpty) {
  //         assigned_to = Map<String, dynamic>.from(json['assigned_to'] as Map);
  //       } else if (json['assigned_to'] is List &&
  //           (json['assigned_to'] as List).isNotEmpty) {
  //         assigned_to = Map<String, dynamic>.from(
  //             (json['assigned_to'] as List).first as Map);
  //       }
  //     }

  //     // ✅ Action status object parsing (for status details)
  //     Map<String, dynamic>? actionStatus;

  //     if (json['action_status'] != null &&
  //         json['action_status'] is Map<String, dynamic>) {
  //       actionStatus = Map<String, dynamic>.from(json['action_status'] as Map);
  //     }

  //     // ✅ Custom fields parsing
  //     List<CustomFields>? customFields = [];

  //     if (json['customFields'] != null && json['customFields'] is List) {
  //       customFields = (json['customFields'] as List)
  //           .map((v) => CustomFields.fromJson(v as Map<String, dynamic>))
  //           .toList();
  //     }

  //     // ✅ Custom field values parsing
  //     CustomFieldValues? customFieldValues;

  //     if (json['customFieldValues'] != null) {
  //       if (json['customFieldValues'] is Map<String, dynamic>) {
  //         customFieldValues = CustomFieldValues.fromJson(
  //             json['customFieldValues'] as Map<String, dynamic>);
  //       } else if (json['customFieldValues'] is List) {
  //         var list = json['customFieldValues'] as List;
  //         if (list.isNotEmpty && list.first is Map<String, dynamic>) {
  //           customFieldValues =
  //               CustomFieldValues.fromJson(list.first as Map<String, dynamic>);
  //         }
  //       }
  //     }

  //     print(
  //         "✅ WorkModel parsed: ID=$id, Title=$title, Status=$statusId, Priority=$priorityId, ActionStatus=$action_status");

  //     // ✅ Return WorkModel with all parsed variables
  //     return WorkModel(
  //       id: id,
  //       title: title,
  //       status: status,
  //       statusId: statusId,
  //       location: location,
  //       active: active,
  //       priority: priority,
  //       priorityId: priorityId,
  //       taskCount: taskCount,
  //       users: users,
  //       userId: userId,
  //       clients: clients,
  //       clientId: clientId,
  //       tags: tags,
  //       tagIds: tagIds,
  //       startDate: startDate,
  //       completedAt: completedAt,
  //       endDate: endDate,
  //       budget: budget,
  //       taskAccessibility: taskAccessibility,
  //       description: description,
  //       note: note,
  //       createdType: createdType,
  //       favorite: favorite,
  //       pinned: pinned,
  //       createdAt: createdAt,
  //       updatedAt: updatedAt,
  //       createType: createType,
  //       asset: asset,
  //       assetId: assetId,
  //       assigned_to: assigned_to,
  //       action_status: action_status,
  //       actionStatus: actionStatus,
  //       enable: enable,
  //       clientCanDiscuss: clientCanDiscuss,
  //       customFields: customFields,
  //       customFieldValues: customFieldValues,
  //       // woStatusData: woStatusData,
  //       // priorityDatas: priorityDatas,
  //     );
  //   } catch (e, stackTrace) {
  //     print("❌ Error parsing WorkModel: $e");
  //     print("Stack trace: $stackTrace");
  //     print("Problematic JSON: $json");
  //     rethrow;
  //   }
  // }

  Future<void> loadStatusData() async {
    this.woStatusData = await HiveStorage.getAllStatusData();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['status'] = status;
    data['status_id'] = statusId;
    data['action_status'] = action_status;
    data['priority'] = priority;
    data['task_count'] = taskCount;
    data['priority_id'] = priorityId;
    data['create_type'] = createType;
    if (users != null) {
      data['users'] = users!.map((v) => v.toJson()).toList();
    }
    data['user_id'] = userId;
    if (clients != null) {
      data['clients'] = clients!.map((v) => v.toJson()).toList();
    }
    data['client_id'] = clientId;
    if (tags != null) {
      data['tags'] = tags!.map((v) => v.toJson()).toList();
    }
    data['tag_ids'] = tagIds;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['budget'] = budget;
    data['task_accessibility'] = taskAccessibility;
    data['client_can_discuss'] = this.clientCanDiscuss;
    data['enable'] = this.enable;
    data['description'] = description;
    data['note'] = note;
    data['created_type'] = createdType;
    data['favorite'] = favorite;
    data['pinned'] = pinned;
    data['action_status'] = actionStatus;
    data['asset'] = asset;
    data['asset_id'] = assetId;
    data['assigned_to'] = assigned_to;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (this.customFields != null) {
      data['customFields'] = this.customFields!.map((v) => v.toJson()).toList();
    }
    if (this.customFieldValues != null) {
      data['customFieldValues'] = this.customFieldValues!.toJson();
    }
    return data;
  }

  // ✅ Helper method to format dates for display
  String? getFormattedDueDate() {
    if (endDate == null || endDate!.isEmpty) return 'null';
    try {
      final date = DateTime.parse(endDate!);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return null;
    }
  }

  String? getFormattedStartDate() {
    if (startDate == null || startDate!.isEmpty) return null;
    try {
      final date = DateTime.parse(startDate!);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return null;
    }
  }

  factory WorkModel.empty() {
    return WorkModel(
      id: 0,
      title: "",
      status: "",
      active: 1,
      location: 0,
      statusId: 0,
      priority: "",
      taskCount: 0,
      priorityId: 0,
      users: [],
      userId: [],
      clients: [],
      clientId: [],
      tags: [],
      tagIds: [],
      startDate: "",
      endDate: "",
      budget: "",
      taskAccessibility: "",
      description: "",
      note: "",
      createdType: "",
      favorite: 0,
      action_status: 0,
      pinned: 0,
      assetId: 0,
      createdAt: "",
      clientCanDiscuss: 0,
      enable: 1,
      updatedAt: "",
      createType: "",
      workType: "",
      customFields: [],
      asset: {},
      actionStatus: {},
      assigned_to: {},
      customFieldValues: null,
    );
  }
}

class WorkUsers {
  int? id;
  String? firstName;
  String? lastName;
  String? photo;
  String? email;
  String? team_name;

  WorkUsers({
    this.id,
    this.firstName,
    this.lastName,
    this.photo,
    this.team_name,
    this.email,
  });

  WorkUsers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
    team_name = json['team_name'];
    photo = json['photo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['email'] = email;
    data['team_name'] = team_name;
    data['photo'] = photo;
    return data;
  }
}

class WorkClients {
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  String? photo;

  WorkClients({this.id, this.firstName, this.lastName, this.photo});

  WorkClients.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    photo = json['photo'];
    email = json['email'];
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

class Tag {
  int? id;
  String? title;

  Tag({this.id, this.title});

  Tag.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    return data;
  }
}

class CustomFields {
  int? id;
  String? module;
  String? fieldLabel;
  String? name;
  String? fieldType;
  String? guideText;
  List<String>? options;
  String? required;
  String? visibility;
  String? createdAt;
  String? updatedAt;

  CustomFields({
    this.id,
    this.module,
    this.fieldLabel,
    this.name,
    this.fieldType,
    this.guideText,
    this.options,
    this.required,
    this.visibility,
    this.createdAt,
    this.updatedAt,
  });
  factory CustomFields.empty() {
    return CustomFields(
      id: null,
      module: null,
      fieldLabel: null,
      name: null,
      fieldType: null,
      guideText: null,
      options: [],
      required: null,
      visibility: null,
      createdAt: null,
      updatedAt: null,
    );
  }
  CustomFields.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    module = json['module'];
    fieldLabel = json['field_label'];
    name = json['name'];
    fieldType = json['field_type'];
    guideText = json['guide_text'];
    options = json['options'] != null
        ? (json['options'] as List).cast<String>()
        : [];

    required = json['required'];
    visibility = json['visibility'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['module'] = this.module;
    data['field_label'] = this.fieldLabel;
    data['name'] = this.name;
    data['field_type'] = this.fieldType;
    data['guide_text'] = this.guideText;
    data['options'] = this.options;
    data['required'] = this.required;
    data['visibility'] = this.visibility;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class CustomFieldValues {
  Map<String, dynamic> values;

  CustomFieldValues({required this.values});

  factory CustomFieldValues.fromJson(Map<String, dynamic> json) {
    return CustomFieldValues(values: json);
  }

  Map<String, dynamic> toJson() {
    return values;
  }
}
