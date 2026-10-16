import 'package:equatable/equatable.dart';

import '../../../data/model/work/milestone.dart';

abstract class WorkMilestoneState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkMilestoneInitial extends WorkMilestoneState {}

class WorkMilestoneWithId extends WorkMilestoneState {
  final List<WorksMilestone> WorkMilestone;

  WorkMilestoneWithId(
    this.WorkMilestone,
  );
  @override
  List<Object> get props => [WorkMilestone];
}

class WorkMilestoneLoading extends WorkMilestoneState {}

class WorkMilestoneSuccess extends WorkMilestoneState {
  WorkMilestoneSuccess(this.WorkMilestone, this.selectedIndex,
      this.selectedTitle, this.isLoadingMore);
  final List<WorksMilestone> WorkMilestone;
  final int? selectedIndex;
  final String selectedTitle;
  final bool isLoadingMore;

  @override
  List<Object> get props =>
      [WorkMilestone, selectedIndex!, selectedTitle, isLoadingMore];
}

class WorkMilestonePaginated extends WorkMilestoneState {
  final List<WorksMilestone> WorkMilestone;
  final bool hasReachedMax;

  WorkMilestonePaginated({
    required this.WorkMilestone,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [WorkMilestone, hasReachedMax];
}

class WorkMilestoneMileStonePaginated extends WorkMilestoneState {
  final List<WorksMilestone> WorkMilestoneMilestone;
  final bool hasReachedMax;

  WorkMilestoneMileStonePaginated({
    required this.WorkMilestoneMilestone,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [WorkMilestoneMilestone, hasReachedMax];
}

class WorkMilestoneError extends WorkMilestoneState {
  final String errorMessage;
  WorkMilestoneError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkMilestoneCreateLoading extends WorkMilestoneState {}

class WorkMilestoneCreateSuccess extends WorkMilestoneState {
  final List<WorksMilestone> createWorkMilestone;
  WorkMilestoneCreateSuccess(this.createWorkMilestone);
  @override
  List<Object> get props => [createWorkMilestone];
}

class WorkMilestoneEditLoading extends WorkMilestoneState {}

class WorkMilestoneEditSuccess extends WorkMilestoneState {
  final List<WorksMilestone> editWorkMilestone;
  WorkMilestoneEditSuccess(this.editWorkMilestone);
  @override
  List<Object> get props => [editWorkMilestone];
}

class WorkMilestoneCreateError extends WorkMilestoneState {
  final String errorMessage;
  WorkMilestoneCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkMilestoneEditError extends WorkMilestoneState {
  final String errorMessage;
  WorkMilestoneEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkMilestoneDeleteSuccess extends WorkMilestoneState {
  WorkMilestoneDeleteSuccess();
  @override
  List<Object> get props => [];
}

class WorkMilestoneDeleteError extends WorkMilestoneState {
  final String errorMessage;
  WorkMilestoneDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
