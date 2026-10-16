import 'package:equatable/equatable.dart';
import 'package:ibex/data/model/location/location_model.dart';

abstract class LocationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationSuccess extends LocationState {
  LocationSuccess([this.location = const []]);

  final List<LocationModel> location;

  @override
  List<Object> get props => [location];
}

class LocationError extends LocationState {
  final String errorMessage;
  LocationError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class LocationDeleteSuccess extends LocationState {
  LocationDeleteSuccess();
  @override
  List<Object> get props => [];
}

class LocationDeleteError extends LocationState {
  final String errorMessage;
  LocationDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class LocationPaginated extends LocationState {
  final List<LocationModel> location;
  final List<int>? locationIdList;
  final bool hasReachedMax;
  final bool isLoading;

  LocationPaginated({
    required this.location,
    this.locationIdList,
    required this.hasReachedMax,
    required this.isLoading,
  });

  @override
  List<Object?> get props =>
      [Location, locationIdList, hasReachedMax, isLoading];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LocationPaginated &&
        other.location == location &&
        other.locationIdList == locationIdList &&
        other.hasReachedMax == hasReachedMax &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode =>
      Object.hash(Location, locationIdList, hasReachedMax, isLoading);
}

class LocationCreateError extends LocationState {
  final String errorMessage;

  LocationCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class LocationEditError extends LocationState {
  final String errorMessage;

  LocationEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class LocationEditSuccess extends LocationState {
  LocationEditSuccess();
  @override
  List<Object> get props => [];
}

class LocationCreateSuccessLoading extends LocationState {}

class LocationEditSuccessLoading extends LocationState {}

class LocationCreateSuccess extends LocationState {
  LocationCreateSuccess();
  @override
  List<Object> get props => [];
}

class CreatePrimaryLocationSuccess extends LocationState {
  final int id;
  CreatePrimaryLocationSuccess(this.id);
  @override
  List<Object> get props => [id];
}
