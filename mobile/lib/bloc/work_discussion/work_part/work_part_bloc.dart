import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/work_discussion/work_part/work_part_event.dart';
import 'package:ibex/bloc/work_discussion/work_part/work_part_state.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';

import '../../../api_helper/api.dart';
import '../../../data/model/work/part.dart';
import '../../../data/repositories/Work/work_repo.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkPartBloc extends Bloc<WorkPartEvent, WorkPartState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;
  WorkPartBloc() : super(WorkPartInitial()) {
    on<WorkPartList>(_getPartLists);
    on<WorkPartLoadMore>(_onLoadMoreWorkPart);
    on<DeleteWorkPart>(_onDeleteWorkPart);
    on<SearchWorkPart>(_onSearchWorkPart);
    on<WorkPartCreated>(_onCreatePartWork);
    on<UpdatePartWork>(_onUpdateWorkPart);
  }

  Future<void> _getPartLists(
    WorkPartList event,
    Emitter<WorkPartState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(WorkPartLoading());

      List<WorksPart> workpart = [];

      Map<String, dynamic> result = await WorkRepo().getWorksPart(
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

      workpart = List<WorksPart>.from(
        result['data'].map((workData) => WorksPart.fromJson(workData)),
      );

      int? totalCount;

      if (result['meta'] != null) {
        totalCount =
            result['meta']['filter_count'] ?? result['meta']['total_count'];
      }

      totalCount ??= workpart.length;
      if (workpart.isNotEmpty) {
        _offset +=
            workpart.length; // Update offset based on actual fetched data
      }

      _hasReachedMax = workpart.length < _limit || (_offset >= totalCount);

      if (!result.containsKey('error')) {
        emit(
          WorkPartPaginated(WorkPart: workpart, hasReachedMax: _hasReachedMax),
        );
      } else {
        emit(WorkPartError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d("Error: $e");
      }
      emit(WorkPartError("Error: $e"));
    }
  }

  void _onDeleteWorkPart(
    DeleteWorkPart event,
    Emitter<WorkPartState> emit,
  ) async {
    // if (emit is NotesSuccess) {
    final work = event.workPartId;

    try {
      Map<String, dynamic> result = await WorkRepo().getDeleteWorkPart(
        id: work.toString(),
        token: true,
      );
      if (result['data']['error'] == false) {
        emit(WorkPartDeleteSuccess());
      }
      if (result['data']['error'] == true) {
        emit((WorkPartDeleteError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(WorkPartError(e.toString()));
    }
    // }
  }

  Future<void> _onCreatePartWork(
    WorkPartCreated event,
    Emitter<WorkPartState> emit,
  ) async {
    try {
      List<WorksPart> work = [];

      emit(WorkPartCreateLoading());
      var result = await WorkRepo().createWorkPart(
        id: event.projId,
        title: event.title,
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        desc: event.desc,
        cost: event.cost,
      );
      if (!result.containsKey('error')) {
        emit(WorkPartCreateSuccess(work));
      }
      if (result.containsKey('errors')) {
        emit(WorkPartCreateError(result['message']));
        flutterToastCustom(msg: result['message']);
        // add(WorkDashBoardList());
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((WorkPartError("Error: $e")));
    }
  }

  // void _selectWork(SelectedWork event, Emitter<WorkState> emit) {
  //   if (state is WorkSuccess) {
  //     final currentState = state as WorkSuccess;
  //     emit(WorkSuccess(currentState.work, event.selectedIndex,
  //         event.selectedTitle, false));
  //   }

  void _onUpdateWorkPart(
    UpdatePartWork event,
    Emitter<WorkPartState> emit,
  ) async {
    if (state is WorkPartPaginated) {
      List<WorksPart> workpart = [];
      final id = event.id;
      final workId = event.workId;
      final title = event.title;
      final status = event.status;
      final startDate = event.startDate;
      final endDate = event.endDate;
      final desc = event.desc;
      final cost = event.cost;
      final progress = event.progress;

      emit(WorkPartEditLoading());
      // Try to update the task via the repository
      try {
        Map<String, dynamic> updatedWork = await WorkRepo().updateWorkPart(
          id: id,
          projectId: workId,
          title: title,
          status: status,
          startDate: startDate,
          endDate: endDate,
          desc: desc,
          cost: cost,
          progress: progress,
        );
        // work = List<WorkModel>.from(updatedWork['data']
        //     .map((workData) => WorkModel.fromJson(workData)));
        if (updatedWork['error'] == false) {
          emit(WorkPartEditSuccess(workpart));
          // add(WorkDashBoardList());
          // add(WorkList());
        }
        if (updatedWork['error'] == true) {
          flutterToastCustom(msg: updatedWork['message']);
          // add(WorkDashBoardList());
          emit(WorkPartEditError(updatedWork['message']));
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating Task: $e');
        }
      }
    }
  }

  Future<void> _onSearchWorkPart(
    SearchWorkPart event,
    Emitter<WorkPartState> emit,
  ) async {
    try {
      List<WorksPart> workpart = [];
      _offset = 0;
      emit(WorkPartLoading());
      var result = await WorkRepo().getWorksPart(
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
        workpart = List<WorksPart>.from(
          result['data'].map((workData) => WorksPart.fromJson(workData)),
        );
        bool hasReachedMax = workpart.length < _limit;
        emit(
          WorkPartPaginated(WorkPart: workpart, hasReachedMax: hasReachedMax),
        );
      } else if (result.containsKey('errors')) {
        emit(WorkPartError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      emit(WorkPartError("Error: $e"));
    }
  }

  Future<void> _onLoadMoreWorkPart(
    WorkPartLoadMore event,
    Emitter<WorkPartState> emit,
  ) async {
    if (state is WorkPartPaginated && !_hasReachedMax) {
      try {
        final currentState = state as WorkPartPaginated;
        final updatedWork = List<WorksPart>.from(currentState.WorkPart);

        // Fetch additional Works from the repository
        Map<String, dynamic> result = await WorkRepo().getWorksPart(
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
        final additional = List<WorksPart>.from(
          result['data'].map((workData) => WorksPart.fromJson(workData)),
        );

        if (additional.isEmpty) {
          _hasReachedMax = true;
        } else {
          _offset += _limit; // Increment the offset consistently
          updatedWork.addAll(additional);
        }

        if (!result.containsKey('error')) {
          emit(
            WorkPartPaginated(
              WorkPart: updatedWork,
              hasReachedMax: _hasReachedMax,
            ),
          );
        } else {
          emit(WorkPartError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } on ApiException catch (e) {
        emit(WorkPartError("Error: $e"));
      }
    }
  }
}
