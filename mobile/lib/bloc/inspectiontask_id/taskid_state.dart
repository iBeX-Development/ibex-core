import 'package:equatable/equatable.dart';
import '../../data/model/inspectiontask/task_model.dart';

abstract class InspectionTaskidState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionTaskidInitial extends InspectionTaskidState {}

class InspectionTaskidLoading extends InspectionTaskidState {}

class InspectionTaskidWithId extends InspectionTaskidState {
  final List<InspectionTasks> task;

  InspectionTaskidWithId(
    this.task,
  );
  @override
  List<Object> get props => [task];
}
