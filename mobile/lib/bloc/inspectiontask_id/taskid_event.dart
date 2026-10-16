import 'package:equatable/equatable.dart';

abstract class InspectionTaskidEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionTaskIdListId extends InspectionTaskidEvent {
  final int? id;

  InspectionTaskIdListId(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateTaskCompletion extends InspectionTaskidEvent {
  final int taskId;
  final String value;

  UpdateTaskCompletion({
    required this.taskId,
    required this.value,
  });

  @override
  List<Object?> get props => [taskId, value];
}
