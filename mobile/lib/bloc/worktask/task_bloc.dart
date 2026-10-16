import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/worktask/task_event.dart';
import 'package:ibex/bloc/worktask/task_state.dart';

import '../../data/model/worktask/task_model.dart';
import '../../data/repositories/worktask/task_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkTaskBloc extends Bloc<WorkTaskEvent, WorkTaskState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 20;
  bool _hasReachedMax = false;
  bool _isLoading = false;
  WorkTaskBloc() : super(WorkTaskInitial()) {
    on<WorkTaskCreated>(_onCreateTask);
    on<AllWorkTaskList>(_getAllTask);
    on<AllWorkTaskListOnTask>(_getAllWorkTaskListOnProject);
    on<TodaysWorkTaskList>(_onTodaysTask);
    on<WorkUpdateTask>(_onWorkUpdateTask);
    on<WorkSearchTasks>(_onSearchTask);
    on<WorkDeleteTask>(_onWorkDeleteTasks);
    on<WorkLoadMore>(_onWorkLoadMoreTask);
    on<WorkLoadMoreToday>(_onWorkLoadMoreTodaysTask);
    on<WorkTaskDashBoardFavList>(_getTaskFavLists);
    on<ResetWorkTaskState>(_onResetWorkTaskState); // ✅ Шинэ handler
  }
  Future<void> _onCreateTask(
    WorkTaskCreated event,
    Emitter<WorkTaskState> emit,
  ) async {
    try {
      emit(WorkTaskCreateSuccessLoading());
      Map<String, dynamic> result = await WorkTaskRepo().createTask(
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
        billingType: event.billingType,
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

      if (!result.containsKey('error')) {
        emit(WorkTaskCreateSuccess());
      }
      if (result.containsKey('errors')) {
        emit(WorkTaskCreateError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((WorkTaskError("Error: $e")));
    }
  }

  Future<void> _getTaskFavLists(
    WorkTaskDashBoardFavList event,
    Emitter<WorkTaskState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(WorkTaskLoading());
      List<WorkTasks> fav = [];
      Map<String, dynamic> result = await WorkTaskRepo().getTasksFav(
        isFav: event.isFav,
        limit: _limit,
        offset: _offset,
        search: '',
      );
      fav = List<WorkTasks>.from(
        result['data'].map((projectData) => WorkTasks.fromJson(projectData)),
      );
      _offset += _limit;
      _hasReachedMax = fav.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(WorkTaskFavPaginated(task: fav, hasReachedMax: _hasReachedMax));
      }
      if (result.containsKey('errors')) {
        emit((WorkTaskError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((WorkTaskError("Error: $e")));
    }
  }

  Future<void> _getAllWorkTaskListOnProject(
    AllWorkTaskListOnTask event,
    Emitter<WorkTaskState> emit,
  ) async {
    try {
      List<WorkTasks> task = [];
      _offset = 0;
      _hasReachedMax = false;
      emit(WorkTaskLoading());

      Map<String, dynamic> result = await WorkTaskRepo().getTask(
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
        task = List<WorkTasks>.from(
          result['data'].map((projectData) => WorkTasks.fromJson(projectData)),
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
            WorkTaskPaginated(
              task: task,
              hasReachedMax: _hasReachedMax,
              isToday: false,
            ),
          );
        } else {
          emit(WorkTaskError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } else {
        emit(WorkTaskPaginated(task: [], hasReachedMax: true, isToday: false));
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d('❌ ApiException: $e');
      }

      emit(WorkTaskError("Error: $e"));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        logger.d('❌ Unexpected error: $e');
      }
      if (kDebugMode) {
        logger.d('❌ Stack trace: $stackTrace');
      }
      emit(WorkTaskError("Error: $e"));
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

      // 2. Check root level fields

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
      if (kDebugMode) {
        logger.d('❌ Error extracting total count: $e');
      }
    }

    if (kDebugMode) {

      logger.d('⚠️ No total count found in response');

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

    if (kDebugMode) {

      logger.d('⚠️ Cannot parse to int: $value (${value.runtimeType})');

    }
    return null;
  }

  // ✅ Update LoadMore handler
  Future<void> _onWorkLoadMoreTask(
    WorkLoadMore event,
    Emitter<WorkTaskState> emit,
  ) async {
    if (state is WorkTaskPaginated && !_hasReachedMax && !_isLoading) {
      _isLoading = true;

      try {
        final currentState = state as WorkTaskPaginated;
        final updatedNotes = List<WorkTasks>.from(currentState.task);

        Map<String, dynamic> result = await WorkTaskRepo().getTask(
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
          final additionalNotes = List<WorkTasks>.from(
            result['data'].map(
              (projectData) => WorkTasks.fromJson(projectData),
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
            WorkTaskPaginated(
              task: updatedNotes,
              hasReachedMax: _hasReachedMax,
              isToday: false,
            ),
          );
        } else {
          if (result.containsKey('errors')) {
            emit(WorkTaskError(result['message']));
            flutterToastCustom(msg: result['message']);
          }
        }
      } on ApiException catch (e) {
        if (kDebugMode) {
          logger.d('❌ LoadMore ApiException: $e');
        }
        emit(WorkTaskError("Error: $e"));
      } catch (e, stackTrace) {
        if (kDebugMode) {
          logger.d('❌ LoadMore Unexpected error: $e');
        }
        if (kDebugMode) {
          logger.d('❌ Stack trace: $stackTrace');
        }
        emit(WorkTaskError("Error: $e"));
      } finally {
        _isLoading = false;
      }
    } else {
      if (kDebugMode) {
        logger.d('⚠️ LoadMore: Conditions not met');
      }
    }
  }

  Future<void> _onSearchTask(
    WorkSearchTasks event,
    Emitter<WorkTaskState> emit,
  ) async {
    try {
      List<WorkTasks> task = [];
      emit(WorkTaskLoading());
      _offset = 0;
      _hasReachedMax = false;

      Map<String, dynamic> result = await WorkTaskRepo().getTask(
        limit: _limit,
        offset: _offset,
        search: event.searchQuery,
        token: true,
      );
      task = List<WorkTasks>.from(
        result['data'].map((projectData) => WorkTasks.fromJson(projectData)),
      );
      bool hasReachedMax = task.length < _limit;
      if (!result.containsKey('error')) {
        emit(
          WorkTaskPaginated(
            task: task,
            hasReachedMax: hasReachedMax,
            isToday: false,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((WorkTaskError(result['message'])));
      }
    } on ApiException catch (e) {
      emit(WorkTaskError("Error: $e"));
    }
  }

  Future<void> _getAllTask(
    AllWorkTaskList event,
    Emitter<WorkTaskState> emit,
  ) async {
    try {
      List<WorkTasks> task = [];
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(WorkTaskLoading());
      Map<String, dynamic> result = await WorkTaskRepo().getTask(
        limit: _limit,
        offset: _offset,
        search: '',
        token: true,
      );
      task = List<WorkTasks>.from(
        result['data'].map((projectData) => WorkTasks.fromJson(projectData)),
      );

      _offset += _limit;
      _hasReachedMax = task.length < _limit;
      if (!result.containsKey('error')) {
        emit(
          WorkTaskPaginated(
            task: task,
            hasReachedMax: _hasReachedMax,
            isToday: false,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((WorkTaskError(result['message'])));
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((WorkTaskError("Error: $e")));
    }
  }

  Future<void> _onTodaysTask(
    TodaysWorkTaskList event,
    Emitter<WorkTaskState> emit,
  ) async {
    try {
      List<WorkTasks> task = [];
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(TodaysWorkTaskLoading());
      Map<String, dynamic> result = await WorkTaskRepo().getTask(
        limit: _limit,
        offset: _offset,
        search: '',
        token: true,
        fromDate: event.fromDate,
        toDate: event.fromDate,
      );
      task = List<WorkTasks>.from(
        result['data'].map((projectData) => WorkTasks.fromJson(projectData)),
      );
      _offset += _limit;

      // Fixed: Check if we've reached max based on fetched items vs limit
      _hasReachedMax = task.length < _limit;
      // Alternative: if you want to use total count, do this instead:
      // _hasReachedMax = task.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(
          WorkTaskPaginated(
            task: task,
            hasReachedMax: _hasReachedMax,
            isToday: true,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((WorkTaskError(result['message'])));
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((WorkTaskError("Error: $e")));
    }
  }

  void _onWorkDeleteTasks(
    WorkDeleteTask event,
    Emitter<WorkTaskState> emit,
  ) async {
    final int note = event.taskId;
    try {
      Map<String, dynamic> result = await WorkTaskRepo().getDeleteTask(
        id: note.toString(),
        token: true,
      );
      if (result['status'] == 200 && !result.containsKey('error')) {
        emit(WorkTaskDeleteSuccess());
      }
      if (result.containsKey('errors')) {
        emit((WorkTaskDeleteError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(WorkTaskError(e.toString()));
    }
  }

  void _onWorkUpdateTask(
    WorkUpdateTask event,
    Emitter<WorkTaskState> emit,
  ) async {
    if (state is WorkTaskPaginated ||
        state is WorkTaskLoading ||
        state is WorkTaskInitial) {
      emit(WorkTaskEditSuccessLoading());
      try {
        Map<String, dynamic> result = await WorkTaskRepo().updateTask(
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
          billingType: event.billingType,
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
          emit(WorkTaskEditSuccess());
          add(AllWorkTaskList());
        } else {
          emit(WorkTaskEditError(result['message']));
          flutterToastCustom(msg: result['message']);
          add(AllWorkTaskList());
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d(e.toString());
        }
      }
    }
  }

  void _onResetWorkTaskState(
    ResetWorkTaskState event,
    Emitter<WorkTaskState> emit,
  ) {
    emit(WorkTaskInitial());
  }

  Future<void> _onWorkLoadMoreTodaysTask(
    WorkLoadMoreToday event,
    Emitter<WorkTaskState> emit,
  ) async {
    if (state is WorkTaskPaginated && !_hasReachedMax && !_isLoading) {
      _isLoading = true;
      try {
        final currentState = state as WorkTaskPaginated;
        final updatedTask = List<WorkTasks>.from(currentState.task);

        // Fetch additional tasks from the repository
        Map<String, dynamic> result = await WorkTaskRepo().getTask(
          limit: _limit,
          offset: _offset, // Use the current offset
          search: '',
          token: true,
          fromDate: event.fromDate,
          toDate: event.toDate,
        );

        final additionalTask = List<WorkTasks>.from(
          result['data'].map((taskData) => WorkTasks.fromJson(taskData)),
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
            WorkTaskPaginated(
              task: updatedTask,
              hasReachedMax: _hasReachedMax,
              isToday: true,
            ),
          );
        } else {
          emit(WorkTaskError(result['message']));
        }
      } on ApiException catch (e) {
        emit(WorkTaskError("Error: $e"));
      } finally {
        _isLoading = false; // End loading
      }
    }
  }
}
