import 'package:equatable/equatable.dart';

import '../../data/model/inspection/inspection.dart';

abstract class InspectionidState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionidInitial extends InspectionidState {}

class InspectionidLoading extends InspectionidState {}

class InspectionidWithId extends InspectionidState {
  final List<InspectionModel> work;
  final dynamic inspectionsUsers;

  InspectionidWithId(this.work, {this.inspectionsUsers});
  @override
  List<Object> get props => [work, inspectionsUsers ?? ''];
}

class InspectionidError extends InspectionidState {
  final String errorMessage;

  InspectionidError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
