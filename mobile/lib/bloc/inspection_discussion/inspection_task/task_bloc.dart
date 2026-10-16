import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/inspectiontask/task_event.dart';
import 'package:ibex/bloc/inspectiontask/task_state.dart';

import '../../../api_helper/api.dart';
import '../../../data/model/inspectiontask/task_model.dart';
import '../../../data/repositories/Inspectiontask/Task_repo.dart';
import '../../../utils/widgets/toast_widget.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionTaskBloc
    extends Bloc<InspectionTaskEvent, InspectionTaskState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;
  bool _isLoading = false;
  InspectionTaskBloc() : super(InspectionTaskInitial()) {
    on<InspectionTaskCreated>(_onCreateTask);
    on<AllInspectionTaskList>(_getAllTask);
    on<AllInspectionTaskListOnTask>(_getAllTaskListOnProject);
    on<InspectionUpdateTask>(_onUpdateTask);
    on<InspectionSearchTasks>(_onSearchTask);
    on<InspectionDeleteTask>(_onDeleteTasks);
    on<InspectionLoadMore>(_onLoadMoreTask);
    on<InspectionLoadMoreToday>(_onLoadMoreTodaysTask);
    on<InspectionTaskDashBoardFavList>(_getTaskFavLists);
  }
  Future<void> _onCreateTask(
      InspectionTaskCreated event, Emitter<InspectionTaskState> emit) async {
    try {
      emit(InspectionTaskCreateSuccessLoading());
      Map<String, dynamic> result = await InspectionTaskRepo().createTask(
        canClientDiscuss: event.canClientDiscuss,
        title: event.title,
        statusId: event.statusId,
        priorityId: event.priorityId,
        startDate: event.startDate,
        dueDate: event.dueDate,
        desc: event.desc,
        project: event.project,
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

      if (!result.containsKey('error')) {
        emit(InspectionTaskCreateSuccess());
        add(AllInspectionTaskList());
      }
      if (result.containsKey('errors')) {
        emit(InspectionTaskCreateError(result['message']));
        add(AllInspectionTaskList());

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

  Future<void> _getAllTaskListOnProject(
    AllInspectionTaskListOnTask event,
    Emitter<InspectionTaskState> emit,
  ) async {
    try {
      List<InspectionTasks> task = [];
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      Map<String, dynamic> result = {};
      emit(InspectionTaskLoading());
      _offset = 0;
      result = await InspectionTaskRepo().getTask(
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

  Future<void> _onSearchTask(
      InspectionSearchTasks event, Emitter<InspectionTaskState> emit) async {
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
      AllInspectionTaskList event, Emitter<InspectionTaskState> emit) async {
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

  void _onDeleteTasks(
      InspectionDeleteTask event, Emitter<InspectionTaskState> emit) async {
    final int note = event.taskId;
    try {
      Map<String, dynamic> result = await InspectionTaskRepo().getDeleteTask(
        id: note.toString(),
        token: true,
      );
      if (!result.containsKey('error')) {
        emit(InspectionTaskDeleteSuccess());
      }
      if (result.containsKey('errors')) {
        emit((InspectionTaskDeleteError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(InspectionTaskError(e.toString()));
    }
  }

  void _onUpdateTask(
      InspectionUpdateTask event, Emitter<InspectionTaskState> emit) async {
    if (state is InspectionTaskPaginated) {
      emit(InspectionTaskEditSuccessLoading());
      try {
        Map<String, dynamic> result = await InspectionTaskRepo().updateTask(
          id: event.id,
          title: event.title,
          statusId: event.statusId,
          priorityId: event.priorityId,
          startDate: event.startDate,
          dueDate: event.dueDate,
          desc: event.desc,
          note: event.note,
          frequencyType: event.frequencyType,
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
          add(AllInspectionTaskList());
        } else {
          emit(InspectionTaskEditError(result['message']));
          flutterToastCustom(msg: result['message']);
          add(AllInspectionTaskList());
        }
      } catch (e) {
        logger.e("Error: $e");
      }
    }
  }

  Future<void> _onLoadMoreTask(
      InspectionLoadMore event, Emitter<InspectionTaskState> emit) async {
    if (state is InspectionTaskPaginated && !_hasReachedMax && !_isLoading) {
      _isLoading = true; // Start loading
      try {
        final currentState = state as InspectionTaskPaginated;
        final updatedNotes = List<InspectionTasks>.from(currentState.task);

        // Fetch additional tasks
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

        if (!result.containsKey('error')) {
          final additionalNotes = List<InspectionTasks>.from(
            result['data']
                .map((projectData) => InspectionTasks.fromJson(projectData)),
          );

          // Increment the offset only if new items are fetched
          if (additionalNotes.isNotEmpty) {
            _offset += additionalNotes.length; // Update offset
          }
          if (updatedNotes.length >= result['total']) {
            _hasReachedMax = true;
          } else {
            _hasReachedMax = false;
          }

          updatedNotes.addAll(additionalNotes);
        } else if (result.containsKey('errors')) {
          emit(InspectionTaskError(result['message']));
          flutterToastCustom(msg: result['message']);
        }

        emit(
          InspectionTaskPaginated(
            task: updatedNotes,
            hasReachedMax: _hasReachedMax,
            isToday: false,
          ),
        );
      } on ApiException catch (e) {
        emit(InspectionTaskError("Error: $e"));
      } finally {
        _isLoading = false; // End loading
      }
    }
  }

  Future<void> _onLoadMoreTodaysTask(
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
      } finally {
        _isLoading = false; // End loading
      }
    }
  }
}
