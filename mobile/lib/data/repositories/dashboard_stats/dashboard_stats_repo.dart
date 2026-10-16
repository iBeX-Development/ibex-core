import 'package:flutter/foundation.dart';
import 'package:ibex/config/end_points.dart';
import '../../../api_helper/api_base_helper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class DashboardStatsRepo {
  int? totalProjects;
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      if (kDebugMode) {
        logger.d("getDashboardStats $getStatisticsUrl");
      }
      final response = await ApiBaseHelper.getApi(
        url: getStatisticsUrl,
        useAuthToken: true,
        params: {},
      );
      if (kDebugMode) {
        logger.d("response $response");
      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        logger.d("Error ${error.toString()}");
      }
      throw Exception('Error occurred');
    }
    //    totalProjects =   response.data['data']['total_projects'];
    //  var totalTask = response.data['data']['total_tasks'];
    // var totalUser = response.data['data']['total_users'];
    //   var totalClient = response.data['data']['total_clients'];
    //   var totalMeeting = response.data['data']['total_meetings'];
    //   var totalTodos = response.data['data']['total_todos'];
    //
    //   print("totalProjects $totalProjects");
    //   print("totalTask $totalTask");
    //   print("totalUser $totalUser");
    //   print("totalClient $totalClient");
    //   print("totalMeeting $totalMeeting");
    //   print("totalTodos $totalTodos");
    //   Box box = Hive.box(statsBox);
    //   box.put('totalProjects', totalProjects);
    //   var task = await box.get('totalProjects');
    //   print("totalProjects task $task");
    //   box.put('totalTask', totalTask);
    //   box.put('totalUser', totalUser);
    //   box.put('totalClient', totalClient);
    //   box.put('totalMeeting', totalMeeting);
    //   box.put('totalTodos', totalTodos);
    //
    //   tagss.add(Stats.fromJson(response.data['data']));
    //
    //   // print("RESPOMNSE state.statsm ${tagss.first.totalProjects}");
    //   // rows = response.data['data'] as List<dynamic>;
    //   //
    //   // for (var row in rows) {
    //   //   // tagss.add(Stats.fromJson(row as Map<String, dynamic>));
    //   // }
    //   return tagss;
    //   } catch (e, stacktrace) {
    //     print('Exception: $e');
    //     print('Stacktrace: $stacktrace');
    //   }
    //   return tagss;
  }
}
