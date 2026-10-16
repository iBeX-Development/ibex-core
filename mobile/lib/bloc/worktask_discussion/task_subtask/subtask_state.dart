import 'package:equatable/equatable.dart';

import '../../../data/model/work/milestone.dart';

abstract class WorkSubTaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkSubTaskInitial extends WorkSubTaskState {}

class WorkSubTaskWithId extends WorkSubTaskState {
  final List<WorksMilestone> SubTask;

  WorkSubTaskWithId(
    this.SubTask,
  );
  @override
  List<Object> get props => [SubTask];
}

class WorkSubTaskLoading extends WorkSubTaskState {}

class WorkSubTaskSuccess extends WorkSubTaskState {
  WorkSubTaskSuccess(
      this.SubTask, this.selectedIndex, this.selectedTitle, this.isLoadingMore);
  final List<WorksMilestone> SubTask;
  final int? selectedIndex;
  final String selectedTitle;
  final bool isLoadingMore;

  @override
  List<Object> get props =>
      [SubTask, selectedIndex!, selectedTitle, isLoadingMore];
}

class WorkSubTaskPaginated extends WorkSubTaskState {
  final List<WorksMilestone> SubTask;
  final bool hasReachedMax;

  WorkSubTaskPaginated({
    required this.SubTask,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [SubTask, hasReachedMax];
}

class WorkSubTaskMileStonePaginated extends WorkSubTaskState {
  final List<WorksMilestone> SubTaskWorksMilestone;
  final bool hasReachedMax;

  WorkSubTaskMileStonePaginated({
    required this.SubTaskWorksMilestone,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [SubTaskWorksMilestone, hasReachedMax];
}

class WorkSubTaskError extends WorkSubTaskState {
  final String errorMessage;
  WorkSubTaskError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkSubTaskCreateLoading extends WorkSubTaskState {}

class WorkSubTaskCreateSuccess extends WorkSubTaskState {
  final List<WorksMilestone> createSubTask;
  WorkSubTaskCreateSuccess(this.createSubTask);
  @override
  List<Object> get props => [createSubTask];
}

class WorkSubTaskEditLoading extends WorkSubTaskState {}

class WorkSubTaskEditSuccess extends WorkSubTaskState {
  final List<WorksMilestone> editSubTask;
  WorkSubTaskEditSuccess(this.editSubTask);
  @override
  List<Object> get props => [editSubTask];
}

class WorkSubTaskCreateError extends WorkSubTaskState {
  final String errorMessage;
  WorkSubTaskCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkSubTaskEditError extends WorkSubTaskState {
  final String errorMessage;
  WorkSubTaskEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkSubTaskDeleteSuccess extends WorkSubTaskState {
  WorkSubTaskDeleteSuccess();
  @override
  List<Object> get props => [];
}

class WorkSubTaskDeleteError extends WorkSubTaskState {
  final String errorMessage;
  WorkSubTaskDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
