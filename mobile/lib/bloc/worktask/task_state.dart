import 'package:equatable/equatable.dart';

import '../../data/model/worktask/task_model.dart';

abstract class WorkTaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkTaskInitial extends WorkTaskState {}

class WorkTaskLoading extends WorkTaskState {}

class TodaysWorkTaskLoading extends WorkTaskState {}

class WorkTaskSuccess extends WorkTaskState {
  WorkTaskSuccess(
    this.task,
  );

  final List<WorkTasks> task;

  @override
  List<Object> get props => [task];
}

class AllWorkTaskSuccess extends WorkTaskState {
  AllWorkTaskSuccess(
    this.allTask,
  );

  final List<WorkTasks> allTask;

  @override
  List<Object> get props => [allTask];
}

class WorkTaskError extends WorkTaskState {
  final String errorMessage;

  WorkTaskError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkTaskPaginated extends WorkTaskState {
  final List<WorkTasks> task;
  final bool hasReachedMax;
  final bool isToday;

  WorkTaskPaginated({
    required this.task,
    required this.hasReachedMax,
    required this.isToday,
  });

  @override
  List<Object> get props => [task, hasReachedMax, isToday];
}

class TodayWorkTaskSuccess extends WorkTaskState {
  final List<WorkTasks> task;
  final bool hasReachedMax;

  TodayWorkTaskSuccess({
    required this.task,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [task, hasReachedMax];
}

class WorkTaskCreateError extends WorkTaskState {
  final String errorMessage;

  WorkTaskCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkTaskEditError extends WorkTaskState {
  final String errorMessage;

  WorkTaskEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkTaskFavPaginated extends WorkTaskState {
  final List<WorkTasks> task;
  final bool hasReachedMax;

  WorkTaskFavPaginated({
    required this.task,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [task, hasReachedMax];
}

class WorkTaskEditSuccessLoading extends WorkTaskState {}

class WorkTaskEditSuccess extends WorkTaskState {
  WorkTaskEditSuccess();
  @override
  List<Object> get props => [];
}

class WorkTaskCreateSuccessLoading extends WorkTaskState {}

class WorkTaskCreateSuccess extends WorkTaskState {
  WorkTaskCreateSuccess();
  @override
  List<Object> get props => [];
}

class WorkTaskDeleteError extends WorkTaskState {
  final String errorMessage;

  WorkTaskDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkTaskDeleteSuccess extends WorkTaskState {
  WorkTaskDeleteSuccess();
  @override
  List<Object> get props => [];
}
