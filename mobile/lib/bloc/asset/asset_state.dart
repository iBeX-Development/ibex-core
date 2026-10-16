import 'package:equatable/equatable.dart';
import 'package:ibex/data/model/asset/asset_model.dart';

abstract class AssetState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AssetInitial extends AssetState {}

class AssetLoading extends AssetState {}

class AssetPaginated extends AssetState {
  final List<AssetModel> asset;
  final bool hasReachedMax;
  final bool isLoading;

  AssetPaginated({
    required this.asset,
    required this.hasReachedMax,
    required this.isLoading,
  });

  @override
  List<Object?> get props => [asset, hasReachedMax, isLoading];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AssetPaginated &&
        other.asset == asset &&
        other.hasReachedMax == hasReachedMax &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode => Object.hash(asset, hasReachedMax, isLoading);
}

class AssetSuccess extends AssetState {
  AssetSuccess([this.asset = const []]);

  final List<AssetModel> asset;

  @override
  List<Object> get props => [asset];
}

class AssetError extends AssetState {
  final String errorMessage;
  AssetError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class AssetDeleteSuccess extends AssetState {
  AssetDeleteSuccess();
  @override
  List<Object> get props => [];
}

class AssetDeleteError extends AssetState {
  final String errorMessage;
  AssetDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class AssetCreateError extends AssetState {
  final String errorMessage;

  AssetCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class AssetEditError extends AssetState {
  final String errorMessage;

  AssetEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class AssetEditSuccess extends AssetState {
  AssetEditSuccess();
  @override
  List<Object> get props => [];
}

class AssetCreateSuccessLoading extends AssetState {}

class AssetEditSuccessLoading extends AssetState {}

class AssetCreateSuccess extends AssetState {
  AssetCreateSuccess();
  @override
  List<Object> get props => [];
}

class CreatePrimaryAssetSuccess extends AssetState {
  final int id;
  CreatePrimaryAssetSuccess(this.id);
  @override
  List<Object> get props => [id];
}
