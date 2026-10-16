import 'package:equatable/equatable.dart';
import '../../data/model/Inspection/inspection.dart';

abstract class InspectionMultiState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionMultiInitial extends InspectionMultiState {}

class InspectionMultiLoading extends InspectionMultiState {}

class InspectionMultiSuccess extends InspectionMultiState {
  final List<InspectionModel> workMulti;
  final List<int> selectedIndices;
  final List<String> selectedInspectionMultinames;
  final bool isLoadingMore;

  InspectionMultiSuccess({
    required this.workMulti,
    this.selectedIndices = const [],
    this.selectedInspectionMultinames = const [],
    this.isLoadingMore = false,
  });
}

class InspectionMultiPaginated extends InspectionMultiState {
  final List<InspectionModel> workMulti;
  final bool hasReachedMax;

  InspectionMultiPaginated({
    required this.workMulti,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [workMulti, hasReachedMax];
}

class InspectionMultiSuccessCreate extends InspectionMultiState {
  InspectionMultiSuccessCreate();

  @override
  List<Object> get props => [];
}

class InspectionMultiError extends InspectionMultiState {
  final String errorMessage;
  InspectionMultiError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionMultiCreateError extends InspectionMultiState {
  final String errorMessage;

  InspectionMultiCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionMultiEditError extends InspectionMultiState {
  final String errorMessage;

  InspectionMultiEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionMultiEditSuccess extends InspectionMultiState {
  InspectionMultiEditSuccess();
  @override
  List<Object> get props => [];
}

class InspectionMultiCreateSuccess extends InspectionMultiState {
  InspectionMultiCreateSuccess();
  @override
  List<Object> get props => [];
}

class InspectionMultiDeleteError extends InspectionMultiState {
  final String errorMessage;

  InspectionMultiDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionMultiDeleteSuccess extends InspectionMultiState {
  InspectionMultiDeleteSuccess();
  @override
  List<Object> get props => [];
}
