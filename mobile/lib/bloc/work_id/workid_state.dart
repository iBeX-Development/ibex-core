import 'package:equatable/equatable.dart';

import '../../data/model/Work/all_work.dart';

abstract class WorkidState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkidInitial extends WorkidState {}

class WorkidLoading extends WorkidState {}

class WorkidWithId extends WorkidState {
  final List<WorkModel> work;

  WorkidWithId(
    this.work,
  );
  @override
  List<Object> get props => [work];
}
