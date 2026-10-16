part of 'status_timeline_bloc.dart';

abstract class StatusTimelineEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StatusTimelineList extends StatusTimelineEvent {
  final int? id;

  StatusTimelineList({
    this.id,
  });

  @override
  List<Object?> get props => [id];
}

class DeleteWorkMedia extends StatusTimelineEvent {
  final int? id;

  DeleteWorkMedia({
    this.id,
  });

  @override
  List<Object?> get props => [id];
}
