import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/location/location_event.dart';
import 'package:ibex/bloc/location/location_state.dart';
import 'package:ibex/data/localStorage/hive.dart';
import 'package:ibex/data/model/location/location_model.dart';
import '../../data/repositories/location/location_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import '../../utils/user_id_mapper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  int? defaultLocationID;
  bool _isLoading = false;
  bool _hasReachedMax = false;
  int? workspcaId;
  String? workspcaTitle;
  bool? workspcaIsSelected;
  int? totalLocation;
  List<int> locationIdList = [];

  LocationBloc() : super(LocationInitial()) {
    on<LocationList>(_getLocationList);
    on<LocationRemove>(_getRemoveFromLocation);
    on<RemoveUSerFromLocation>(_onRemoveUSerFromLocation);
    on<SelectedWokspce>(_getSelectedLocation);
    on<LoadMoreLocation>(_onLoadMoreLocation);
    on<AddLocation>(_onAddLocation);
    on<UpdateLocation>(_onLocationupdate);
    on<SearchLocation>(_onSearchLocation);
    on<CreateRemoveLocation>(_onSetLocation);
    on<ToggleLocationSelection>(_onToggleLocationSelection);
  }
  @override
  void onTransition(Transition<LocationEvent, LocationState> transition) {
    super.onTransition(transition);
  }

  Future<void> _onAddLocation(
    AddLocation event,
    Emitter<LocationState> emit,
  ) async {
    if (state is LocationPaginated) {
      final work = event.location;
      final title = work.title;

      try {
        emit(LocationCreateSuccessLoading());
        Map<String, dynamic> result = await LocationRepo().createLocation(
          work: LocationModel(
            title: title,
          ),
        );

        if (!result.containsKey('error')) {
          emit(LocationCreateSuccess());
        }
        if (result.containsKey('errors')) {
          emit((LocationCreateError(result['message'])));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        logger.e('Error while creating Meeting: $e');
        // Optionally, handle the error state
      }
    }
  }

  Future<void> _onSearchLocation(
    SearchLocation event,
    Emitter<LocationState> emit,
  ) async {
    try {
      _isLoading = true;
      emit(LocationLoading());

      Map<String, dynamic> result = await LocationRepo().LocationList(
        limit: _limit,
        offset: 0,
        search: event.searchQuery,
        fields: "*",
        filter: {
          "status": {"_eq": '1'}
        },
      );

      if (result.containsKey('errors') || result.containsKey('error')) {
        emit(LocationError(result['message'] ?? 'Unknown error'));
        return;
      }

      final rawData = result['data'];
      final List<LocationModel> location = rawData != null
          ? List<LocationModel>.from(
              rawData.map((d) => LocationModel.fromJson(d)),
            )
          : [];

      emit(
        LocationPaginated(
          location: location,
          hasReachedMax: location.length < _limit,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(LocationError("Error: $e"));
    } finally {
      _isLoading = false;
    }
  }

  void _onToggleLocationSelection(
    ToggleLocationSelection event,
    Emitter<LocationState> emit,
  ) {
    if (state is LocationSuccess) {
      final currentState = state as LocationSuccess;

      // Create local copies of selected userIds and usernames to avoid mutation issues
      // final updatedSelectedUserIds = List<int>.from(
      //   currentState.selectedIndices,
      // );
      // final updatedSelectedUsernames = List<String>.from(
      //   currentState.selectedUsernames,
      // );

      // // Check if the userId is already selected
      // final isSelected = updatedSelectedUserIds.contains(event.userId);
      // if (isSelected) {
      //   // If selected, find the index of userId and remove it along with the corresponding username
      //   final removeIndex = updatedSelectedUserIds.indexOf(event.userId);
      //   updatedSelectedUserIds.removeAt(removeIndex);
      //   updatedSelectedUsernames.removeAt(removeIndex);
      // } else {
      //   // If not selected, add the userId and corresponding username
      //   updatedSelectedUserIds.add(event.userId);
      //   updatedSelectedUsernames.add(event.userName);
      // }

      // // Emit the updated state with the toggled selection
      // emit(
      //   LocationSuccess(
      //     user: currentState.user,
      //     selectedIndices: updatedSelectedUserIds,
      //     selectedUsernames: updatedSelectedUsernames,
      //     isLoadingMore: currentState.isLoadingMore,
      //   ),
      // );

      // Debugging log for checking the updated usernames
    }
  }

  void _onLocationupdate(
    UpdateLocation event,
    Emitter<LocationState> emit,
  ) async {
    if (state is LocationPaginated) {
      final work = event.location;
      final id = work.id;
      final title = work.title;

      emit(LocationEditSuccessLoading());

      try {
        Map<String, dynamic> result = await LocationRepo().updateLocation(
          id: id!,
          title: event.name ?? title!,
        );

        if (!result.containsKey('error')) {
          emit(LocationEditSuccess());
          String successMsg = event.isTeamUpdate
              ? 'Team updated successfully'
              : 'Location updated successfully';
          flutterToastCustom(
            msg: successMsg,
            color: Colors.green,
          );
        } else if (result.containsKey('errors')) {
          emit(LocationEditError(result['message'] ?? 'Update failed'));
          flutterToastCustom(msg: result['message'] ?? 'Update failed');
        }
      } catch (e) {
        logger.e('Error while updating: $e');
        String errorMsg = event.isTeamUpdate
            ? 'Error updating team: ${e.toString()}'
            : 'Error updating location: ${e.toString()}';
        emit(LocationEditError(errorMsg));
        flutterToastCustom(msg: errorMsg);
      }
    }
  }

  Future<void> _getLocationList(
    LocationList event,
    Emitter<LocationState> emit,
  ) async {
    // Guard against duplicate calls
    if (_isLoading) {
      return;
    }

    try {
      _isLoading = false;
      _offset = 0;
      _hasReachedMax = false;

      emit(LocationLoading());

      // Get current user's ID and convert to UUID
      int currentUserId = await HiveStorage.getUserId();
      String currentUserUuid = UserIdMapper().getUuid(currentUserId) ?? '';

      Map<String, dynamic> result = await LocationRepo().LocationList(
        offset: _offset,
        limit: _limit,
        fields: "*",
        filter: {
          "status": {"_eq": '1'}
        },
      );

      if (result['data'] != null && result['data'] is List) {
        for (var team in result['data']) {
          if (team['id'] != null) {
            locationIdList.add(team['id']);
          }
        }
        locationIdList = locationIdList.toSet().toList();

        // print('taaaams ${result['data']}');
        if (locationIdList.isNotEmpty) {
          await HiveStorage.setLocationIdList(locationIdList);
        }
      }

      if (result['data'] != null) {
        List<LocationModel> location = [];

        // Parse each location individually with error handling
        for (var projectData in result['data']) {
          try {
            location.add(LocationModel.fromJson(projectData));
          } catch (e) {
            logger.e("Error parsing location item: $e");
            // Skip this location and continue with others
            continue;
          }
        }

        // print("locationList_result $result");

        // Calculate if we've reached max (handle null total)
        int totalCount = result['data'].length ?? 0;
        _hasReachedMax = location.length >= totalCount;
        totalLocation = location.length;
        // Set offset to the length of data we've received
        _offset = location.length;
        _isLoading = location.length <= totalCount;

        emit(
          LocationPaginated(
            location: location,
            locationIdList: locationIdList,
            hasReachedMax: _hasReachedMax,
            isLoading: _isLoading, // Set to false after completion
          ),
        );
        // print("nfvcm   $state");
      }
      if (result.containsKey('errors')) {
        emit(LocationError(" ${result['message']}"));
      }
    } on ApiException catch (e) {
      logger.e("API Exception: $e");
      emit(LocationError("Error: $e"));
    } finally {
      _isLoading = false; // Reset loading flag in finally block
    }
  }

  Future<void> _onSetLocation(
    CreateRemoveLocation event,
    Emitter<LocationState> emit,
  ) async {
    try {
      int id = event.id;
      await LocationRepo().getLocationPrimary(
        id: id,
        defaultPrimary: event.defaultPrimary,
      );
      workspcaId = event.id;
      emit(CreatePrimaryLocationSuccess(id));
      add(LocationList());
    } on ApiException catch (e) {
      logger.e("API Exception: $e");
      emit(LocationError("Error: $e"));
    }
  }

  Future<void> _getRemoveFromLocation(
    LocationRemove event,
    Emitter<LocationState> emit,
  ) async {
    final workspcaId = event.id;
    try {
      await LocationRepo().LocationRemove(id: workspcaId);
      emit(LocationDeleteSuccess());
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  Future<void> _onRemoveUSerFromLocation(
    RemoveUSerFromLocation event,
    Emitter<LocationState> emit,
  ) async {
    final workspcaId = event.id;
    try {
      await LocationRepo().LocationRemove(id: workspcaId);
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  Future<void> _getSelectedLocation(
    SelectedWokspce event,
    Emitter<LocationState> emit,
  ) async {
    try {
      workspcaId = event.id;
      workspcaTitle = event.title;
      workspcaIsSelected = event.isSelected;
      await HiveStorage.setLocationId(workspcaId!);
      await HiveStorage.setLocationName(workspcaTitle!);
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  bool _isFetching = false; // Add a flag to prevent concurrent executions

  Future<void> _onLoadMoreLocation(
    LoadMoreLocation event,
    Emitter<LocationState> emit,
  ) async {
    // Prevent concurrent executions
    if (_isFetching) return;

    // Ensure this function doesn't execute multiple times
    _isFetching = true;

    if (state is LocationPaginated && !_hasReachedMax) {
      try {
        final currentState = state as LocationPaginated;
        final updatedTodos = List<LocationModel>.from(currentState.location);

        // Fetch data from the API
        Map<String, dynamic> result = await LocationRepo().LocationList(
          limit: _limit,
          offset: _offset,
          search: event.searchQuery,
        );

        // Handle API error
        if (result.containsKey('errors')) {
          emit(LocationError(result['message']));
          flutterToastCustom(msg: result['message']);
          _isFetching = false;
          return;
        }

        // Parse the response into a list of LocationModel
        List<LocationModel> todo = List<LocationModel>.from(
          result['data'].map((todoData) => LocationModel.fromJson(todoData)),
        );

        // If no new data is returned, set `_hasReachedMax` to true
        if (todo.isEmpty) {
          _hasReachedMax = true;
          emit(
            LocationPaginated(
              location: [...updatedTodos],
              hasReachedMax: _hasReachedMax,
              isLoading: false,
            ),
          );
          _isFetching = false; // Reset flag
          return;
        }

        // Update `_offset` and merge the new data
        _offset += todo.length; // This happens only once per successful fetch
        updatedTodos.addAll(todo);

        // Calculate `_hasReachedMax` based on `result['total']`
        int totalAvailable = result['total'];
        _hasReachedMax = updatedTodos.length >= totalAvailable;

        // Emit the updated state
        _isLoading =
            !_hasReachedMax; // Only loading if there are more items to fetch
        emit(
          LocationPaginated(
            location: [...updatedTodos],
            hasReachedMax: _hasReachedMax,
            isLoading: _isLoading,
          ),
        );
      } catch (e) {
        logger.e("Error occurred: $e");
        emit(LocationError("Error: $e"));
      } finally {
        // Ensure the fetching flag is reset
        _isFetching = false;
      }
    } else {
      _isFetching = false; // Reset flag if state conditions fail
    }
  }
}
