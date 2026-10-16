import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/workspace/workspace_event.dart';
import 'package:ibex/bloc/workspace/workspace_state.dart';
import 'package:ibex/data/localStorage/hive.dart';
import 'package:ibex/data/model/workspace/workspace_model.dart';
import '../../data/repositories/workspace/workspace_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import '../../utils/user_id_mapper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  int? defaultWorkspaceID;
  bool _isLoading = false;
  bool _hasReachedMax = false;
  int? workspcaId;
  String? workspcaTitle;
  bool? workspcaIsSelected;
  int? totalWorkspace;
  List<int> teamsIdList = [];

  WorkspaceBloc() : super(WorkspaceInitial()) {
    on<WorkspaceList>(_getWorkSpaceList);
    on<WorkspaceRemove>(_getRemoveFromWorkSpace);
    on<RemoveUSerFromWorkspace>(_onRemoveUSerFromWorkspace);
    on<SelectedWokspce>(_getSelectedWorkSpace);
    on<LoadMoreWorkspace>(_onLoadMoreWorkspace);
    on<AddWorkspace>(_onAddWorkspace);
    on<UpdateWorkspace>(_onWorkspaceupdate);
    on<SearchWorkspace>(_onSearchWorkspace);
    on<CreateRemoveWorkspace>(_onSetWorkSpace);
    on<ToggleWorkspaceSelection>(_onToggleWorkspaceSelection);
  }
  @override
  void onTransition(Transition<WorkspaceEvent, WorkspaceState> transition) {
    super.onTransition(transition);
  }

  Future<void> _onAddWorkspace(
    AddWorkspace event,
    Emitter<WorkspaceState> emit,
  ) async {
    if (state is WorkspacePaginated) {
      final work = event.workspace;
      final title = work.title;
      final primaryWorkspcae = work.primaryWorkspace;
      final userID = work.userIds;
      final clientID = work.clientIds;
      final teamLeaderIds = work.teamLeaderIds;

      try {
        emit(WorkspaceCreateSuccessLoading());
        Map<String, dynamic> result = await WorkspaceRepo().createWorkspace(
          work: WorkspaceModel(
            title: title,
            primaryWorkspace: primaryWorkspcae,
            userIds: userID,
            clientIds: clientID,
          ),
        );

        // print('Create result: $result');
        if (!result.containsKey('error')) {
          emit(WorkspaceCreateSuccess());
        }
        if (result.containsKey('errors')) {
          emit((WorkspaceCreateError(result['message'])));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while creating Meeting: $e');
        }
        // Optionally, handle the error state
      }
    }
  }

  Future<void> _onSearchWorkspace(
    SearchWorkspace event,
    Emitter<WorkspaceState> emit,
  ) async {
    try {
      _isLoading = true; // Set loading state to true

      emit(WorkspaceLoading());
      List<WorkspaceModel> workspace = [];
      Map<String, dynamic> result = await WorkspaceRepo().workspaceList(
        limit: _limit,
        offset: 0,
        search: event.searchQuery,
        fields:
            "*,users.*,users.directus_users_id.id,users.directus_users_id.first_name,users.directus_users_id.last_name,users.directus_users_id.avatar,users.directus_users_id.email,team_leaders.directus_users_id.id,team_leaders.directus_users_id.first_name,team_leaders.directus_users_id.last_name,team_leaders.directus_users_id.avatar",
        filter: {
          "users": {
            "directus_users_id": {"_eq": event.currentUserId},
          },
          "active": {"_eq": 1},
        },
      );
      bool hasReachedMax = workspace.length < _limit;
      workspace = List<WorkspaceModel>.from(
        result['data'].map(
          (projectData) => WorkspaceModel.fromJson(projectData),
        ),
      );
      if (!result.containsKey('error')) {
        emit(
          WorkspacePaginated(
            workspace: workspace,
            hasReachedMax: hasReachedMax,
            isLoading: _isLoading,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((WorkspaceError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      emit(WorkspaceError("Error: $e"));
    } finally {
      _isLoading = false; // Reset loading state
    }
  }

  void _onToggleWorkspaceSelection(
    ToggleWorkspaceSelection event,
    Emitter<WorkspaceState> emit,
  ) {
    if (state is WorkspaceSuccess) {
      final currentState = state as WorkspaceSuccess;

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
      //   WorkspaceSuccess(
      //     user: currentState.user,
      //     selectedIndices: updatedSelectedUserIds,
      //     selectedUsernames: updatedSelectedUsernames,
      //     isLoadingMore: currentState.isLoadingMore,
      //   ),
      // );

      // Debugging log for checking the updated usernames
    }
  }

  void _onWorkspaceupdate(
    UpdateWorkspace event,
    Emitter<WorkspaceState> emit,
  ) async {
    if (state is WorkspacePaginated) {
      final work = event.workspace;
      final id = work.id;
      final title = work.title;
      final userId = work.userIds;

      emit(WorkspaceEditSuccessLoading());

      try {
        Map<String, dynamic> result = await WorkspaceRepo().updateWorkspace(
          id: id!,
          title: event.name ?? title!,
          userId: userId!,
          // Team update parameters from event
          name: event.name,
          description: event.description,
          createTeamLeaderIds: event.createTeamLeaderIds,
          updateTeamLeaderIds: event.updateTeamLeaderIds,
          deleteTeamLeaderIds: event.deleteTeamLeaderIds,
          createTeamUserIds: event.createTeamUserIds,
          updateTeamUserIds: event.updateTeamUserIds,
          deleteTeamUserIds: event.deleteTeamUserIds,
          imageId: event.imageId,
          isTeamUpdate: event.isTeamUpdate,
        );

        if (!result.containsKey('error')) {
          emit(WorkspaceEditSuccess());
          String successMsg = event.isTeamUpdate
              ? 'Team updated successfully'
              : 'Workspace updated successfully';
          flutterToastCustom(msg: successMsg, color: Colors.green);
        } else if (result.containsKey('errors')) {
          emit(WorkspaceEditError(result['message'] ?? 'Update failed'));
          flutterToastCustom(msg: result['message'] ?? 'Update failed');
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating: $e');
        }
        String errorMsg = event.isTeamUpdate
            ? 'Error updating team: ${e.toString()}'
            : 'Error updating workspace: ${e.toString()}';
        emit(WorkspaceEditError(errorMsg));
        flutterToastCustom(msg: errorMsg);
      }
    }
  }

  Future<void> _getWorkSpaceList(
    WorkspaceList event,
    Emitter<WorkspaceState> emit,
  ) async {
    // Guard against duplicate calls
    if (_isLoading) {
      return;
    }

    try {
      _isLoading = false; // Set loading flag immediately

      // Reset initial values
      _offset = 0;
      _hasReachedMax = false;
      teamsIdList = []; // ✅ Clear teams list to avoid stale data

      emit(WorkspaceLoading());

      // Get current user's ID and convert to UUID
      int currentUserId = await HiveStorage.getUserId();
      String currentUserUuid = UserIdMapper().getUuid(currentUserId) ?? '';

      // Single API request: Get Teams filtered by current user
      // ✅ Using _or logic with _some for many-to-many relations
      Map<String, dynamic> result = await WorkspaceRepo().workspaceList(
        offset: _offset,
        limit: _limit,
        fields:
            "*,users.*,users.directus_users_id.id,users.directus_users_id.first_name,users.directus_users_id.last_name,users.directus_users_id.avatar,users.directus_users_id.email,team_leaders.directus_users_id.id,team_leaders.directus_users_id.first_name,team_leaders.directus_users_id.last_name,team_leaders.directus_users_id.avatar",
        filter: {
          "_and": [
            {
              "_or": [
                {
                  "users": {
                    "directus_users_id": {"_eq": currentUserUuid},
                  },
                },
                {
                  "team_leaders": {
                    "directus_users_id": {"_eq": currentUserUuid},
                  },
                },
              ],
            },
            {
              "active": {"_eq": 1},
            },
          ],
        },
      );

      // Extract and save Teams IDs for use in other parts of the app
      if (result['data'] != null && result['data'] is List) {
        for (var team in result['data']) {
          if (team['id'] != null) {
            teamsIdList.add(team['id']);
          }
        }
        teamsIdList = teamsIdList.toSet().toList();

        if (teamsIdList.isNotEmpty) {
          await HiveStorage.setTeamsIdList(teamsIdList);
        } else {
          // ✅ If no teams, clear the old data
          await HiveStorage.setTeamsIdList([]);
        }
      }

      if (result['data'] != null) {
        List<WorkspaceModel> workspace = [];

        // Parse each workspace individually with error handling
        for (var projectData in result['data']) {
          try {
            workspace.add(WorkspaceModel.fromJson(projectData));
          } catch (e) {
            if (kDebugMode) {
              logger.d("Error parsing workspace item: $e");
            }
            // Skip this workspace and continue with others
            continue;
          }
        }

        // Calculate if we've reached max (handle null total)
        int totalCount = result['data'].length ?? 0;
        _hasReachedMax = workspace.length >= totalCount;
        totalWorkspace = workspace.length;
        // Set offset to the length of data we've received
        _offset = workspace.length;
        _isLoading = workspace.length <= totalCount;

        emit(
          WorkspacePaginated(
            workspace: workspace,
            teamsIdList: teamsIdList,
            hasReachedMax: _hasReachedMax,
            isLoading: _isLoading, // Set to false after completion
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit(WorkspaceError(" ${result['message']}"));
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit(WorkspaceError(" $e"));
    } finally {
      _isLoading = false; // Reset loading flag in finally block
    }
  }

  Future<void> _onSetWorkSpace(
    CreateRemoveWorkspace event,
    Emitter<WorkspaceState> emit,
  ) async {
    try {
      int id = event.id;
      await WorkspaceRepo().getWorkspacePrimary(
        id: id,
        defaultPrimary: event.defaultPrimary,
      );
      workspcaId = event.id;
      emit(CreatePrimaryWorkspaceSuccess(id));
      add(WorkspaceList());
    } on ApiException catch (e) {
      emit(WorkspaceError("Error: $e"));
    }
  }

  Future<void> _getRemoveFromWorkSpace(
    WorkspaceRemove event,
    Emitter<WorkspaceState> emit,
  ) async {
    final workspcaId = event.id;
    try {
      await WorkspaceRepo().workspaceRemove(id: workspcaId);
      emit(WorkspaceDeleteSuccess());
    } catch (e) {
      emit(WorkspaceError(e.toString()));
    }
  }

  Future<void> _onRemoveUSerFromWorkspace(
    RemoveUSerFromWorkspace event,
    Emitter<WorkspaceState> emit,
  ) async {
    final workspcaId = event.id;
    try {
      await WorkspaceRepo().workspaceRemove(id: workspcaId);
    } catch (e) {
      emit(WorkspaceError(e.toString()));
    }
  }

  Future<void> _getSelectedWorkSpace(
    SelectedWokspce event,
    Emitter<WorkspaceState> emit,
  ) async {
    try {
      workspcaId = event.id;
      workspcaTitle = event.title;
      workspcaIsSelected = event.isSelected;
      await HiveStorage.setWorkspaceId(workspcaId!);
      await HiveStorage.setWorkspaceTitle(workspcaTitle!);
    } catch (e) {
      emit(WorkspaceError(e.toString()));
    }
  }

  bool _isFetching = false; // Add a flag to prevent concurrent executions

  Future<void> _onLoadMoreWorkspace(
    LoadMoreWorkspace event,
    Emitter<WorkspaceState> emit,
  ) async {
    // Prevent concurrent executions
    if (_isFetching) return;

    // Ensure this function doesn't execute multiple times
    _isFetching = true;

    if (state is WorkspacePaginated && !_hasReachedMax) {
      try {
        final currentState = state as WorkspacePaginated;
        final updatedTodos = List<WorkspaceModel>.from(currentState.workspace);

        // Fetch data from the API
        Map<String, dynamic> result = await WorkspaceRepo().workspaceList(
          limit: _limit,
          offset: _offset,
          search: event.searchQuery,
        );

        // Handle API error
        if (result.containsKey('errors')) {
          emit(WorkspaceError(result['message']));
          flutterToastCustom(msg: result['message']);
          _isFetching = false;
          return;
        }

        // Parse the response into a list of WorkspaceModel
        List<WorkspaceModel> todo = List<WorkspaceModel>.from(
          result['data'].map((todoData) => WorkspaceModel.fromJson(todoData)),
        );

        // If no new data is returned, set `_hasReachedMax` to true
        if (todo.isEmpty) {
          _hasReachedMax = true;
          emit(
            WorkspacePaginated(
              workspace: [...updatedTodos],
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
          WorkspacePaginated(
            workspace: [...updatedTodos],
            hasReachedMax: _hasReachedMax,
            isLoading: _isLoading,
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          logger.d("Error occurred: $e");
        }
        emit(WorkspaceError("Error: $e"));
      } finally {
        // Ensure the fetching flag is reset
        _isFetching = false;
      }
    } else {
      _isFetching = false; // Reset flag if state conditions fail
    }
  }
}
