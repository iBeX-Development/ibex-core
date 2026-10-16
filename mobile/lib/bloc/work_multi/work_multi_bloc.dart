import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/work_multi/work_multi_event.dart';
import 'package:ibex/bloc/work_multi/work_multi_state.dart';
import '../../data/model/Work/all_work.dart';
import '../../data/repositories/Work/work_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import '../../data/localStorage/hive.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkMultiBloc extends Bloc<WorkMultiEvent, WorkMultiState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 16;
  bool _hasReachedMax = false;
  List<Object> woStatusData = [];
  WorkMultiBloc() : super(WorkMultiInitial()) {
    _initializeStatusData();
    on<WorkMultiList>(_getWorkMultiList);
    on<SelectedWorkMulti>(_onSelectWorkMulti);
    on<WorkMultiLoadMore>(_onLoadMore);
    on<ToggleWorkMultiSelection>(_onToggleWorkMultiSelection);
    on<SearchWorkMultis>(_onSearchWorkMulti);
  }

  Future<void> _initializeStatusData() async {
    woStatusData = await HiveStorage.getAllStatusData();
  }

  Future<void> _getWorkMultiList(
    WorkMultiList event,
    Emitter<WorkMultiState> emit,
  ) async {
    try {
      List<WorkModel> workMultis = [];
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(WorkMultiLoading());
      Map<String, dynamic> result = await WorkRepo().getWorks(
        limit: _limit,
        offset: _offset,
      );
      workMultis = List<WorkModel>.from(
        result['data'].map(
          (workData) => WorkModel.fromJson(workData, woStatusData),
        ),
      );
      _offset += _limit;
      _hasReachedMax = workMultis.length >= result['total'];

      emit(
        WorkMultiPaginated(
          workMulti: workMultis,
          hasReachedMax: _hasReachedMax,
        ),
      );
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((WorkMultiError("Error: $e")));
    }
  }

  Future<void> _onSearchWorkMulti(
    SearchWorkMultis event,
    Emitter<WorkMultiState> emit,
  ) async {
    try {
      List<WorkModel> workMulti = [];
      // emit(WorkMultiLoading());
      Map<String, dynamic> result = await WorkRepo().getWorks(
        limit: _limit,
        offset: 0,
        search: event.searchQuery,
      );
      workMulti = List<WorkModel>.from(
        result['data'].map(
          (workData) => WorkModel.fromJson(workData, woStatusData),
        ),
      );

      bool hasReachedMax = workMulti.length >= result['total'];
      if (!result.containsKey('error')) {
        emit(
          WorkMultiPaginated(
            workMulti: workMulti,
            hasReachedMax: hasReachedMax,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((WorkMultiError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      flutterToastCustom(msg: "$e");

      emit(WorkMultiError("Error: $e"));
    }
  }

  Future<void> _onLoadMore(
    WorkMultiLoadMore event,
    Emitter<WorkMultiState> emit,
  ) async {
    if (state is WorkMultiPaginated && !_hasReachedMax) {
      try {
        final currentState = state as WorkMultiPaginated;
        final updatedNotification = List<WorkModel>.from(
          currentState.workMulti,
        );

        // Fetch additional Notifications from the repository
        List<WorkModel> additionalNotes = [];
        Map<String, dynamic> result = await WorkRepo().getWorks(
          limit: _limit,
          offset: _offset,
        );
        additionalNotes = List<WorkModel>.from(
          result['data'].map(
            (workData) => WorkModel.fromJson(workData, woStatusData),
          ),
        );
        // Update the offset for the next load
        _offset = updatedNotification.length;

        // Check if the D number of items has been reached
        logger.d(
          "loading more ${currentState.workMulti.length} and > = ${result['total']}",
        );
        if (currentState.workMulti.length >= result['total']) {
          _hasReachedMax = true;
        } else {
          _hasReachedMax = false;
        }

        // Add the newly fetched Notifications to the existing list
        updatedNotification.addAll(additionalNotes);
        if (!result.containsKey('error')) {
          emit(
            WorkMultiPaginated(
              workMulti: updatedNotification,
              hasReachedMax: _hasReachedMax,
            ),
          );
        }
        if (result.containsKey('errors')) {
          emit((WorkMultiError(result['message'])));
          flutterToastCustom(msg: result['message']);
        }
        // Emit the new state with the updated Notification list and hasReachedMax flag
      } on ApiException catch (e) {
        // Handle any errors that occur during the API call
        emit(WorkMultiError("Error: $e"));
      }
    }
  }

  void _onSelectWorkMulti(
    SelectedWorkMulti event,
    Emitter<WorkMultiState> emit,
  ) {
    if (state is WorkMultiSuccess) {
      final currentState = state as WorkMultiSuccess;

      final selectedIndices = List<int>.from(currentState.selectedIndices);
      final selectedWorkMultinames = List<String>.from(
        currentState.selectedWorkMultinames,
      );

      if (selectedIndices.contains(event.selectedIndex)) {
        selectedIndices.remove(event.selectedIndex);
        selectedWorkMultinames.remove(event.selectedTitle);
      } else {
        selectedIndices.add(event.selectedIndex);
        selectedWorkMultinames.add(event.selectedTitle);
      }

      emit(
        WorkMultiSuccess(
          workMulti: currentState.workMulti,
          selectedIndices: selectedIndices,
          selectedWorkMultinames: selectedWorkMultinames,
          isLoadingMore: currentState.isLoadingMore,
        ),
      );
    }
  }

  void _onToggleWorkMultiSelection(
    ToggleWorkMultiSelection event,
    Emitter<WorkMultiState> emit,
  ) {
    if (state is WorkMultiSuccess) {
      final currentState = state as WorkMultiSuccess;

      // Create local copies to avoid mutation issues
      final updatedSelectedWorkMultiIds = List<int>.from(
        currentState.selectedIndices,
      );
      final updatedSelectedWorkMultinames = List<String>.from(
        currentState.selectedWorkMultinames,
      );

      // Check if the WorkMulti is already selected based on WorkMultiId
      final isSelected = updatedSelectedWorkMultiIds.contains(
        event.workMultiId,
      );

      if (isSelected) {
        // Find the index of the WorkMultiId in the selectedIndices list
        final removeIndex = updatedSelectedWorkMultiIds.indexOf(
          event.workMultiId,
        );

        // Remove WorkMultiId and corresponding WorkMultiname
        updatedSelectedWorkMultiIds.removeAt(removeIndex);
        updatedSelectedWorkMultinames.removeAt(removeIndex);
      } else {
        // Add WorkMultiId and corresponding WorkMultiname
        updatedSelectedWorkMultiIds.add(event.workMultiId);
        updatedSelectedWorkMultinames.add(event.workMultiName);
      }

      // Emit the updated state
      emit(
        WorkMultiSuccess(
          workMulti: currentState.workMulti,
          selectedIndices: updatedSelectedWorkMultiIds,
          selectedWorkMultinames: updatedSelectedWorkMultinames,
          isLoadingMore: currentState.isLoadingMore,
        ),
      );
    }
  }
}
