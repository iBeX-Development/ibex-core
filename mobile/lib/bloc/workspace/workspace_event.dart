import "package:equatable/equatable.dart";
import "package:ibex/data/model/workspace/workspace_model.dart";

abstract class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();

  @override
  List<Object?> get props => [];
}

class WorkspaceList extends WorkspaceEvent {
  const WorkspaceList();
  @override
  List<Object> get props => [];
}

class WorkspaceRemove extends WorkspaceEvent {
  final int id;

  const WorkspaceRemove({required this.id});
  @override
  List<Object> get props => [id];
}

class RemoveUSerFromWorkspace extends WorkspaceEvent {
  final int id;

  const RemoveUSerFromWorkspace({required this.id});
  @override
  List<Object> get props => [id];
}

class ToggleWorkspaceSelection extends WorkspaceEvent {
  final int teamId;
  final String name;

  ToggleWorkspaceSelection(this.teamId, this.name);
}

class SelectedWokspce extends WorkspaceEvent {
  final int id;
  final String title;
  final bool isSelected;

  const SelectedWokspce({
    required this.id,
    required this.title,
    required this.isSelected,
  });
  @override
  List<Object> get props => [id];
}

class SearchWorkspace extends WorkspaceEvent {
  final String searchQuery;
  final String currentUserId;

  const SearchWorkspace(this.searchQuery, this.currentUserId);

  @override
  List<Object?> get props => [searchQuery, currentUserId];
}

class LoadMoreWorkspace extends WorkspaceEvent {
  final String? searchQuery;
  const LoadMoreWorkspace({this.searchQuery});

  @override
  List<Object?> get props => [searchQuery];
}

class AllWorkspaceList extends WorkspaceEvent {
  const AllWorkspaceList();

  @override
  List<Object> get props => [];
}

class AddWorkspace extends WorkspaceEvent {
  final WorkspaceModel workspace;

  const AddWorkspace(this.workspace);

  @override
  List<Object?> get props => [workspace];
}

class UpdateWorkspace extends WorkspaceEvent {
  final WorkspaceModel workspace;

  // Team update parameters
  final String? name;
  final String? description;
  final List<String>? createTeamLeaderIds;
  final List<String>? updateTeamLeaderIds;
  final List<int>? deleteTeamLeaderIds;
  final List<String>? createTeamUserIds;
  final List<String>? updateTeamUserIds;
  final List<int>? deleteTeamUserIds;
  final String? imageId;
  final bool isTeamUpdate;

  const UpdateWorkspace(
    this.workspace, {
    this.name,
    this.description,
    this.createTeamLeaderIds,
    this.updateTeamLeaderIds,
    this.deleteTeamLeaderIds,
    this.createTeamUserIds,
    this.updateTeamUserIds,
    this.deleteTeamUserIds,
    this.imageId,
    this.isTeamUpdate = false,
  });

  @override
  List<Object?> get props => [
        workspace,
        name,
        description,
        createTeamLeaderIds,
        updateTeamLeaderIds,
        deleteTeamLeaderIds,
        createTeamUserIds,
        updateTeamUserIds,
        deleteTeamUserIds,
        imageId,
        isTeamUpdate,
      ];
}

class CreateRemoveWorkspace extends WorkspaceEvent {
  final int id;
  final int defaultPrimary;

  const CreateRemoveWorkspace({required this.id, required this.defaultPrimary});
  @override
  List<Object> get props => [id];
}
