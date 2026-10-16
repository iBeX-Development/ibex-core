import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../data/model/dashboard_stats/dashboard_stats_model.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import 'dash_board_stats_event.dart';
import 'dash_board_stats_state.dart';

import 'package:logger/logger.dart';

final logger = Logger();

class DashBoardStatsBloc
    extends Bloc<DashBoardStatsEvent, DashBoardStatsState> {
  int? totalRequestedWorks;
  int? totalOpenWorks;
  int? totalCompletedWorks;
  int? totalProject;
  int? totalTask;
  int? totaluser;
  int? totalClient;
  int? totalMeeting;
  int? totalTodos;
  int? completedTodos;
  int? pendingTodos;
  List<StatusWiseProjects> projectStats = [];
  List<StatusWiseTasks> taskStats = [];

  DashBoardStatsBloc() : super(DashBoardStatsInitial()) {
    on<StatsList>(_onAllStat);
  }

  Future<void> _onAllStat(
      StatsList event, Emitter<DashBoardStatsState> emit) async {
    try {
      emit(DashBoardStatsLoading());
      Map<String, dynamic> result = {};
      //neeh
      // await DashboardStatsRepo().getDashboardStats();
      totalRequestedWorks = 111;
      totalOpenWorks = 11;
      totalCompletedWorks = 121;
      totalProject = 12;
      totalTask = 123;
      totaluser = 13;
      totalClient = 11;
      totalMeeting = 21;
      totalTodos = 12;
      completedTodos = 1;
      pendingTodos = 11;
      projectStats = [];
      taskStats = [];

      // neeh
      // totalProject = result['data']['total_projects'];
      // totalTask = result['data']['total_tasks'];
      // totaluser = result['data']['total_users'];
      // totalClient = result['data']['total_clients'];
      // totalMeeting = result['data']['total_meetings'];
      // totalTodos = result['data']['total_todos'];
      // completedTodos = result['data']['completed_todos'];
      // pendingTodos = result['data']['pending_todos'];
      // print("hekh ${result['data']['status_wise_projects'].runtimeType}");
      // projectStats =result['data']['status_wise_projects'];
      // final data = result['data'] ?? []; // Extract the 'data' map
      final projectList = [
        {
          "id": 1,
          "title": "Incomplete",
          "color": "secondary",
          "chart_color": "0XffCC99CC",
          "total_projects": 13
        },
        {
          "id": 2,
          "title": "complete",
          "color": "success",
          "chart_color": "0Xff9933FF",
          "total_projects": 1
        },
        {
          "id": 3,
          "title": "Done",
          "color": "success",
          "chart_color": "0XffFFCC00",
          "total_projects": 0
        }
      ]; // Extract the List

      projectStats = projectList
          .map((projectData) => StatusWiseProjects.fromJson(projectData))
          .toList();
      final taskList = [
        {
          "id": 1,
          "title": "Incomplete",
          "color": "secondary",
          "chart_color": "0Xff9933FF",
          "total_tasks": 6
        },
        {
          "id": 2,
          "title": "complete",
          "color": "success",
          "chart_color": "0XffFF9999",
          "total_tasks": 3
        },
        {
          "id": 3,
          "title": "Done",
          "color": "success",
          "chart_color": "0Xff999999",
          "total_tasks": 1
        }
      ]; // Extract the List

      taskStats = taskList
          .map((projectData) => StatusWiseTasks.fromJson(projectData))
          .toList();
      // taskStats = result['data']['status_wise_tasks'];
      if (!result.containsKey('error')) {
        emit(DashBoardStatsSuccess(
            totalmeeting: totalMeeting!,
            totalclient: totalClient!,
            totalproject: totalProject!,
            totalrequestedworks: totalRequestedWorks!,
            totalopenworks: totalOpenWorks!,
            totalcompletedworks: totalCompletedWorks!,
            totaltask: totalTask!,
            totaltodos: totalTodos!,
            totaluser: totaluser!,
            statusWiseProject: projectStats,
            statusWiseTask: taskStats));
      }
      if (result.containsKey('errors')) {
        emit((DashBoardStatsError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e(e);
      emit((DashBoardStatsError("Error: $e")));
    }
  }
}
