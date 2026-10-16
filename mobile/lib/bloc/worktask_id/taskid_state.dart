import 'package:equatable/equatable.dart';
import '../../data/model/worktask/task_model.dart';

abstract class WorkTaskidState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkTaskidInitial extends WorkTaskidState {}

class WorkTaskidLoading extends WorkTaskidState {}

class WorkTaskidWithId extends WorkTaskidState {
  final List<WorkTasks> task;

  WorkTaskidWithId(
    this.task,
  );
  @override
  List<Object> get props => [task];
}
