import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/work_discussion/work_trade/work_trade_event.dart';
import 'package:ibex/bloc/work_discussion/work_trade/work_trade_state.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';

import '../../../api_helper/api.dart';
import '../../../data/model/work/trade.dart';
import '../../../data/repositories/Work/work_repo.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkTradeBloc extends Bloc<WorkTradeEvent, WorkTradeState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;
  WorkTradeBloc() : super(WorkTradeInitial()) {
    on<WorkTradeList>(_getTradeLists);
    on<WorkTradeLoadMore>(_onLoadMoreWorkTrade);
    on<DeleteWorkTrade>(_onDeleteWorkTrade);
    on<SearchWorkTrade>(_onSearchWorkTrade);
    on<WorkTradeCreated>(_onCreateTradeWork);
    on<UpdateTradeWork>(_onUpdateWorkTrade);
  }

  Future<void> _getTradeLists(
    WorkTradeList event,
    Emitter<WorkTradeState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(WorkTradeLoading());

      List<WorksTrade> workpart = [];

      Map<String, dynamic> result = await WorkRepo().getWorksTrade(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: '',
        dateBetweenFrom: event.dateBetweenFrom,
        dateBetweenTo: event.dateBetweenTo,
        status: event.status,
      );

      workpart = List<WorksTrade>.from(
        result['data'].map((workData) => WorksTrade.fromJson(workData)),
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
          WorkTradePaginated(
            WorkTrade: workpart,
            hasReachedMax: _hasReachedMax,
          ),
        );
      } else {
        emit(WorkTradeError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d("Error: $e");
      }
      emit(WorkTradeError("Error: $e"));
    }
  }

  void _onDeleteWorkTrade(
    DeleteWorkTrade event,
    Emitter<WorkTradeState> emit,
  ) async {
    // if (emit is NotesSuccess) {
    final work = event.workTradeId;

    try {
      Map<String, dynamic> result = await WorkRepo().getDeleteWorkTrade(
        id: work.toString(),
        token: true,
      );
      if (result['data']['error'] == false) {
        emit(WorkTradeDeleteSuccess());
      }
      if (result['data']['error'] == true) {
        emit((WorkTradeDeleteError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(WorkTradeError(e.toString()));
    }
    // }
  }

  Future<void> _onCreateTradeWork(
    WorkTradeCreated event,
    Emitter<WorkTradeState> emit,
  ) async {
    try {
      List<WorksTrade> work = [];

      emit(WorkTradeCreateLoading());
      var result = await WorkRepo().createWorkTrade(
        id: event.projId,
        title: event.title,
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        desc: event.desc,
        cost: event.cost,
      );
      if (!result.containsKey('error')) {
        emit(WorkTradeCreateSuccess(work));
      }
      if (result.containsKey('errors')) {
        emit(WorkTradeCreateError(result['message']));
        flutterToastCustom(msg: result['message']);
        // add(WorkDashBoardList());
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((WorkTradeError("Error: $e")));
    }
  }

  // void _selectWork(SelectedWork event, Emitter<WorkState> emit) {
  //   if (state is WorkSuccess) {
  //     final currentState = state as WorkSuccess;
  //     emit(WorkSuccess(currentState.work, event.selectedIndex,
  //         event.selectedTitle, false));
  //   }

  void _onUpdateWorkTrade(
    UpdateTradeWork event,
    Emitter<WorkTradeState> emit,
  ) async {
    if (state is WorkTradePaginated) {
      List<WorksTrade> workpart = [];
      final id = event.id;
      final workId = event.workId;
      final title = event.title;
      final status = event.status;
      final startDate = event.startDate;
      final endDate = event.endDate;
      final desc = event.desc;
      final cost = event.cost;
      final progress = event.progress;

      emit(WorkTradeEditLoading());
      // Try to update the task via the repository
      try {
        Map<String, dynamic> updatedWork = await WorkRepo().updateWorkTrade(
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
          emit(WorkTradeEditSuccess(workpart));
          // add(WorkDashBoardList());
          // add(WorkList());
        }
        if (updatedWork['error'] == true) {
          flutterToastCustom(msg: updatedWork['message']);
          // add(WorkDashBoardList());
          emit(WorkTradeEditError(updatedWork['message']));
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating Task: $e');
        }
      }
    }
  }

  Future<void> _onSearchWorkTrade(
    SearchWorkTrade event,
    Emitter<WorkTradeState> emit,
  ) async {
    try {
      List<WorksTrade> workpart = [];
      _offset = 0;
      emit(WorkTradeLoading());
      var result = await WorkRepo().getWorksTrade(
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
        workpart = List<WorksTrade>.from(
          result['data'].map((workData) => WorksTrade.fromJson(workData)),
        );
        bool hasReachedMax = workpart.length < _limit;
        emit(
          WorkTradePaginated(WorkTrade: workpart, hasReachedMax: hasReachedMax),
        );
      } else if (result.containsKey('errors')) {
        emit(WorkTradeError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      emit(WorkTradeError("Error: $e"));
    }
  }

  Future<void> _onLoadMoreWorkTrade(
    WorkTradeLoadMore event,
    Emitter<WorkTradeState> emit,
  ) async {
    if (state is WorkTradePaginated && !_hasReachedMax) {
      try {
        final currentState = state as WorkTradePaginated;
        final updatedWork = List<WorksTrade>.from(currentState.WorkTrade);

        // Fetch additional Works from the repository
        Map<String, dynamic> result = await WorkRepo().getWorksTrade(
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
        final additional = List<WorksTrade>.from(
          result['data'].map((workData) => WorksTrade.fromJson(workData)),
        );

        if (additional.isEmpty) {
          _hasReachedMax = true;
        } else {
          _offset += _limit; // Increment the offset consistently
          updatedWork.addAll(additional);
        }

        if (!result.containsKey('error')) {
          emit(
            WorkTradePaginated(
              WorkTrade: updatedWork,
              hasReachedMax: _hasReachedMax,
            ),
          );
        } else {
          emit(WorkTradeError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } on ApiException catch (e) {
        emit(WorkTradeError("Error: $e"));
      }
    }
  }
}
