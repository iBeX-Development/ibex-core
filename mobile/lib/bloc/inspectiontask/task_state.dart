import 'package:equatable/equatable.dart';

import '../../data/model/inspectiontask/task_model.dart';

abstract class InspectionTaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionTaskInitial extends InspectionTaskState {}

class InspectionTaskLoading extends InspectionTaskState {}

class TodaysInspectionTaskLoading extends InspectionTaskState {}

class InspectionTaskSuccess extends InspectionTaskState {
  InspectionTaskSuccess(
    this.task,
  );

  final List<InspectionTasks> task;

  @override
  List<Object> get props => [task];
}

class AllInspectionTaskSuccess extends InspectionTaskState {
  AllInspectionTaskSuccess(
    this.allTask,
  );

  final List<InspectionTasks> allTask;

  @override
  List<Object> get props => [allTask];
}

class InspectionTaskError extends InspectionTaskState {
  final String errorMessage;

  InspectionTaskError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionTaskPaginated extends InspectionTaskState {
  final List<InspectionTasks> task;
  final bool hasReachedMax;
  final bool isToday;

  InspectionTaskPaginated({
    required this.task,
    required this.hasReachedMax,
    required this.isToday,
  });

  @override
  List<Object> get props => [task, hasReachedMax, isToday];
}

class TodayInspectionTaskSuccess extends InspectionTaskState {
  final List<InspectionTasks> task;
  final bool hasReachedMax;

  TodayInspectionTaskSuccess({
    required this.task,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [task, hasReachedMax];
}

class InspectionTaskCreateError extends InspectionTaskState {
  final String errorMessage;

  InspectionTaskCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionTaskEditError extends InspectionTaskState {
  final String errorMessage;

  InspectionTaskEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionTaskFavPaginated extends InspectionTaskState {
  final List<InspectionTasks> task;
  final bool hasReachedMax;

  InspectionTaskFavPaginated({
    required this.task,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [task, hasReachedMax];
}

class InspectionTaskEditSuccessLoading extends InspectionTaskState {}

class InspectionTaskEditSuccess extends InspectionTaskState {
  InspectionTaskEditSuccess();
  @override
  List<Object> get props => [];
}

class InspectionTaskCreateSuccessLoading extends InspectionTaskState {}

class InspectionTaskCreateSuccess extends InspectionTaskState {
  InspectionTaskCreateSuccess();
  @override
  List<Object> get props => [];
}

class InspectionTaskDeleteError extends InspectionTaskState {
  final String errorMessage;

  InspectionTaskDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionTaskDeleteSuccess extends InspectionTaskState {
  InspectionTaskDeleteSuccess();
  @override
  List<Object> get props => [];
}
