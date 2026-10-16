import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
final logger = Logger();

class Asset {
  bool? error;
  String? message;
  int? total;
  List<AssetModel>? data;

  Asset({this.error, this.message, this.total, this.data});

  Asset.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    message = json['message'];
    total = json['total'];
    if (json['data'] != null) {
      data = <AssetModel>[];
      json['data'].forEach((v) {
        data!.add(AssetModel.fromJson(v));
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

class AssetModel {
  int? id;
  String? name;
  String? asset_code;
  String? model_number;
  String? userCreated;
  DateTime? dateCreated;
  String? userUpdated;
  DateTime? dateUpdated;
  int? active;
  int? location;
  String? image;
  String? description;
  dynamic status;
  String? createdAt;
  String? updatedAt;

  AssetModel({
    this.id,
    this.name,
    this.asset_code,
    this.model_number,
    this.userCreated,
    this.dateCreated,
    this.userUpdated,
    this.dateUpdated,
    this.location,
    this.active,
    this.image,
    this.description,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  AssetModel.fromJson(Map<String, dynamic> json) {
    try {
      id = json['id'];
      name = json['name'] ?? json['name'];
      asset_code = json['asset_code'] ?? json['asset_code'];
      model_number = json['model_number'] ?? json['model_number'];
      userCreated = json['user_created'];
      location = json['location'];

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
      image = json['file'];
      description = json['description'];
      status = json['status'];
    } catch (e) {
      if (kDebugMode) {
        logger.d("Error in AssetModel.fromJson: $e");
      }
      if (kDebugMode) {
        logger.d("JSON data: $json");
      }
      rethrow;
    }

    createdAt = json['date_created'] ?? json['created_at'];
    updatedAt = json['date_updated'] ?? json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    if (id != null) {
      data['id'] = id;
    }
    data['name'] = name;
    data['model_number'] = model_number;
    data['location'] = location;
    data['asset_code'] = asset_code;
    data['user_created'] = userCreated;
    data['date_created'] = dateCreated?.toIso8601String();
    data['user_updated'] = userUpdated;
    data['date_updated'] = dateUpdated?.toIso8601String();
    data['active'] = active;
    data['image'] = image;
    data['description'] = description;
    data['status'] = status;

    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
