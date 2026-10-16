import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/inspection_multi/inspection_multi_event.dart';
import 'package:ibex/bloc/inspection_multi/inspection_multi_state.dart';
import '../../data/model/Inspection/inspection.dart';
import '../../data/repositories/inspection/inspection_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import '../../data/localStorage/hive.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionMultiBloc
    extends Bloc<InspectionMultiEvent, InspectionMultiState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 16;
  bool _hasReachedMax = false;
  List<Object> woStatusData = [];
  InspectionMultiBloc() : super(InspectionMultiInitial()) {
    _initializeStatusData();
    on<InspectionMultiList>(_getInspectionMultiList);
    on<SelectedInspectionMulti>(_onSelectInspectionMulti);
    on<InspectionMultiLoadMore>(_onLoadMore);
    on<ToggleInspectionMultiSelection>(_onToggleInspectionMultiSelection);
    on<SearchInspectionMultis>(_onSearchInspectionMulti);
  }

  Future<void> _initializeStatusData() async {
    woStatusData = await HiveStorage.getAllStatusData();
  }

  Future<void> _getInspectionMultiList(
    InspectionMultiList event,
    Emitter<InspectionMultiState> emit,
  ) async {
    try {
      List<InspectionModel> workMultis = [];
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(InspectionMultiLoading());
      Map<String, dynamic> result = await InspectionRepo().getInspections(
        limit: _limit,
        offset: _offset,
      );
      workMultis = List<InspectionModel>.from(
        result['data'].map(
            (workData) => InspectionModel.fromJson(workData, woStatusData)),
      );
      _offset += _limit;
      _hasReachedMax = workMultis.length >= result['total'];

      emit(
        InspectionMultiPaginated(
          workMulti: workMultis,
          hasReachedMax: _hasReachedMax,
        ),
      );
    } on ApiException catch (e) {
      logger.e("Error: $e");
      emit((InspectionMultiError("Error: $e")));
    }
  }

  Future<void> _onSearchInspectionMulti(
    SearchInspectionMultis event,
    Emitter<InspectionMultiState> emit,
  ) async {
    try {
      List<InspectionModel> workMulti = [];
      // emit(InspectionMultiLoading());
      Map<String, dynamic> result = await InspectionRepo().getInspections(
        limit: _limit,
        offset: 0,
        search: event.searchQuery,
      );
      workMulti = List<InspectionModel>.from(
        result['data'].map(
            (workData) => InspectionModel.fromJson(workData, woStatusData)),
      );

      bool hasReachedMax = workMulti.length >= result['total'];
      if (!result.containsKey('error')) {
        emit(
          InspectionMultiPaginated(
            workMulti: workMulti,
            hasReachedMax: hasReachedMax,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((InspectionMultiError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      flutterToastCustom(msg: "$e");

      emit(InspectionMultiError("Error: $e"));
    }
  }

  Future<void> _onLoadMore(
    InspectionMultiLoadMore event,
    Emitter<InspectionMultiState> emit,
  ) async {
    if (state is InspectionMultiPaginated && !_hasReachedMax) {
      if (kDebugMode) {
        logger.d("Loading more inspections, hasReachedMax: $_hasReachedMax");
      }
      try {
        final currentState = state as InspectionMultiPaginated;
        final updatedNotification = List<InspectionModel>.from(
          currentState.workMulti,
        );

        // Fetch additional Notifications from the repository
        List<InspectionModel> additionalNotes = [];
        Map<String, dynamic> result = await InspectionRepo().getInspections(
          limit: _limit,
          offset: _offset,
        );
        additionalNotes = List<InspectionModel>.from(
          result['data'].map(
              (workData) => InspectionModel.fromJson(workData, woStatusData)),
        );
        // Update the offset for the next load
        _offset = updatedNotification.length;

        // Check if the D number of items has been reached

        if (currentState.workMulti.length >= result['total']) {
          _hasReachedMax = true;
        } else {
          _hasReachedMax = false;
        }

        // Add the newly fetched Notifications to the existing list
        updatedNotification.addAll(additionalNotes);
        if (!result.containsKey('error')) {
          emit(
            InspectionMultiPaginated(
              workMulti: updatedNotification,
              hasReachedMax: _hasReachedMax,
            ),
          );
        }
        if (result.containsKey('errors')) {
          emit((InspectionMultiError(result['message'])));
          flutterToastCustom(msg: result['message']);
        }
        // Emit the new state with the updated Notification list and hasReachedMax flag
      } on ApiException catch (e) {
        // Handle any errors that occur during the API call
        emit(InspectionMultiError("Error: $e"));
      }
    }
  }

  void _onSelectInspectionMulti(
    SelectedInspectionMulti event,
    Emitter<InspectionMultiState> emit,
  ) {
    if (state is InspectionMultiSuccess) {
      final currentState = state as InspectionMultiSuccess;

      final selectedIndices = List<int>.from(currentState.selectedIndices);
      final selectedInspectionMultinames = List<String>.from(
        currentState.selectedInspectionMultinames,
      );

      if (selectedIndices.contains(event.selectedIndex)) {
        selectedIndices.remove(event.selectedIndex);
        selectedInspectionMultinames.remove(event.selectedTitle);
      } else {
        selectedIndices.add(event.selectedIndex);
        selectedInspectionMultinames.add(event.selectedTitle);
      }

      emit(
        InspectionMultiSuccess(
          workMulti: currentState.workMulti,
          selectedIndices: selectedIndices,
          selectedInspectionMultinames: selectedInspectionMultinames,
          isLoadingMore: currentState.isLoadingMore,
        ),
      );
    }
  }

  void _onToggleInspectionMultiSelection(
    ToggleInspectionMultiSelection event,
    Emitter<InspectionMultiState> emit,
  ) {
    if (state is InspectionMultiSuccess) {
      final currentState = state as InspectionMultiSuccess;

      // Create local copies to avoid mutation issues
      final updatedSelectedInspectionMultiIds = List<int>.from(
        currentState.selectedIndices,
      );
      final updatedSelectedInspectionMultinames = List<String>.from(
        currentState.selectedInspectionMultinames,
      );

      // Check if the InspectionMulti is already selected based on InspectionMultiId
      final isSelected = updatedSelectedInspectionMultiIds.contains(
        event.workMultiId,
      );

      if (isSelected) {
        // Find the index of the InspectionMultiId in the selectedIndices list
        final removeIndex = updatedSelectedInspectionMultiIds.indexOf(
          event.workMultiId,
        );

        // Remove InspectionMultiId and corresponding InspectionMultiname
        updatedSelectedInspectionMultiIds.removeAt(removeIndex);
        updatedSelectedInspectionMultinames.removeAt(removeIndex);
      } else {
        // Add InspectionMultiId and corresponding InspectionMultiname
        updatedSelectedInspectionMultiIds.add(event.workMultiId);
        updatedSelectedInspectionMultinames.add(event.workMultiName);
      }

      // Emit the updated state
      emit(
        InspectionMultiSuccess(
          workMulti: currentState.workMulti,
          selectedIndices: updatedSelectedInspectionMultiIds,
          selectedInspectionMultinames: updatedSelectedInspectionMultinames,
          isLoadingMore: currentState.isLoadingMore,
        ),
      );
    }
  }
}
