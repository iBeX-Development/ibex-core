part of 'status_timeline_bloc.dart';

abstract class StatusTimelineState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class StatusTimelineInitial extends StatusTimelineState {}

class InspectionStatusTimelineLoading extends StatusTimelineState {}

class InspectionStatusTimelineSuccess extends StatusTimelineState {}

class InspectionStatusTimelinePaginated extends StatusTimelineState {
  final List<StatusTimelineModel> InspectionTimeline;
  final bool hasReachedMax;

  InspectionStatusTimelinePaginated({
    required this.InspectionTimeline,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [InspectionTimeline, hasReachedMax];
}

class InspectionStatusTimelineError extends StatusTimelineState {
  final String errorMessage;
  InspectionStatusTimelineError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionStatusTimelineDeleteSuccess extends StatusTimelineState {
  InspectionStatusTimelineDeleteSuccess();
  @override
  List<Object> get props => [];
}
