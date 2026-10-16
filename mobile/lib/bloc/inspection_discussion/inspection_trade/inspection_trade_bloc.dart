import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/inspection_discussion/inspection_trade/inspection_trade_event.dart';
import 'package:ibex/bloc/inspection_discussion/inspection_trade/inspection_trade_state.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';

import '../../../api_helper/api.dart';
import '../../../data/model/inspection/trade.dart';
import '../../../data/repositories/inspection/inspection_repo.dart';

import 'package:logger/logger.dart';

final logger = Logger();

class InspectionTradeBloc
    extends Bloc<InspectionTradeEvent, InspectionTradeState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;
  InspectionTradeBloc() : super(InspectionTradeInitial()) {
    on<InspectionTradeList>(_getTradeLists);
    on<InspectionTradeLoadMore>(_onLoadMoreInspectionTrade);
    on<DeleteInspectionTrade>(_onDeleteInspectionTrade);
    on<SearchInspectionTrade>(_onSearchInspectionTrade);
    on<InspectionTradeCreated>(_onCreateTradeInspection);
    on<UpdateTradeInspection>(_onUpdateInspectionTrade);
  }

  Future<void> _getTradeLists(
    InspectionTradeList event,
    Emitter<InspectionTradeState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(InspectionTradeLoading());

      List<InspectionsTrade> workpart = [];

      Map<String, dynamic> result = await InspectionRepo().getInspectionsTrade(
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

      workpart = List<InspectionsTrade>.from(
        result['data'].map((workData) => InspectionsTrade.fromJson(workData)),
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
          InspectionTradePaginated(
            InspectionTrade: workpart,
            hasReachedMax: _hasReachedMax,
          ),
        );
      } else {
        emit(InspectionTradeError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e("Error: $e");
      emit(InspectionTradeError("Error: $e"));
    }
  }

  void _onDeleteInspectionTrade(
    DeleteInspectionTrade event,
    Emitter<InspectionTradeState> emit,
  ) async {
    // if (emit is NotesSuccess) {
    final work = event.workTradeId;

    try {
      Map<String, dynamic> result =
          await InspectionRepo().getDeleteInspectionTrade(
        id: work.toString(),
        token: true,
      );
      if (result['data']['error'] == false) {
        emit(InspectionTradeDeleteSuccess());
      }
      if (result['data']['error'] == true) {
        emit((InspectionTradeDeleteError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      logger.e("Error: $e");
      emit(InspectionTradeError("Error: $e"));
    }
    // }
  }

  Future<void> _onCreateTradeInspection(
    InspectionTradeCreated event,
    Emitter<InspectionTradeState> emit,
  ) async {
    try {
      List<InspectionsTrade> work = [];

      emit(InspectionTradeCreateLoading());
      var result = await InspectionRepo().createInspectionTrade(
        id: event.projId,
        title: event.title,
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        desc: event.desc,
        cost: event.cost,
      );
      if (!result.containsKey('error')) {
        emit(InspectionTradeCreateSuccess(work));
      }
      if (result.containsKey('errors')) {
        emit(InspectionTradeCreateError(result['message']));
        flutterToastCustom(msg: result['message']);
        // add(InspectionDashBoardList());
      }
    } on ApiException catch (e) {
      logger.e("Error: $e");
      emit((InspectionTradeError("Error: $e")));
    }
  }

  // void _selectInspection(SelectedInspection event, Emitter<InspectionState> emit) {
  //   if (state is InspectionSuccess) {
  //     final currentState = state as InspectionSuccess;
  //     emit(InspectionSuccess(currentState.work, event.selectedIndex,
  //         event.selectedTitle, false));
  //   }

  void _onUpdateInspectionTrade(
    UpdateTradeInspection event,
    Emitter<InspectionTradeState> emit,
  ) async {
    if (state is InspectionTradePaginated) {
      List<InspectionsTrade> workpart = [];
      final id = event.id;
      final workId = event.workId;
      final title = event.title;
      final status = event.status;
      final startDate = event.startDate;
      final endDate = event.endDate;
      final desc = event.desc;
      final cost = event.cost;
      final progress = event.progress;

      emit(InspectionTradeEditLoading());
      // Try to update the task via the repository
      try {
        Map<String, dynamic> updatedInspection =
            await InspectionRepo().updateInspectionTrade(
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
        // work = List<InspectionModel>.from(updatedInspection['data']
        //     .map((workData) => InspectionModel.fromJson(workData)));
        if (updatedInspection['error'] == false) {
          emit(InspectionTradeEditSuccess(workpart));
          // add(InspectionDashBoardList());
          // add(InspectionList());
        }
        if (updatedInspection['error'] == true) {
          flutterToastCustom(msg: updatedInspection['message']);
          // add(InspectionDashBoardList());
          emit(InspectionTradeEditError(updatedInspection['message']));
        }
      } catch (e) {
        logger.e("Error while updating Task: $e");
      }
    }
  }

  Future<void> _onSearchInspectionTrade(
    SearchInspectionTrade event,
    Emitter<InspectionTradeState> emit,
  ) async {
    try {
      List<InspectionsTrade> workpart = [];
      _offset = 0;
      emit(InspectionTradeLoading());
      var result = await InspectionRepo().getInspectionsTrade(
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
        workpart = List<InspectionsTrade>.from(
          result['data'].map((workData) => InspectionsTrade.fromJson(workData)),
        );
        bool hasReachedMax = workpart.length < _limit;
        emit(
          InspectionTradePaginated(
            InspectionTrade: workpart,
            hasReachedMax: hasReachedMax,
          ),
        );
      } else if (result.containsKey('errors')) {
        emit(InspectionTradeError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      emit(InspectionTradeError("Error: $e"));
    }
  }

  Future<void> _onLoadMoreInspectionTrade(
    InspectionTradeLoadMore event,
    Emitter<InspectionTradeState> emit,
  ) async {
    if (state is InspectionTradePaginated && !_hasReachedMax) {
      try {
        final currentState = state as InspectionTradePaginated;
        final updatedInspection = List<InspectionsTrade>.from(
          currentState.InspectionTrade,
        );

        // Fetch additional Inspections from the repository
        Map<String, dynamic> result =
            await InspectionRepo().getInspectionsTrade(
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
        final additional = List<InspectionsTrade>.from(
          result['data'].map((workData) => InspectionsTrade.fromJson(workData)),
        );

        if (additional.isEmpty) {
          _hasReachedMax = true;
        } else {
          _offset += _limit; // Increment the offset consistently
          updatedInspection.addAll(additional);
        }

        if (!result.containsKey('error')) {
          emit(
            InspectionTradePaginated(
              InspectionTrade: updatedInspection,
              hasReachedMax: _hasReachedMax,
            ),
          );
        } else {
          emit(InspectionTradeError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } on ApiException catch (e) {
        emit(InspectionTradeError("Error: $e"));
      }
    }
  }
}
