import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../data/model/leave_request/leave_req_model.dart';
import '../../data/repositories/leave_request/leave_request_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import 'leave_request_event.dart';
import 'leave_request_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class LeaveRequestBloc extends Bloc<LeaveRequestEvent, LeaveRequestState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;

  bool _isLoading = false;
  int? statusPending;

  LeaveRequestBloc() : super(LeaveRequestInitial()) {
    on<CreateLeaveRequest>(_onLeaveRequestCreate);
    on<GetPendingLeaveRequest>(_getpendingLeaveRequest);
    on<LeaveRequestList>(_getListOfLeaveRequest);
    // on<AddLeaveRequest>(_onAddLeaveRequest);
    on<UpdateLeaveRequest>(_onUpdateLeaveRequest);
    on<DeleteLeaveRequest>(_onDeleteLeaveRequest);
    on<SearchLeaveRequest>(_onSearchLeaveRequest);
    on<LoadMoreLeaveRequest>(_onLoadMoreLeaveRequest);
    on<WeekLeaveReqList>(_onWeekLeavereq);
  }
  @override
  void onTransition(
      Transition<LeaveRequestEvent, LeaveRequestState> transition) {
    super.onTransition(transition);
  }

  Future<void> _getpendingLeaveRequest(
      GetPendingLeaveRequest event, Emitter<LeaveRequestState> emit) async {
    add(LeaveRequestList(""));

    statusPending = await LeaveRequestRepo().leaveRequestPending();
  }

  Future<void> _onWeekLeavereq(
      WeekLeaveReqList event, Emitter<LeaveRequestState> emit) async {
    try {
      List<LeaveRequests> leave = [];

      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      // emit(TodaysBirthdayLoading());
      Map<String, dynamic> result = await LeaveRequestRepo().leaveRequestList(
          limit: _limit,
          offset: _offset,
          token: true,
          fromDate: event.fromDate,
          toDate: event.toDate,
          search: '');

      leave = List<LeaveRequests>.from(result['data']
          .map((projectData) => LeaveRequests.fromJson(projectData)));
      _offset += _limit;
      _hasReachedMax = leave.length < _limit;
      if (!result.containsKey('error')) {
        emit(TodayLeavereqSuccess(
          leave: leave,
          hasReachedMax: _hasReachedMax,
        ));
        add(LeaveRequestList(""));
      }
      if (result.containsKey('errors')) {
        emit((LeaveRequestError(result['message'])));
      }
      // emit(BirthdayLoading());
      // List<Birthdays> Birthday = await BirthdayRepo().getBirthday(token: true);

      // emit(AllBirthdaySuccess(Birthday));
    } on ApiException catch (e) {
      logger.e("API Exception: $e");
      emit((LeaveRequestError("Error: $e")));
    }
  }

  Future<void> _onLeaveRequestCreate(
      CreateLeaveRequest event, Emitter<LeaveRequestState> emit) async {
    try {
      emit(LeaveRequestCreateLoading());
      Map<String, dynamic> result = await LeaveRequestRepo().createLeaveRequest(
          reason: event.reason,
          fromDate: event.fromDate,
          toDate: event.toDate,
          fromTime: event.fromTime,
          toTime: event.toTime,
          status: event.status,
          leaveVisibleToAll: event.leaveVisibleToAll,
          visibleToIds: event.visibleToIds,
          userId: event.userId,
          partialLeave: event.partialLeave,
          token: true);
      if (!result.containsKey('error')) {
        emit(const LeaveRequestCreateSuccess());
        // add(const LeaveRequestList(""));
      }
      if (result.containsKey('errors')) {
        emit((LeaveRequestCreateError(result['message'])));
        // add(const LeaveRequestList(""));
        flutterToastCustom(msg: result['message']);
      }
      // emit(LeaveRequestPaginated( LeaveRequest: LeaveRequest, hasReachedMax: null,));
    } on ApiException catch (e) {
      emit(LeaveRequestError("Error SHOW :  $e"));
    }
  }

  Future<void> _getListOfLeaveRequest(
      LeaveRequestList event, Emitter<LeaveRequestState> emit) async {
    if (_isLoading) return; // Avoid multiple calls
    _isLoading = true;

    try {
      _offset = 0;
      _hasReachedMax = false;
      emit(LeaveRequestLoading());
      List<LeaveRequests> leave = [];
      Map<String, dynamic> result = await LeaveRequestRepo().leaveRequestList(
          limit: _limit,
          offset: _offset,
          search: event.searchQuery,
          token: true);
      leave = List<LeaveRequests>.from(result['data']
          .map((projectData) => LeaveRequests.fromJson(projectData)));
      _offset += _limit;
      _hasReachedMax = leave.length >= result['total'];
      _isLoading = !_hasReachedMax;
      if (!result.containsKey('error')) {
        emit(LeaveRequestPaginated(
            leave: leave,
            hasReachedMax: _hasReachedMax,
            isLoading: _isLoading));
      } else {
        emit(LeaveRequestError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      emit(LeaveRequestError("Error: $e"));
    } finally {
      _isLoading = false;
    }
  }

  void _onUpdateLeaveRequest(
      UpdateLeaveRequest event, Emitter<LeaveRequestState> emit) async {
    emit(LeaveRequestEditLoading());
    final leave = event.updatedRequest;

    final id = leave.id;
    final reason = leave.reason;
    final fromDate = leave.fromDate;
    final toDate = leave.toDate ?? "";
    final fromTime = leave.fromTime ?? "";
    final toTime = leave.toTime ?? "";
    final status = leave.status;
    final leaveVisibleToAll = leave.leaveVisibleToAll;
    final visibleToIds = leave.visibleToIds;
    final partialLeave = leave.partialLeave;

    // final updatedNotes = currentState.LeaveRequest.map((n) {
    //   return n.id == id ? leave : n;
    // }).toList();
    try {
      Map<String, dynamic> result = await LeaveRequestRepo().updateLeaveRequest(
        id: id!,
        reason: reason!,
        fromDate: fromDate!,
        toDate: toDate,
        fromTime: fromTime,
        toTime: toTime,
        status: status!,
        leaveVisibleToAll: leaveVisibleToAll!,
        visibleToIds: visibleToIds!,
        partialLeave: partialLeave!,
        userId: id,
      ); // Cast to NotesModel
      if (!result.containsKey('error')) {
        emit(const LeaveRequestEditSuccess());
        add(const LeaveRequestList(""));
      }
      if (result.containsKey('errors')) {
        emit((LeaveRequestEditError(result['message'])));
        flutterToastCustom(msg: result['message']);
        add(LeaveRequestList(""));
      }
      // Replace the note in the list with the updated one
    } on ApiException catch (e) {
      emit(LeaveRequestError("Error: $e"));
    }
  }

  void _onDeleteLeaveRequest(
      DeleteLeaveRequest event, Emitter<LeaveRequestState> emit) async {
    final leaveRequest = event.leaveRequest;
    try {
      Map<String, dynamic> result = await LeaveRequestRepo().deleteLeaveRequest(
        id: leaveRequest.id!.toString(),
        token: true,
      );
      if (!result.containsKey('error')) {
        emit(const LeaveRequestDeleteSuccess());
        add(const LeaveRequestList(""));
      }
      if (result.containsKey('errors')) {
        emit((LeaveRequestDeleteError(result['message'])));
        add(const LeaveRequestList(""));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(LeaveRequestError(e.toString()));
      add(const LeaveRequestList(""));
    }
  }

  Future<void> _onSearchLeaveRequest(
      SearchLeaveRequest event, Emitter<LeaveRequestState> emit) async {
    try {
      _offset = 0;
      emit(LeaveRequestLoading());
      List<LeaveRequests> leaveRequest = [];
      Map<String, dynamic> result = await LeaveRequestRepo().leaveRequestList(
          limit: _limit,
          offset: _offset,
          search: event.searchQuery,
          token: true);
      leaveRequest = List<LeaveRequests>.from(result['data']
          .map((projectData) => LeaveRequests.fromJson(projectData)));

      bool hasReachedMax = leaveRequest.length < _limit;
      if (!result.containsKey('error')) {
        emit(LeaveRequestPaginated(
            leave: leaveRequest,
            hasReachedMax: hasReachedMax,
            isLoading: false));
      }
      if (result.containsKey('errors')) {
        emit((LeaveRequestError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      emit(LeaveRequestError("Error: $e"));
    }
  }

  Future<void> _onLoadMoreLeaveRequest(
      LoadMoreLeaveRequest event, Emitter<LeaveRequestState> emit) async {
    if (state is LeaveRequestPaginated && !_hasReachedMax) {
      try {
        final currentState = state as LeaveRequestPaginated;
        final updatedTodos = List<LeaveRequests>.from(currentState.leave);
        Map<String, dynamic> result = await LeaveRequestRepo().leaveRequestList(
            limit: _limit, offset: _offset, search: '', token: true);

        if (result.containsKey('errors')) {
          emit(LeaveRequestError(result['message']));
          flutterToastCustom(msg: result['message']);
          return;
        }

        List<LeaveRequests> todo = List<LeaveRequests>.from(
            result['data'].map((todoData) => LeaveRequests.fromJson(todoData)));

        if (todo.isEmpty) {
          if (kDebugMode) {
            logger.i("No more data to load");
          }
          _hasReachedMax = true;
          emit(LeaveRequestPaginated(
            leave: [...updatedTodos],
            hasReachedMax: _hasReachedMax,
            isLoading: false,
          ));
          return;
        }

        // Update offset for the next call
        _offset += todo.length;

        updatedTodos.addAll(todo);

        _hasReachedMax = updatedTodos.length >= result['total'];

        emit(LeaveRequestPaginated(
          leave: [...updatedTodos],
          hasReachedMax: _hasReachedMax,
          isLoading: false,
        ));
      } catch (e) {
        logger.e("Error occurred: $e");
        emit(LeaveRequestError("Error: $e"));
      }
    }
  }
}
