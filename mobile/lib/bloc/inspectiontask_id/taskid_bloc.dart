import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../api_helper/api.dart';
import '../../data/model/inspectiontask/task_model.dart';
import '../../data/repositories/inspectiontask/task_repo.dart';

import 'taskid_event.dart';
import 'taskid_state.dart';
// import '../inspectiontask/task_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionTaskidBloc
    extends Bloc<InspectionTaskidEvent, InspectionTaskidState> {
  InspectionTaskidBloc() : super(InspectionTaskidInitial()) {
    on<InspectionTaskIdListId>(_getTaskListId);
    on<UpdateTaskCompletion>(_updateTaskCompletion);
  }

  Future<void> _getTaskListId(
      InspectionTaskIdListId event, Emitter<InspectionTaskidState> emit) async {
    try {
      List<InspectionTasks> taskList = [];

      // emit(InspectionTaskidLoading());
      if (state is InspectionTaskidWithId) {
        var oldData = state as InspectionTaskidWithId;
        // Preserve old data if needed
      } else {
        emit(InspectionTaskidLoading());
      }

      Map<String, dynamic> result = await InspectionTaskRepo().getTask(
        id: event.id,
        token: true,
      );
      taskList = List<InspectionTasks>.from(
          result['data'].map((taskData) => InspectionTasks.fromJson(taskData)));

      // if (state is InspectionTaskidWithId) {
      //   bool flag = false;
      //   for (var i = 0; i < existingTasks.length; i++) {
      //     if (event.id == existingTasks[i].id) {
      //       existingTasks[i] = taskList[0];
      //       flag = true;
      //     }
      //   }

      //   print("existingTasks.length ${existingTasks.length}");
      //   for (var i = 0; i < existingTasks.length; i++) {}
      //   if (!flag) {
      //     existingTasks.addAll(taskList);
      //   }
      //   emit(InspectionTaskidWithId(
      //     existingTasks,
      //   ));
      //   return;
      // }
      emit(InspectionTaskidWithId(
        taskList,
      ));
    } on ApiException catch (e) {
      logger.e("API Exception: $e");
      // emit((TaskError("Error: $e")));
    }
  }

  Future<void> _updateTaskCompletion(
      UpdateTaskCompletion event, Emitter<InspectionTaskidState> emit) async {
    try {
      await InspectionTaskRepo().updateTaskCompletion(
        taskId: event.taskId,
        value: event.value,
      );

      // Optionally refresh the task list after update
      if (kDebugMode) {
        logger.i('Task ${event.taskId} updated with value: ${event.value}');
      }
    } on ApiException catch (e) {
      logger.e('Error updating task completion: $e');
    }
  }
}
