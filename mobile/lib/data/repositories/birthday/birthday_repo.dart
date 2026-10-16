import 'package:flutter/foundation.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class BirthdayRepo{
  Future<Map<String, dynamic>> getBirthday(
      {
        int? offset,
        int? limit,
        required bool token,
         int? upComingDays,
        List<int>? userId,
        List<int>? clientId
      }) async {


    try {

      Map<String, dynamic> body = {};

      if (limit != null) {
        body["limit"] = limit;
      }

      if (offset != null) {
        body["offset"] = offset;
      }
      if (upComingDays != null && upComingDays != 0) {
        body["upcoming_days"] = upComingDays;
      }
      if (userId != null) {
        body["user_ids[]"] = userId;
      }
      if (userId != null) {
        body["client_ids[]"] = clientId;
      }


          final response = await ApiBaseHelper.getApi(
        url: getBirthdayUrl,
        useAuthToken: true, params: body,


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