import 'package:equatable/equatable.dart';

import '../../../data/model/work/part.dart';

abstract class WorkPartState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkPartInitial extends WorkPartState {}

class WorkPartWithId extends WorkPartState {
  final List<WorksPart> WorkPart;

  WorkPartWithId(
    this.WorkPart,
  );
  @override
  List<Object> get props => [WorkPart];
}

class WorkPartLoading extends WorkPartState {}

class WorkPartSuccess extends WorkPartState {
  WorkPartSuccess(this.WorkPart, this.selectedIndex, this.selectedTitle,
      this.isLoadingMore);
  final List<WorksPart> WorkPart;
  final int? selectedIndex;
  final String selectedTitle;
  final bool isLoadingMore;

  @override
  List<Object> get props =>
      [WorkPart, selectedIndex!, selectedTitle, isLoadingMore];
}

class WorkPartPaginated extends WorkPartState {
  final List<WorksPart> WorkPart;
  final bool hasReachedMax;

  WorkPartPaginated({
    required this.WorkPart,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [WorkPart, hasReachedMax];
}

class WorkPartPartPaginated extends WorkPartState {
  final List<WorksPart> WorkPartPart;
  final bool hasReachedMax;

  WorkPartPartPaginated({
    required this.WorkPartPart,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [WorkPartPart, hasReachedMax];
}

class WorkPartError extends WorkPartState {
  final String errorMessage;
  WorkPartError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkPartCreateLoading extends WorkPartState {}

class WorkPartCreateSuccess extends WorkPartState {
  final List<WorksPart> createWorkPart;
  WorkPartCreateSuccess(this.createWorkPart);
  @override
  List<Object> get props => [createWorkPart];
}

class WorkPartEditLoading extends WorkPartState {}

class WorkPartEditSuccess extends WorkPartState {
  final List<WorksPart> editWorkPart;
  WorkPartEditSuccess(this.editWorkPart);
  @override
  List<Object> get props => [editWorkPart];
}

class WorkPartCreateError extends WorkPartState {
  final String errorMessage;
  WorkPartCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkPartEditError extends WorkPartState {
  final String errorMessage;
  WorkPartEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkPartDeleteSuccess extends WorkPartState {
  WorkPartDeleteSuccess();
  @override
  List<Object> get props => [];
}

class WorkPartDeleteError extends WorkPartState {
  final String errorMessage;
  WorkPartDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
