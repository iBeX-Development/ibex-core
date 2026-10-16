import "package:equatable/equatable.dart";
import "package:ibex/data/model/asset/asset_model.dart";

abstract class AssetEvent extends Equatable {
  const AssetEvent();

  @override
  List<Object?> get props => [];
}

class AssetList extends AssetEvent {
  const AssetList();
  @override
  List<Object> get props => [];
}

class AssetRemove extends AssetEvent {
  final int id;

  const AssetRemove({required this.id});
  @override
  List<Object> get props => [id];
}

class RemoveUSerFromAsset extends AssetEvent {
  final int id;

  const RemoveUSerFromAsset({required this.id});
  @override
  List<Object> get props => [id];
}

class ToggleAssetSelection extends AssetEvent {
  final int teamId;
  final String name;

  ToggleAssetSelection(this.teamId, this.name);
}

class SelectedAsset extends AssetEvent {
  final int id;
  final String title;
  final bool isSelected;

  const SelectedAsset({
    required this.id,
    required this.title,
    required this.isSelected,
  });
  @override
  List<Object> get props => [id];
}

class SearchAsset extends AssetEvent {
  final String searchQuery;

  const SearchAsset(this.searchQuery);

  @override
  List<Object?> get props => [searchQuery];
}

class LoadMoreAsset extends AssetEvent {
  final String? searchQuery;

  const LoadMoreAsset({this.searchQuery});

  @override
  List<Object?> get props => [searchQuery];
}

class AllAssetList extends AssetEvent {
  const AllAssetList();

  @override
  List<Object> get props => [];
}

class AddAsset extends AssetEvent {
  final AssetModel asset;

  const AddAsset(this.asset);

  @override
  List<Object?> get props => [asset];
}

class UpdateAsset extends AssetEvent {
  final AssetModel asset;

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

  const UpdateAsset(
    this.asset, {
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
        asset,
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

class CreateRemoveAsset extends AssetEvent {
  final int id;
  final int defaultPrimary;

  const CreateRemoveAsset({required this.id, required this.defaultPrimary});
  @override
  List<Object> get props => [id];
}
