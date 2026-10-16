import 'package:equatable/equatable.dart';

import '../../../data/model/inspection/part.dart';

abstract class InspectionPartState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionPartInitial extends InspectionPartState {}

class InspectionPartWithId extends InspectionPartState {
  final List<InspectionsPart> InspectionPart;

  InspectionPartWithId(
    this.InspectionPart,
  );
  @override
  List<Object> get props => [InspectionPart];
}

class InspectionPartLoading extends InspectionPartState {}

class InspectionPartSuccess extends InspectionPartState {
  InspectionPartSuccess(this.InspectionPart, this.selectedIndex,
      this.selectedTitle, this.isLoadingMore);
  final List<InspectionsPart> InspectionPart;
  final int? selectedIndex;
  final String selectedTitle;
  final bool isLoadingMore;

  @override
  List<Object> get props =>
      [InspectionPart, selectedIndex!, selectedTitle, isLoadingMore];
}

class InspectionPartPaginated extends InspectionPartState {
  final List<InspectionsPart> InspectionPart;
  final bool hasReachedMax;

  InspectionPartPaginated({
    required this.InspectionPart,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [InspectionPart, hasReachedMax];
}

class InspectionPartPartPaginated extends InspectionPartState {
  final List<InspectionsPart> InspectionPartPart;
  final bool hasReachedMax;

  InspectionPartPartPaginated({
    required this.InspectionPartPart,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [InspectionPartPart, hasReachedMax];
}

class InspectionPartError extends InspectionPartState {
  final String errorMessage;
  InspectionPartError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionPartCreateLoading extends InspectionPartState {}

class InspectionPartCreateSuccess extends InspectionPartState {
  final List<InspectionsPart> createInspectionPart;
  InspectionPartCreateSuccess(this.createInspectionPart);
  @override
  List<Object> get props => [createInspectionPart];
}

class InspectionPartEditLoading extends InspectionPartState {}

class InspectionPartEditSuccess extends InspectionPartState {
  final List<InspectionsPart> editInspectionPart;
  InspectionPartEditSuccess(this.editInspectionPart);
  @override
  List<Object> get props => [editInspectionPart];
}

class InspectionPartCreateError extends InspectionPartState {
  final String errorMessage;
  InspectionPartCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionPartEditError extends InspectionPartState {
  final String errorMessage;
  InspectionPartEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionPartDeleteSuccess extends InspectionPartState {
  InspectionPartDeleteSuccess();
  @override
  List<Object> get props => [];
}

class InspectionPartDeleteError extends InspectionPartState {
  final String errorMessage;
  InspectionPartDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
