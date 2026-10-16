import 'package:flutter/foundation.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AccountDeletion {
  Future<Map<String, dynamic>> getDeleteAccount() async {
    try {
      final response = await ApiBaseHelper.delete(
          url: accountdeletionsurl, useAuthToken: true, body: {});
      if (response['error'] = true) {
        return {};
      }
      return response as Map<String, dynamic>;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
  }
}
