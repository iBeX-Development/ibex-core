import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/work/work_event.dart';
import 'package:ibex/bloc/work/work_state.dart';
import 'package:ibex/data/model/Work/all_work.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';
import '../../data/repositories/Work/work_repo.dart';
import '../../api_helper/api.dart';
import '../../../data/localStorage/hive.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkBloc extends Bloc<WorkEvent, WorkState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 25;
  int totalCount = 0;
  List<Object> woStatusData = [];

  bool _hasReachedMax = false;
  WorkBloc() : super(WorkInitial()) {
    _initializeStatusData();

    on<WorkDashBoardList>(_getWorkLists);
    on<WorkDashBoardFavList>(_getWorkFavLists);
    on<SelectedWork>(_onSelectWork);
    on<WorkLoadMore>(_onLoadMoreWork);
    on<DeleteWork>(_onDeleteWork);
    on<SearchWork>(_onSearchWork);
    on<WorkCreated>(_onCreateWork);
    on<UpdateWork>(_onUpdateWork);
    on<WorkMindMap>(_onWorkMindMap);
  }

  Future<void> _initializeStatusData() async {
    woStatusData = await HiveStorage.getAllStatusData();
  }

  Future<void> _onWorkMindMap(
    WorkMindMap event,
    Emitter<WorkState> emit,
  ) async {
    try {
      //
      emit(WorkMapLoading());

      Map<String, dynamic> result = await WorkRepo().getWorkMindMap(
        id: event.id,
      );

      if (result['original']['error'] == false) {
        emit(WorkMindMapSuccess(result));
      }
      if (result.containsKey('errors')) {
        emit((WorkError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((WorkError("Error: $e")));
    }
  }

  Future<void> _getWorkLists(
    WorkDashBoardList event,
    Emitter<WorkState> emit,
  ) async {
    try {
      // ✅ Ensure woStatusData is loaded before processing
      if (woStatusData.isEmpty) {
        woStatusData = await HiveStorage.getAllStatusData();
      }

      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(WorkLoading());
      List<WorkModel> notification = [];
      Map<String, dynamic> result = await WorkRepo().getWorks(
        id: event.id,
        isFav: event.isFav,
        limit: _limit,
        offset: _offset,
        active: 1,
        location: event.location,
        woStatus: event.woStatus,
        workType: event.workType,
        createType: event.createType,
        actionStatus: event.actionStatus, // ✅ Pass action_status filter
        workOrderIds: event.workOrderIds, // ✅ Pass work order IDs filter
        search: '',
        userId: event.userId,
        assetId: event.assetId,
        statusId: event.statusId,
        priorityId: event.priorityId,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      totalCount = result['meta']['filter_count'] != null
          ? result['meta']['filter_count'] as int
          : 0;

      notification = List<WorkModel>.from(
        result['data'].map(
          (workData) => WorkModel.fromJson(workData, woStatusData),
        ),
      );

      // ✅ Deduplicate by id
      final seen = <int?>{};
      notification = notification.where((w) => seen.add(w.id)).toList();
      if (event.id != null) {
        _offset = 0;
      } else {
        _offset += _limit;
        _hasReachedMax = notification.length >= (result['data'].length ?? 1);
      }

      if (!result.containsKey('error') || notification.length > 0) {
        emit(
          WorkPaginated(
            work: notification,
            hasReachedMax: _hasReachedMax,
            totalCount: totalCount,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((WorkError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((WorkError("Error: $e")));
    }
  }

  Future<void> _getWorkFavLists(
    WorkDashBoardFavList event,
    Emitter<WorkState> emit,
  ) async {
    try {
      // ✅ Ensure woStatusData is loaded before processing
      if (woStatusData.isEmpty) {
        woStatusData = await HiveStorage.getAllStatusData();
      }

      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(WorkLoading());
      List<WorkModel> fav = [];
      Map<String, dynamic> result = await WorkRepo().getWorksFav(
        isFav: event.isFav,
        limit: _limit,
        offset: _offset,
        search: '',
      );
      fav = List<WorkModel>.from(
        result['data'].map(
          (workData) => WorkModel.fromJson(workData, woStatusData),
        ),
      );
      _offset += _limit;
      _hasReachedMax = fav.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(WorkFavPaginated(work: fav, hasReachedMax: _hasReachedMax));
      }
      if (result.containsKey('errors')) {
        emit((WorkError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((WorkError("Error: $e")));
    }
  }

  void _onDeleteWork(DeleteWork event, Emitter<WorkState> emit) async {
    // if (emit is NotesSuccess) {
    final work = event.workId;

    try {
      Map<String, dynamic> result = await WorkRepo().getDeleteWork(
        id: work.toString(),
        token: true,
      );
      if (result['data']['error'] == false) {
        emit(WorkDeleteSuccess());
      }
      if (result['data']['error'] == true) {
        emit((WorkDeleteError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(WorkError(e.toString()));
    }
    // }
  }

  Future<void> _onCreateWork(WorkCreated event, Emitter<WorkState> emit) async {
    try {
      List<WorkModel> work = [];

      emit(WorkCreateLoading());
      var result = await WorkRepo().createWork(
        title: event.title,
        statusId: event.statusId ?? 1,
        userId: event.userId,
        actionStatus: event.actionStatus,
        workType: event.workType,
        requestUser: event.userIdString,
        locationId: event.locationId,
        desc: event.desc ?? '',
        note: event.note ?? '',
        priorityId: event.priorityId ?? 1,
        startDate: event.startDate ?? '',
        endDate: event.endDate ?? '',
        createdType: event.createdType ?? 'open', // ✅ Default утга нэмэх
        assetId: event.assetId != null ? event.assetId! : null,
        taskAccess: event.taskAccess ?? '',
        enable: event.enable ?? 0,
        budget: event.budget ?? '',
        customFieldValues: event.customFieldValues ?? null,
      );
      if (result.containsKey('data') && result['data'] != null) {
        // ✅ Parse created work data
        WorkModel? createdWork;
        int? createdWorkId;

        if (result['data'] is List && (result['data'] as List).isNotEmpty) {
          var workData = result['data'][0];
          createdWork = WorkModel.fromJson(workData, []);
          createdWorkId = workData['id'];
        } else if (result['data'] is Map) {
          createdWork = WorkModel.fromJson(result['data'], []);
          createdWorkId = result['data']['id'];
        }

        emit(
          WorkCreateSuccess(
            createdWork: createdWork,
            createdWorkId: createdWorkId,
          ),
        );
      } else if (result.containsKey('errors')) {
        String errorMessage =
            result['errors'][0]['message'] ?? 'Create work failed';
        if (kDebugMode) {
          logger.d("❌ Create work failed: $errorMessage");
        }
        emit(WorkCreateError(errorMessage));
      } else {
        if (kDebugMode) {
          logger.d("❌ Unexpected response format");
        }
        emit(WorkCreateError('Unexpected response format'));
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((WorkError("Error: $e")));
    }
  }

  void _onSelectWork(SelectedWork event, Emitter<WorkState> emit) {
    if (state is WorkSuccess) {
      final currentState = state as WorkSuccess;
      emit(
        WorkSuccess(
          currentState.work,
          event.selectedIndex,
          event.selectedTitle,
          false,
        ),
      );
    }
  }

  void _onUpdateWork(UpdateWork event, Emitter<WorkState> emit) async {
    if (state is WorkPaginated) {
      List<WorkModel> work = [];
      final id = event.id;
      final title = event.title;
      final statusId = event.statusId;
      final priorityId = event.priorityId;
      final startDate = event.startDate;
      final endDate = event.endDate;
      final desc = event.desc;
      final note = event.note;
      final taskAccess = event.taskAccess;
      final budget = event.budget;
      final userId = event.userId;
      final assetId = event.assetId;
      final clientId = event.clientId;
      final tagId = event.tagId;
      final canClientDiscuss = event.clientCanDiscuss;
      final isEnabled = event.enable;
      final customFieldValues =
          event.customFieldValues; // Access from the event

      // Get custom field values
      // final fieldValues = getFieldValues(); // From your submitToAPI function

      emit(WorkEditLoading());
      try {
        Map<String, dynamic> updatedWork = await WorkRepo().updateWork(
          id: id,
          title: title,
          statusId: statusId ?? 0,
          priorityId: priorityId ?? 0,
          startDate: startDate ?? '',
          endDate: endDate ?? '',
          desc: desc ?? '',
          note: note ?? '',
          userId: userId ?? [],
          assetId: assetId ?? [],
          taskAccess: taskAccess ?? '',
          budget: budget ?? '',
          clientId: clientId ?? [],
          canClientDiscuss: canClientDiscuss!,
          enable: isEnabled!,
          tagId: tagId ?? [],
          customFieldValues: customFieldValues, // Pass as a named parameter
        );

        if (!updatedWork.containsKey('error')) {
          emit(WorkEditSuccess(work));
          add(WorkDashBoardList());
        } else if (updatedWork.containsKey('error')) {
          flutterToastCustom(msg: updatedWork['message']);
          add(WorkDashBoardList());
          emit(WorkEditError(updatedWork['message']));
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating Task: $e');
        }
      }
    }
  }

  Future<void> _onSearchWork(SearchWork event, Emitter<WorkState> emit) async {
    try {
      // ✅ Ensure woStatusData is loaded before processing
      if (woStatusData.isEmpty) {
        woStatusData = await HiveStorage.getAllStatusData();
      }

      List<WorkModel> works = [];
      _offset = 0;
      emit(WorkLoading());
      var result = await WorkRepo().getWorks(
        limit: _limit,
        offset: _offset,
        search: event.searchQuery,
        clientId: event.clientId,
        // actionStatus: event.actionStatus, // ✅ Pass action_status filter
      );

      if (!result.containsKey('error')) {
        works = List<WorkModel>.from(
          result['data'].map(
            (workData) => WorkModel.fromJson(workData, woStatusData),
          ),
        );
        bool hasReachedMax = works.length < _limit;
        emit(
          WorkPaginated(
            work: works,
            hasReachedMax: hasReachedMax,
            totalCount: totalCount,
          ),
        );
      } else if (result.containsKey('errors')) {
        emit(WorkError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      emit(WorkError("Error: $e"));
    }
  }

  Future<void> _onLoadMoreWork(
    WorkLoadMore event,
    Emitter<WorkState> emit,
  ) async {
    if (state is WorkPaginated && !_hasReachedMax) {
      try {
        // ✅ Ensure woStatusData is loaded before processing
        if (woStatusData.isEmpty) {
          woStatusData = await HiveStorage.getAllStatusData();
        }

        final currentState = state as WorkPaginated;
        final updatedWork = List<WorkModel>.from(currentState.work);

        // Fetch additional Works from the repository
        Map<String, dynamic> result = await WorkRepo().getWorks(
          limit: _limit,
          offset: _offset,
          search: event.searchQuery,
          clientId: event.clientId,
          userId: event.userId,
        );
        final additional = List<WorkModel>.from(
          result['data'].map(
            (workData) => WorkModel.fromJson(workData, woStatusData),
          ),
        );

        if (additional.isEmpty) {
          _hasReachedMax = true;
        } else {
          _offset += _limit; // Increment the offset consistently
          // ✅ Deduplicate: only add items not already in the list
          final existingIds = updatedWork.map((w) => w.id).toSet();
          updatedWork.addAll(additional.where((w) => !existingIds.contains(w.id)));
        }

        if (!result.containsKey('error')) {
          totalCount = result['meta']['filter_count'] != null
              ? result['meta']['filter_count'] as int
              : 0;
          emit(
            WorkPaginated(
              work: updatedWork,
              hasReachedMax: _hasReachedMax,
              totalCount: totalCount,
            ),
          );
        } else {
          emit(WorkError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } on ApiException catch (e) {
        emit(WorkError("Error: $e"));
      }
    }
  }
}
