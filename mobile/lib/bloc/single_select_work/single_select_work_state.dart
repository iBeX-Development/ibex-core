import 'package:equatable/equatable.dart';

import '../../data/model/Work/all_work.dart';

abstract class SingleSelectWorkState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SingleWorkInitial extends SingleSelectWorkState {}

class SingleWorkLoading extends SingleSelectWorkState {}

class SingleWorkSuccess extends SingleSelectWorkState {
  SingleWorkSuccess(
      this.work, this.selectedIndex, this.selectedTitle, this.hasReachedMax);
  final List<WorkModel> work;
  final int? selectedIndex;
  final String selectedTitle;
  final bool hasReachedMax;
  @override
  List<Object> get props =>
      [work, selectedIndex!, selectedTitle, hasReachedMax];
}

class SingleWorkError extends SingleSelectWorkState {
  final String errorMessage;
  SingleWorkError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
