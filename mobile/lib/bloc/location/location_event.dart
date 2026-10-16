import "package:equatable/equatable.dart";
import "package:ibex/data/model/location/location_model.dart";

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LocationList extends LocationEvent {
  const LocationList();
  @override
  List<Object> get props => [];
}

class LocationRemove extends LocationEvent {
  final int id;

  const LocationRemove({required this.id});
  @override
  List<Object> get props => [id];
}

class RemoveUSerFromLocation extends LocationEvent {
  final int id;

  const RemoveUSerFromLocation({required this.id});
  @override
  List<Object> get props => [id];
}

class ToggleLocationSelection extends LocationEvent {
  final int teamId;
  final String name;

  ToggleLocationSelection(this.teamId, this.name);
}

class SelectedWokspce extends LocationEvent {
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

class SearchLocation extends LocationEvent {
  final String searchQuery;
  final String currentUserId;

  const SearchLocation(this.searchQuery, this.currentUserId);

  @override
  List<Object?> get props => [searchQuery, currentUserId];
}

class LoadMoreLocation extends LocationEvent {
  final String? searchQuery;
  const LoadMoreLocation({this.searchQuery});

  @override
  List<Object?> get props => [searchQuery];
}

class AllLocationList extends LocationEvent {
  const AllLocationList();

  @override
  List<Object> get props => [];
}

class AddLocation extends LocationEvent {
  final LocationModel location;

  const AddLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class UpdateLocation extends LocationEvent {
  final LocationModel location;

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

  const UpdateLocation(
    this.location, {
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
        location,
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

class CreateRemoveLocation extends LocationEvent {
  final int id;
  final int defaultPrimary;

  const CreateRemoveLocation({required this.id, required this.defaultPrimary});
  @override
  List<Object> get props => [id];
}
