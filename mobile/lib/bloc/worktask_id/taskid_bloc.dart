import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../api_helper/api.dart';
import '../../data/model/worktask/task_model.dart';
import '../../data/repositories/worktask/task_repo.dart';

import 'taskid_event.dart';
import 'taskid_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// import '../worktask/task_state.dart';

class WorkTaskidBloc extends Bloc<WorkTaskidEvent, WorkTaskidState> {
  WorkTaskidBloc() : super(WorkTaskidInitial()) {
    on<WorkTaskIdListId>(_getTaskListId);
  }
  Future<void> _getTaskListId(
      WorkTaskIdListId event, Emitter<WorkTaskidState> emit) async {
    try {
      List<WorkTasks> taskList = [];

      List<WorkTasks> existingTasks = [];
      // emit(WorkTaskidLoading());
      if (state is WorkTaskidWithId) {
        var oldData = state as WorkTaskidWithId;
        existingTasks = oldData.task;
      } else {
        emit(WorkTaskidLoading());
      }

      Map<String, dynamic> result = await WorkTaskRepo().getTask(
        id: event.id,
        token: true,
      );
      taskList = List<WorkTasks>.from(
          result['data'].map((taskData) => WorkTasks.fromJson(taskData)));

      // if (state is WorkTaskidWithId) {
      //   bool flag = false;
      //   for (var i = 0; i < existingTasks.length; i++) {
      //     if (event.id == existingTasks[i].id) {
      //       existingTasks[i] = taskList[0];
      //       flag = true;
      //     }
      //   }

      //   for (var i = 0; i < existingTasks.length; i++) {}
      //   if (!flag) {
      //     existingTasks.addAll(taskList);
      //   }
      //   emit(WorkTaskidWithId(
      //     existingTasks,
      //   ));
      //   return;
      // }
      emit(WorkTaskidWithId(
        taskList,
      ));
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }

      // emit((TaskError("Error: $e")));
    }
  }
}
