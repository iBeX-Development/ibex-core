import 'package:flutter/foundation.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class IncomeExpenseRepo {
  Future<Map<String, dynamic>> getIncomeExpense({
    String? startDate,
    String? endDate,
    required bool token,
  }) async {
    try {
      if (kDebugMode) {
        logger.d("Client REPO $startDate");
      }
      if (kDebugMode) {
        logger.d("Client REPO $endDate");
      }

      // Create a params map
      final Map<String, String> params = {};

      // Add startDate and endDate if they are not null
      if (startDate != null) {
        params['start_date'] = startDate;
      }
      if (endDate != null) {
        params['end_date'] = endDate;
      }

      final response = await ApiBaseHelper.getApi(
        url: incomeVsExpenseUrl,
        useAuthToken: true,
        params: params, // Pass the params map here
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
