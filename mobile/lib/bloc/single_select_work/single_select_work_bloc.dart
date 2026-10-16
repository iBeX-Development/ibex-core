import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/single_select_work/single_select_work_event.dart';
import 'package:ibex/bloc/single_select_work/single_select_work_state.dart';
import 'package:ibex/data/model/Work/all_work.dart';
import '../../data/repositories/Work/work_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import '../../data/localStorage/hive.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class SingleSelectWorkBloc
    extends Bloc<SingleSelectWorkEvent, SingleSelectWorkState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 13;
  bool _isFetching = false;
  List<Object> woStatusData = [];

  bool _hasReachedMax = false;

  SingleSelectWorkBloc() : super(SingleWorkInitial()) {
    _initializeStatusData();
    on<SingleWorkList>(_getSingleWorkList);
    on<SelectSingleWork>(_onSelectWork);
    on<SingleWorkLoadMore>(_onLoadMoreWork);
    on<SearchSingleWork>(_onSearchSingleWork);
  }

  Future<void> _initializeStatusData() async {
    woStatusData = await HiveStorage.getAllStatusData();
  }

  Future<void> _onSearchSingleWork(
    SearchSingleWork event,
    Emitter<SingleSelectWorkState> emit,
  ) async {
    try {
      List<WorkModel> work = [];
      // emit(UserLoading());
      _offset = 0;
      _hasReachedMax = false;
      Map<String, dynamic> result = await WorkRepo().getWorks(
        limit: _limit,
        offset: _offset,
        search: event.searchQuery,
      );
      work = List<WorkModel>.from(
        result['data'].map(
          (workData) => WorkModel.fromJson(workData, woStatusData),
        ),
      );
      _offset += _limit;
      bool hasReachedMax = work.length >= result['total'];
      if (!result.containsKey('error')) {
        emit(SingleWorkSuccess(work, -1, '', hasReachedMax));
      }
      if (result.containsKey('errors')) {
        emit(SingleWorkError(result['message']));
      }
    } on ApiException catch (e) {
      emit(SingleWorkError("Error: $e"));
    }
  }

  Future<void> _getSingleWorkList(
    SingleWorkList event,
    Emitter<SingleSelectWorkState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      List<WorkModel> priorities = [];

      Map<String, dynamic> result = await WorkRepo().getWorks(
        offset: _offset,
        limit: _limit,
      );

      priorities = List<WorkModel>.from(
        result['data'].map(
          (workData) => WorkModel.fromJson(workData, woStatusData),
        ),
      );
      // Increment offset by limit after each fetch
      _offset += _limit;

      _hasReachedMax = priorities.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(SingleWorkSuccess(priorities, -1, '', _hasReachedMax));
      } else if (result.containsKey('errors')) {
        emit(SingleWorkError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit(SingleWorkError("Error: $e"));
    }
  }

  Future<void> _onLoadMoreWork(
    SingleWorkLoadMore event,
    Emitter<SingleSelectWorkState> emit,
  ) async {
    if (state is SingleWorkSuccess && !_isFetching) {
      final currentState = state as SingleWorkSuccess;

      // Set the fetching flag to true to prevent further requests during this one
      _isFetching = true;

      try {
        // Fetch more Priorityes from the repository
        Map<String, dynamic> result = await WorkRepo().getWorks(
          limit: _limit,
          offset: _offset,
          search: event.searchQuery,
        );

        // Convert the fetched data into a list of Priorityes
        List<WorkModel> morePriorityes = List<WorkModel>.from(
          result['data'].map(
            (workData) => WorkModel.fromJson(workData, woStatusData),
          ),
        );

        // Only update the offset if new data is received
        if (morePriorityes.isNotEmpty) {
          _offset += _limit; // Increment by _limit (which is 15)
          if (kDebugMode) {
            logger.d("Updated offset: $_offset");
          }
        }

        // Check if we've reached the total number of Priorityes
        bool hasReachedMax =
            (currentState.work.length + morePriorityes.length) >=
                result['total'];

        if (!result.containsKey('error')) {
          // Emit the new state with the updated list of Priorityes
          emit(
            SingleWorkSuccess(
              [...currentState.work, ...morePriorityes],
              currentState.selectedIndex,
              currentState.selectedTitle,
              hasReachedMax,
            ),
          );
        } else {
          emit(SingleWorkError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } on ApiException catch (e) {
        if (kDebugMode) {
          logger.d("API Exception: $e");
        }

        emit(SingleWorkError("Error: $e"));
      } catch (e) {
        if (kDebugMode) {
          logger.d("Unexpected error: $e");
        }

        emit(SingleWorkError("Unexpected error occurred."));
      }

      // Reset the fetching flag after the request is completed
      _isFetching = false;
    }
  }

  void _onSelectWork(
    SelectSingleWork event,
    Emitter<SingleSelectWorkState> emit,
  ) {
    if (state is SingleWorkSuccess) {
      final currentState = state as SingleWorkSuccess;
      // Maintain the hasReachedMax value when selecting a work
      emit(
        SingleWorkSuccess(
          currentState.work,
          event.selectedIndex,
          event.selectedTitle,
          currentState.hasReachedMax, // Keep the existing hasReachedMax value
        ),
      );
    }
  }
}
