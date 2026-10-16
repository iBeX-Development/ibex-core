import 'package:equatable/equatable.dart';
import 'package:ibex/data/model/Work/all_work.dart';

abstract class WorkState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkInitial extends WorkState {}

class WorkMindMapSuccess extends WorkState {
  final Map<String, dynamic> mindmap;
  WorkMindMapSuccess(this.mindmap);
  @override
  List<Object> get props => [mindmap];
}

class WorkWithId extends WorkState {
  final List<WorkModel> work;

  WorkWithId(this.work);
  @override
  List<Object> get props => [work];
}

class WorkLoading extends WorkState {}

class WorkMapLoading extends WorkState {}

class WorkSuccess extends WorkState {
  WorkSuccess(
    this.work,
    this.selectedIndex,
    this.selectedTitle,
    this.isLoadingMore,
  );
  final List<WorkModel> work;
  final int? selectedIndex;
  final String selectedTitle;
  final bool isLoadingMore;

  @override
  List<Object> get props => [
        work,
        selectedIndex!,
        selectedTitle,
        isLoadingMore,
      ];
}

class WorkPaginated extends WorkState {
  final List<WorkModel> work;
  final bool hasReachedMax;
  final int? totalCount;

  WorkPaginated(
      {required this.work, required this.hasReachedMax, this.totalCount});

  @override
  List<Object?> get props => [work, hasReachedMax, totalCount];
}

class WorkFavPaginated extends WorkState {
  final List<WorkModel> work;
  final bool hasReachedMax;

  WorkFavPaginated({required this.work, required this.hasReachedMax});

  @override
  List<Object> get props => [work, hasReachedMax];
}

class WorkError extends WorkState {
  final String errorMessage;
  WorkError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkCreateLoading extends WorkState {}

class WorkCreateSuccess extends WorkState {
  final WorkModel? createdWork; // ✅ Add created work data
  final int? createdWorkId; // ✅ Add created work ID

  WorkCreateSuccess({
    this.createdWork,
    this.createdWorkId,
  });

  @override
  List<Object?> get props => [createdWork, createdWorkId];
}

class WorkEditLoading extends WorkState {}

class WorkEditSuccess extends WorkState {
  final List<WorkModel> editWork;
  WorkEditSuccess(this.editWork);
  @override
  List<Object> get props => [editWork];
}

class WorkCreateError extends WorkState {
  final String errorMessage;
  WorkCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkEditError extends WorkState {
  final String errorMessage;
  WorkEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkDeleteSuccess extends WorkState {
  WorkDeleteSuccess();
  @override
  List<Object> get props => [];
}

class WorkDeleteError extends WorkState {
  final String errorMessage;
  WorkDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
