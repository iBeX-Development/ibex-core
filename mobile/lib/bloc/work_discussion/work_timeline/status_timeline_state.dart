part of 'status_timeline_bloc.dart';

abstract class StatusTimelineState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class StatusTimelineInitial extends StatusTimelineState {}

class WorkStatusTimelineLoading extends StatusTimelineState {}

class WorkStatusTimelineSuccess extends StatusTimelineState {}

class WorkStatusTimelinePaginated extends StatusTimelineState {
  final List<StatusTimelineModel> WorkTimeline;
  final bool hasReachedMax;

  WorkStatusTimelinePaginated({
    required this.WorkTimeline,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [WorkTimeline, hasReachedMax];
}

class WorkStatusTimelineError extends StatusTimelineState {
  final String errorMessage;
  WorkStatusTimelineError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkStatusTimelineDeleteSuccess extends StatusTimelineState {
  WorkStatusTimelineDeleteSuccess();
  @override
  List<Object> get props => [];
}
