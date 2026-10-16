import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
final logger = Logger();

class Location {
  bool? error;
  String? message;
  int? total;
  List<LocationModel>? data;

  Location({this.error, this.message, this.total, this.data});

  Location.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    message = json['message'];
    total = json['total'];
    if (json['data'] != null) {
      data = <LocationModel>[];
      json['data'].forEach((v) {
        data!.add(LocationModel.fromJson(v));
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

class LocationModel {
  int? id;
  String? title;
  String? userCreated;
  DateTime? dateCreated;
  String? userUpdated;
  DateTime? dateUpdated;
  int? active;
  String? createdAt;
  String? updatedAt;

  LocationModel({
    this.id,
    this.title,
    this.userCreated,
    this.dateCreated,
    this.userUpdated,
    this.dateUpdated,
    this.active,
    this.createdAt,
    this.updatedAt,
  });

  LocationModel.fromJson(Map<String, dynamic> json) {
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

      createdAt = json['date_created'] ?? json['created_at'];
      updatedAt = json['date_updated'] ?? json['updated_at'];
    } catch (e) {
      if (kDebugMode) {
        logger.d("Error in LocationModel.fromJson: $e");
      }
      if (kDebugMode) {
        logger.d("JSON data: $json");
      }
      rethrow;
    }
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

    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
