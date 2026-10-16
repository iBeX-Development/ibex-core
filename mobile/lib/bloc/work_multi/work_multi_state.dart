import 'package:equatable/equatable.dart';
import '../../data/model/Work/all_work.dart';

abstract class WorkMultiState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkMultiInitial extends WorkMultiState {}

class WorkMultiLoading extends WorkMultiState {}

class WorkMultiSuccess extends WorkMultiState {
  final List<WorkModel> workMulti;
  final List<int> selectedIndices;
  final List<String> selectedWorkMultinames;
  final bool isLoadingMore;

  WorkMultiSuccess({
    required this.workMulti,
    this.selectedIndices = const [],
    this.selectedWorkMultinames = const [],
    this.isLoadingMore = false,
  });
}

class WorkMultiPaginated extends WorkMultiState {
  final List<WorkModel> workMulti;
  final bool hasReachedMax;

  WorkMultiPaginated({
    required this.workMulti,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [workMulti, hasReachedMax];
}

class WorkMultiSuccessCreate extends WorkMultiState {
  WorkMultiSuccessCreate();

  @override
  List<Object> get props => [];
}

class WorkMultiError extends WorkMultiState {
  final String errorMessage;
  WorkMultiError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkMultiCreateError extends WorkMultiState {
  final String errorMessage;

  WorkMultiCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkMultiEditError extends WorkMultiState {
  final String errorMessage;

  WorkMultiEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkMultiEditSuccess extends WorkMultiState {
  WorkMultiEditSuccess();
  @override
  List<Object> get props => [];
}

class WorkMultiCreateSuccess extends WorkMultiState {
  WorkMultiCreateSuccess();
  @override
  List<Object> get props => [];
}

class WorkMultiDeleteError extends WorkMultiState {
  final String errorMessage;

  WorkMultiDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkMultiDeleteSuccess extends WorkMultiState {
  WorkMultiDeleteSuccess();
  @override
  List<Object> get props => [];
}
