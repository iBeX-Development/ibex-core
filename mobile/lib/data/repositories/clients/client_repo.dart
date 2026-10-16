import 'package:flutter/foundation.dart';
import 'package:ibex/data/model/clients/all_client_model.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ClientRepo {
  Future<Map<String, dynamic>> getClients({
    int? id,
    int? offset,
    int? limit,
    String? search,
    required bool token,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("Client REPO ");
      }
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
      final response = await ApiBaseHelper.getApi(
        url: id != null ? "$getClientUrl/$id" : getClientUrl,
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

  Future<Map<String, dynamic>> createClient({
    required AllClientModel client,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": client.id,
        "first_name": client.firstName,
        "last_name": client.lastName,
        "role": client.role,
        "company": client.company,
        "email": client.email,
        "phone": client.phone,
        "country_code": client.countryCode,
        "country_iso_code": client.countryIsoCode,
        "password": client.password,
        "password_confirmation": client.passwordConfirmation,
        "type": client.type,
        "address": client.address,
        "city": client.type,
        "state": client.state,
        "country": client.country,
        "zip": client.zip,
        "profile": client.uploadPicture,
        "status": client.status,
        "internal_purpose": client.internalPurpose,
        "email_verification_mail_sent": client.emailVerificationMailSent,
        "email_verified_at": client.emailVerificationMailSent,
        "created_at": client.createdAt,
        "updated_at": client.updatedAt,
        "assigned": client.assigned,
      };

      if (kDebugMode) {

        logger.d('Request Body: ${client.toJson()}');

      }

      final response = await ApiBaseHelper.post(
        url: createClientUrl,
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

  Future<Map<String, dynamic>> getDeleteClient({
    required int id,
    required bool token,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("rftgyhujikl Id $id");
      }
      final response = await ApiBaseHelper.delete(
        url: "$deleteClientUrl/$id",
        useAuthToken: true,
        body: {},
      );
      if (kDebugMode) {
        logger.d("sedrftgyhujikl $response");
      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }

  Future<Map<String, dynamic>> updateClient({
    required AllClientModel client,
  }) async {
    if (kDebugMode) {
      logger.d("Updating Client...");
    }
    try {
      // Send the request to update the Client
      final response = await ApiBaseHelper.post(
        url: updateClientUrl,
        useAuthToken: true,
        body: client.toJson(),
      );

      // Assuming the response contains the updated Client data
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
}
