import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/work_discussion/work_milestone/work_milestone_event.dart';
import 'package:ibex/bloc/work_discussion/work_milestone/work_milestone_state.dart';

import 'package:ibex/utils/widgets/toast_widget.dart';

import '../../../api_helper/api.dart';
import '../../../data/model/work/milestone.dart';
import '../../../data/repositories/Work/work_repo.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// import '../project_id/projectid_event.dart';

class WorkMilestoneBloc extends Bloc<WorkMilestoneEvent, WorkMilestoneState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;
  WorkMilestoneBloc() : super(WorkMilestoneInitial()) {
    on<WorkMileStoneList>(_getMileStoneLists);
    on<WorkMilestoneLoadMore>(_onLoadMoreWorkMilestone);
    on<DeleteWorkMilestone>(_deleteWorkMilestone);
    on<SearchWorkMilestone>(_onSearchWorkMilestone);
    on<WorkMilestoneCreated>(_createMilestoneWork);
    on<UpdateMilestoneWork>(_updateWorkMilestone);
  }

  Future<void> _getMileStoneLists(
    WorkMileStoneList event,
    Emitter<WorkMilestoneState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(WorkMilestoneLoading());
      List<WorksMilestone> milestone = [];
      Map<String, dynamic> result = await WorkRepo().getWorksMilestone(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: '',
        dateBetweenFrom: event.dateBetweenFrom,
        dateBetweenTo: event.dateBetweenTo,
        startDateFrom: event.startDateFrom,
        startDateTo: event.startDateTo,
        endDateFrom: event.endDateFrom,
        endDateTo: event.endDateTo,
        status: event.status,
      );
      milestone = List<WorksMilestone>.from(
        result['data'].map(
          (projectData) => WorksMilestone.fromJson(projectData),
        ),
      );
      if (event.id != null) {
        _offset = 0;
      } else {
        _offset += _limit;
      }
      _hasReachedMax = milestone.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(
          WorkMilestonePaginated(
            WorkMilestone: milestone,
            hasReachedMax: _hasReachedMax,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((WorkMilestoneError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }

      emit((WorkMilestoneError("Error: $e")));
    }
  }

  void _deleteWorkMilestone(
    DeleteWorkMilestone event,
    Emitter<WorkMilestoneState> emit,
  ) async {
    // if (emit is NotesSuccess) {
    final project = event.workMilestoneId;

    try {
      Map<String, dynamic> result = await WorkRepo().getDeleteWork(
        id: project.toString(),
        token: true,
      );
      if (result['data']['error'] == false) {
        emit(WorkMilestoneDeleteSuccess());
      }
      if (result['data']['error'] == true) {
        emit((WorkMilestoneDeleteError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(WorkMilestoneError(e.toString()));
    }
    // }
  }

  Future<void> _createMilestoneWork(
    WorkMilestoneCreated event,
    Emitter<WorkMilestoneState> emit,
  ) async {
    try {
      List<WorksMilestone> project = [];

      emit(WorkMilestoneCreateLoading());
      var result = await WorkRepo().createWorkMilestone(
        id: event.projId,
        title: event.title,
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        desc: event.desc,
        cost: event.cost,
      );
      if (!result.containsKey('error')) {
        emit(WorkMilestoneCreateSuccess(project));
      }
      if (result.containsKey('errors')) {
        emit(WorkMilestoneCreateError(result['message']));
        flutterToastCustom(msg: result['message']);
        // add(WorkDashBoardList());
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }

      emit((WorkMilestoneError("Error: $e")));
    }
  }

  // void _selectWork(SelectedWork event, Emitter<WorkState> emit) {
  //   if (state is WorkSuccess) {
  //     final currentState = state as WorkSuccess;
  //     emit(WorkSuccess(currentState.project, event.selectedIndex,
  //         event.selectedTitle, false));
  //   }

  void _updateWorkMilestone(
    UpdateMilestoneWork event,
    Emitter<WorkMilestoneState> emit,
  ) async {
    // if (state is WorkMilestonePaginated) {
    //   List<WorksMilestone> milestone = [];
    //   final id = event.id;
    //   final title = event.title;
    //   final status = event.status;
    //   final startDate = event.startDate;
    //   final endDate = event.endDate;
    //   final desc = event.desc;
    //   final cost = event.cost;
    //   final progress = event.progress;
    //
    //   emit(WorkMilestoneEditLoading());
    //   // Try to update the task via the repository
    //   try {
    //     Map<String, dynamic> updatedWork =
    //         await WorkRepo().updateWorkMilestone(
    //       id: id,
    //       title: title,
    //       status: status,
    //       startDate: startDate,
    //       endDate: endDate,
    //       desc: desc,
    //       cost: cost,
    //           progress:progress
    //     );
    //     // project = List<WorkModel>.from(updatedWork['data']
    //     //     .map((projectData) => WorkModel.fromJson(projectData)));
    //     if (updatedWork['error'] == false) {
    //       emit(WorkMilestoneEditSuccess(milestone));
    //       // add(WorkDashBoardList());
    //       // add(WorkList());
    //     }
    //     if (updatedWork['error'] == true) {
    //       flutterToastCustom(msg: updatedWork['message']);
    //       // add(WorkDashBoardList());
    //       emit(WorkMilestoneEditError(updatedWork['message']));
    //     }
    //   } catch (e) {
    //     print('Error while updating Task: $e');
    //   }
    // }
  }

  Future<void> _onSearchWorkMilestone(
    SearchWorkMilestone event,
    Emitter<WorkMilestoneState> emit,
  ) async {
    try {
      List<WorksMilestone> milestone = [];
      _offset = 0;
      emit(WorkMilestoneLoading());
      var result = await WorkRepo().getWorksMilestone(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: event.searchQuery,
        dateBetweenFrom: event.dateBetweenFrom,
        dateBetweenTo: event.dateBetweenTo,
        startDateFrom: event.startDateFrom,
        startDateTo: event.startDateTo,
        endDateFrom: event.endDateFrom,
        endDateTo: event.endDateTo,
      );

      if (!result.containsKey('error')) {
        milestone = List<WorksMilestone>.from(
          result['data'].map(
            (projectData) => WorksMilestone.fromJson(projectData),
          ),
        );
        bool hasReachedMax = milestone.length < _limit;
        emit(
          WorkMilestonePaginated(
            WorkMilestone: milestone,
            hasReachedMax: hasReachedMax,
          ),
        );
      } else if (result.containsKey('errors')) {
        emit(WorkMilestoneError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      emit(WorkMilestoneError("Error: $e"));
    }
  }

  Future<void> _onLoadMoreWorkMilestone(
    WorkMilestoneLoadMore event,
    Emitter<WorkMilestoneState> emit,
  ) async {
    if (state is WorkMilestonePaginated && !_hasReachedMax) {
      try {
        final currentState = state as WorkMilestonePaginated;
        final updatedWork = List<WorksMilestone>.from(
          currentState.WorkMilestone,
        );

        // Fetch additional Works from the repository
        Map<String, dynamic> result = await WorkRepo().getWorksMilestone(
          limit: _limit,
          offset: _offset,
          search: event.searchQuery,
          dateBetweenFrom: event.dateBetweenFrom,
          dateBetweenTo: event.dateBetweenTo,
          startDateFrom: event.startDateFrom,
          startDateTo: event.startDateTo,
          endDateFrom: event.endDateFrom,
          endDateTo: event.endDateTo,
        );
        final additional = List<WorksMilestone>.from(
          result['data'].map(
            (projectData) => WorksMilestone.fromJson(projectData),
          ),
        );

        if (additional.isEmpty) {
          _hasReachedMax = true;
        } else {
          _offset += _limit; // Increment the offset consistently
          updatedWork.addAll(additional);
        }

        if (!result.containsKey('error')) {
          emit(
            WorkMilestonePaginated(
              WorkMilestone: updatedWork,
              hasReachedMax: _hasReachedMax,
            ),
          );
        } else {
          emit(WorkMilestoneError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } on ApiException catch (e) {
        emit(WorkMilestoneError("Error: $e"));
      }
    }
  }
}
