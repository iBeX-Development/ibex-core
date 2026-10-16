import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../api_helper/api.dart';
import '../../data/model/Work/all_work.dart';
import '../../data/repositories/Work/work_repo.dart';
import '../../data/localStorage/hive.dart';

import 'workid_event.dart';
import 'workid_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkidBloc extends Bloc<WorkidEvent, WorkidState> {
  List<Object> woStatusData = [];
  WorkidBloc() : super(WorkidInitial()) {
    _initializeStatusData();
    on<WorkIdListId>(_getprojectListId);
  }

  Future<void> _initializeStatusData() async {
    woStatusData = await HiveStorage.getAllStatusData();
  }

  Future<void> _getprojectListId(
      WorkIdListId event, Emitter<WorkidState> emit) async {
    try {
      List<WorkModel> projects = [];

      List<WorkModel> existingprojects = [];

      if (state is WorkidWithId) {
        var oldData = state as WorkidWithId;
        emit(WorkidLoading());
        existingprojects = oldData.work;
      } else {
        emit(WorkidLoading());
      }

      Map<String, dynamic> result = await WorkRepo().getWorks(
        id: event.id,
      );
      var data = result['data'];
      if (data is List) {
        projects = data
            .map((projectData) => WorkModel.fromJson(projectData, woStatusData))
            .toList();
      } else if (data is Map) {
        // Хэрвээ ганцхан объект ирвэл List болгож хөрвүүлнэ
        projects = [
          WorkModel.fromJson(Map<String, dynamic>.from(data), woStatusData)
        ];
      } else {
        projects = [];
      }

      if (state is WorkidWithId) {
        bool flag = false;
        for (var i = 0; i < existingprojects.length; i++) {
          if (event.id == existingprojects[i].id) {
            existingprojects[i] = projects[0];

            flag = true;
          }
        }
        for (var i = 0; i < existingprojects.length; i++) {}
        if (!flag) {
          existingprojects.addAll(projects);
        }

        emit(WorkidWithId(
          existingprojects,
        ));
        return;
      }
      emit(WorkidWithId(
        projects,
      ));
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      // emit((projectError("Error: $e")));
    }
  }
}
