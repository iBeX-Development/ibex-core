import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/inspectiontask/task_event.dart';
import 'package:ibex/bloc/inspectiontask/task_state.dart';

import '../../data/model/inspectiontask/task_model.dart';
import '../../data/repositories/inspectiontask/task_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionTaskBloc
    extends Bloc<InspectionTaskEvent, InspectionTaskState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 20;
  bool _hasReachedMax = false;
  bool _isLoading = false;
  InspectionTaskBloc() : super(InspectionTaskInitial()) {
    on<InspectionTaskCreated>(_onCreateTask);
    on<AllInspectionTaskList>(_getAllTask);
    on<AllInspectionTaskListOnTask>(_getAllInspectionTaskListOnProject);
    on<TodaysInspectionTaskList>(_onTodaysTask);
    on<InspectionUpdateTask>(_onInspectionUpdateTask);
    on<InspectionSearchTasks>(_onSearchTask);
    on<InspectionDeleteTask>(_onInspectionDeleteTasks);
    on<InspectionLoadMore>(_onInspectionLoadMoreTask);
    on<InspectionLoadMoreToday>(_onInspectionLoadMoreTodaysTask);
    on<InspectionTaskDashBoardFavList>(_getTaskFavLists);
    on<ResetInspectionTaskState>(_onResetInspectionTaskState); // ✅ Шинэ handler
  }
  Future<void> _onCreateTask(
    InspectionTaskCreated event,
    Emitter<InspectionTaskState> emit,
  ) async {
    try {
      emit(InspectionTaskCreateSuccessLoading());
      Map<String, dynamic> result = await InspectionTaskRepo().createTask(
        parentId: event.parentId,
        subtask: event.isSubtask,
        canClientDiscuss: event.canClientDiscuss,
        title: event.title,
        statusId: event.statusId,
        priorityId: event.priorityId,
        startDate: event.startDate,
        dueDate: event.dueDate,
        desc: event.desc,
        project: event.project,
        template_type: event.template_type,
        note: event.note,
        userId: event.userId,
        enableReminder: event.enableReminder,
        enableRecurringTask: event.enableRecurringTask,
        createType: event.createType,
        completionPercentage: event.completionPercentage,
        frequencyType: event.frequencyType,
        recurrenceFrequency: event.recurringFrequencyType,
        // Recurrence Fields
        dayOfWeek: event.dayOfWeek,
        dayOfMonth: event.dayOfMonth,
        timeOfDay: event.timeOfDay,
        recurrenceDayOfWeek: event.recurrenceDayOfWeek,
        recurrenceDayOfMonth: event.recurrenceDayOfMonth,
        recurrenceMonthOfYear: event.recurrenceMonthOfYear,
        recurrrenceStartsFrom: event.recurrenceStartsFrom,
        recurenceOccurences: event.recurrenceOccurrences,
      );

      // print("_onCreateTask result: $result");
      if (!result.containsKey('error')) {
        emit(InspectionTaskCreateSuccess());
      }
      if (result.containsKey('errors')) {
        emit(InspectionTaskCreateError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e("Error: $e");
      emit((InspectionTaskError("Error: $e")));
    }
  }

  Future<void> _getTaskFavLists(
    InspectionTaskDashBoardFavList event,
    Emitter<InspectionTaskState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(InspectionTaskLoading());
      List<InspectionTasks> fav = [];
      Map<String, dynamic> result = await InspectionTaskRepo().getTasksFav(
        isFav: event.isFav,
        limit: _limit,
        offset: _offset,
        search: '',
      );
      fav = List<InspectionTasks>.from(
        result['data']
            .map((projectData) => InspectionTasks.fromJson(projectData)),
      );
      _offset += _limit;
      _hasReachedMax = fav.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(InspectionTaskFavPaginated(
            task: fav, hasReachedMax: _hasReachedMax));
      }
      if (result.containsKey('errors')) {
        emit((InspectionTaskError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e("Error: $e");
      emit((InspectionTaskError("Error: $e")));
    }
  }

  Future<void> _getAllInspectionTaskListOnProject(
    AllInspectionTaskListOnTask event,
    Emitter<InspectionTaskState> emit,
  ) async {
    try {
      List<InspectionTasks> task = [];
      _offset = 0;
      _hasReachedMax = false;
      emit(InspectionTaskLoading());

      Map<String, dynamic> result = await InspectionTaskRepo().getTask(
        subtask: event.isSubtask,
        limit: _limit,
        offset: _offset,
        search: '',
        token: true,
        id: event.id,
        userId: event.userId,
        clientId: event.clientId,
        projectId: event.projectId,
        statusId: event.statusId,
        priorityId: event.priorityId,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (result['data'] != null) {
        task = List<InspectionTasks>.from(
          result['data']
              .map((projectData) => InspectionTasks.fromJson(projectData)),
        );

        // ✅ Try to get total count from various sources
        int? totalCount = _extractTotalCount(result);

        // ✅ Calculate hasReachedMax
        if (totalCount != null && totalCount > 0) {
          // We have total count, use it
          _hasReachedMax = task.length >= totalCount;
        } else {
          // No total count, check if we got less than limit
          _hasReachedMax = task.length < _limit;
        }

        _offset = task.length; // ✅ Set offset to current task count

        if (!result.containsKey('error')) {
          emit(
            InspectionTaskPaginated(
              task: task,
              hasReachedMax: _hasReachedMax,
              isToday: false,
            ),
          );
        } else {
          emit(InspectionTaskError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } else {
        if (kDebugMode) {
          logger.w('⚠️ No data in result');
        }
        emit(
          InspectionTaskPaginated(
            task: [],
            hasReachedMax: true,
            isToday: false,
          ),
        );
      }
    } on ApiException catch (e) {
      logger.e("ApiException: $e");
      emit(InspectionTaskError("Error: $e"));
    } catch (e, stackTrace) {
      logger.e("Unexpected error: $e");
      logger.e("Stack trace: $stackTrace");
      emit(InspectionTaskError("Error: $e"));
    }
  }

// ✅ Helper method: Extract total count from API response
  int? _extractTotalCount(Map<String, dynamic> result) {
    try {
      // 1. Check meta object
      if (result['meta'] != null && result['meta'] is Map) {
        final meta = result['meta'] as Map<String, dynamic>;

        if (meta['filter_count'] != null) {
          return _parseToInt(meta['filter_count']);
        }
        if (meta['total_count'] != null) {
          return _parseToInt(meta['total_count']);
        }
      }

      if (result['total_count'] != null) {
        return _parseToInt(result['total_count']);
      }
      if (result['total'] != null) {
        return _parseToInt(result['total']);
      }
      if (result['count'] != null) {
        return _parseToInt(result['count']);
      }
    } catch (e) {
      logger.e("Error extracting total count: $e");
    }

    if (kDebugMode) {

      logger.w("No total count found in response");

    }
    return null;
  }

// ✅ Helper method: Parse any type to int
  int? _parseToInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    } else if (value is double) {
      return value.toInt();
    } else if (value is num) {
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

// ✅ Update LoadMore handler
  Future<void> _onInspectionLoadMoreTask(
    InspectionLoadMore event,
    Emitter<InspectionTaskState> emit,
  ) async {
    if (state is InspectionTaskPaginated && !_hasReachedMax && !_isLoading) {
      _isLoading = true;

      try {
        final currentState = state as InspectionTaskPaginated;
        final updatedNotes = List<InspectionTasks>.from(currentState.task);

        Map<String, dynamic> result = await InspectionTaskRepo().getTask(
          limit: _limit,
          offset: _offset,
          search: event.searchQuery,
          token: true,
          userId: event.userId,
          clientId: event.clientId,
          projectId: event.projectId,
          statusId: event.statusId,
          priorityId: event.priorityId,
          fromDate: event.fromDate,
          toDate: event.toDate,
          isFav: event.isFav,
        );

        if (!result.containsKey('error') && result['data'] != null) {
          final additionalNotes = List<InspectionTasks>.from(
            result['data'].map(
              (projectData) => InspectionTasks.fromJson(projectData),
            ),
          );

          if (additionalNotes.isNotEmpty) {
            updatedNotes.addAll(additionalNotes);
            _offset += additionalNotes.length;

            // ✅ Check if we got less than limit
            _hasReachedMax = additionalNotes.length < _limit;
          } else {
            _hasReachedMax = true;
          }

          emit(
            InspectionTaskPaginated(
              task: updatedNotes,
              hasReachedMax: _hasReachedMax,
              isToday: false,
            ),
          );
        } else {
          if (result.containsKey('errors')) {
            emit(InspectionTaskError(result['message']));
            flutterToastCustom(msg: result['message']);
          }
        }
      } on ApiException catch (e) {
        logger.e("LoadMore ApiException: $e");
        emit(InspectionTaskError("Error: $e"));
      } catch (e, stackTrace) {
        logger.e("LoadMore Unexpected error: $e");
        logger.e("Stack trace: $stackTrace");
        emit(InspectionTaskError("Error: $e"));
      } finally {
        _isLoading = false;
      }
    } else {
      if (kDebugMode) {
        logger.w("LoadMore: Conditions not met");
      }
      // logger.w(
      //     '   - state is InspectionTaskPaginated: ${state is InspectionTaskPaginated}');
      // logger.w('   - hasReachedMax: $_hasReachedMax');
      // logger.w('   - isLoading: $_isLoading');
    }
  }

  Future<void> _onSearchTask(
    InspectionSearchTasks event,
    Emitter<InspectionTaskState> emit,
  ) async {
    try {
      List<InspectionTasks> task = [];
      emit(InspectionTaskLoading());
      _offset = 0;
      _hasReachedMax = false;

      Map<String, dynamic> result = await InspectionTaskRepo().getTask(
        limit: _limit,
        offset: _offset,
        search: event.searchQuery,
        token: true,
      );
      task = List<InspectionTasks>.from(
        result['data']
            .map((projectData) => InspectionTasks.fromJson(projectData)),
      );
      bool hasReachedMax = task.length < _limit;
      if (!result.containsKey('error')) {
        emit(
          InspectionTaskPaginated(
            task: task,
            hasReachedMax: hasReachedMax,
            isToday: false,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((InspectionTaskError(result['message'])));
      }
    } on ApiException catch (e) {
      emit(InspectionTaskError("Error: $e"));
    }
  }

  Future<void> _getAllTask(
    AllInspectionTaskList event,
    Emitter<InspectionTaskState> emit,
  ) async {
    try {
      List<InspectionTasks> task = [];
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(InspectionTaskLoading());
      Map<String, dynamic> result = await InspectionTaskRepo().getTask(
        limit: _limit,
        offset: _offset,
        search: '',
        token: true,
      );
      task = List<InspectionTasks>.from(
        result['data']
            .map((projectData) => InspectionTasks.fromJson(projectData)),
      );

      _offset += _limit;
      _hasReachedMax = task.length < _limit;
      if (!result.containsKey('error')) {
        emit(
          InspectionTaskPaginated(
            task: task,
            hasReachedMax: _hasReachedMax,
            isToday: false,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((InspectionTaskError(result['message'])));
      }
    } on ApiException catch (e) {
      logger.e("Error: $e");

      emit((InspectionTaskError("Error: $e")));
    }
  }

  Future<void> _onTodaysTask(
    TodaysInspectionTaskList event,
    Emitter<InspectionTaskState> emit,
  ) async {
    try {
      List<InspectionTasks> task = [];
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(TodaysInspectionTaskLoading());
      Map<String, dynamic> result = await InspectionTaskRepo().getTask(
        limit: _limit,
        offset: _offset,
        search: '',
        token: true,
        fromDate: event.fromDate,
        toDate: event.fromDate,
      );
      task = List<InspectionTasks>.from(
        result['data']
            .map((projectData) => InspectionTasks.fromJson(projectData)),
      );
      _offset += _limit;

      // Fixed: Check if we've reached max based on fetched items vs limit
      _hasReachedMax = task.length < _limit;
      // Alternative: if you want to use total count, do this instead:
      // _hasReachedMax = task.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(
          InspectionTaskPaginated(
            task: task,
            hasReachedMax: _hasReachedMax,
            isToday: true,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((InspectionTaskError(result['message'])));
      }
    } on ApiException catch (e) {
      logger.e("Error: $e");
      emit((InspectionTaskError("Error: $e")));
    }
  }

  void _onInspectionDeleteTasks(
    InspectionDeleteTask event,
    Emitter<InspectionTaskState> emit,
  ) async {
    final int note = event.taskId;
    try {
      Map<String, dynamic> result = await InspectionTaskRepo().getDeleteTask(
        id: note.toString(),
        token: true,
      );
      if (result['status'] == 200 && !result.containsKey('error')) {
        emit(InspectionTaskDeleteSuccess());
      }
      if (result.containsKey('errors')) {
        emit((InspectionTaskDeleteError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      logger.e("Error: $e");
      emit(InspectionTaskError(e.toString()));
    }
  }

  void _onInspectionUpdateTask(
    InspectionUpdateTask event,
    Emitter<InspectionTaskState> emit,
  ) async {
    if (state is InspectionTaskPaginated ||
        state is InspectionTaskLoading ||
        state is InspectionTaskInitial) {
      // print("bhnjkml, ${event.recurringFrequencyType}");
      emit(InspectionTaskEditSuccessLoading());
      try {
        Map<String, dynamic> result = await InspectionTaskRepo().updateTask(
          id: event.id,
          parentId: event.parentId,
          subtask: event.isSubtask,
          title: event.title,
          statusId: event.statusId,
          priorityId: event.priorityId,
          startDate: event.startDate,
          dueDate: event.dueDate,
          desc: event.desc,
          note: event.note,
          frequencyType: event.frequencyType,
          template_type: event.template_type,
          recurrenceFrequency: event.recurringFrequencyType,
          userId: event.userId,
          enableReminder: event.enableReminder,
          enableRecurringTask: event.enableRecurringTask,
          createType: event.createType,

          completionPercentage: event.completionPercentage,
          canClientDiscuss: event.canClientDiscuss,

          // Recurrence Fields
          dayOfWeek: event.dayOfWeek,
          dayOfMonth: event.dayOfMonth,
          timeOfDay: event.timeOfDay,
          recurrenceDayOfWeek: event.recurrenceDayOfWeek,
          recurrenceDayOfMonth: event.recurrenceDayOfMonth,
          recurrenceMonthOfYear: event.recurrenceMonthOfYear,
          recurrrenceStartsFrom: event.recurrenceStartsFrom,
          recurenceOccurences: event.recurrenceOccurrences,
        );

        if (!result.containsKey('error')) {
          emit(InspectionTaskEditSuccess());
        } else {
          emit(InspectionTaskEditError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        logger.e("Error: $e");
        emit(InspectionTaskEditError(e.toString()));
      }
    }
  }

  void _onResetInspectionTaskState(
    ResetInspectionTaskState event,
    Emitter<InspectionTaskState> emit,
  ) {
    if (kDebugMode) {
      logger.i('🔥 [BLOC] Resetting InspectionTaskBloc state to Initial');
    }
    emit(InspectionTaskInitial());
  }

  Future<void> _onInspectionLoadMoreTodaysTask(
    InspectionLoadMoreToday event,
    Emitter<InspectionTaskState> emit,
  ) async {
    if (state is InspectionTaskPaginated && !_hasReachedMax && !_isLoading) {
      _isLoading = true;
      try {
        final currentState = state as InspectionTaskPaginated;
        final updatedTask = List<InspectionTasks>.from(currentState.task);

        // Fetch additional tasks from the repository
        Map<String, dynamic> result = await InspectionTaskRepo().getTask(
          limit: _limit,
          offset: _offset, // Use the current offset
          search: '',
          token: true,
          fromDate: event.fromDate,
          toDate: event.toDate,
        );

        final additionalTask = List<InspectionTasks>.from(
          result['data'].map((taskData) => InspectionTasks.fromJson(taskData)),
        );

        // Update the offset only if the fetch is successful
        if (additionalTask.isNotEmpty) {
          _offset += additionalTask.length; // Increment by fetched items
        }

        // Check if the maximum number of items has been reached
        _hasReachedMax = additionalTask.length < _limit;

        updatedTask.addAll(additionalTask);

        if (!result.containsKey('error')) {
          emit(
            InspectionTaskPaginated(
              task: updatedTask,
              hasReachedMax: _hasReachedMax,
              isToday: true,
            ),
          );
        } else {
          emit(InspectionTaskError(result['message']));
        }
      } on ApiException catch (e) {
        emit(InspectionTaskError("Error: $e"));
        logger.e("LoadMore ApiException: $e");
      } finally {
        _isLoading = false; // End loading
      }
    }
  }
}
