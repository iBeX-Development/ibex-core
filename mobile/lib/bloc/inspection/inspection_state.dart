import 'package:equatable/equatable.dart';
import 'package:ibex/data/model/inspection/inspection.dart';

abstract class InspectionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionInitial extends InspectionState {}

class InspectionMindMapSuccess extends InspectionState {
  final Map<String, dynamic> mindmap;
  InspectionMindMapSuccess(this.mindmap);
  @override
  List<Object> get props => [mindmap];
}

class InspectionWithId extends InspectionState {
  final List<InspectionModel> work;

  InspectionWithId(this.work);
  @override
  List<Object> get props => [work];
}

class InspectionLoading extends InspectionState {}

class InspectionMapLoading extends InspectionState {}

class InspectionSuccess extends InspectionState {
  InspectionSuccess(
    this.work,
    this.selectedIndex,
    this.selectedTitle,
    this.isLoadingMore,
  );
  final List<InspectionModel> work;
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

class InspectionPaginated extends InspectionState {
  final List<InspectionModel> work;
  final bool hasReachedMax;
  final int? totalCount;

  InspectionPaginated(
      {required this.work, required this.hasReachedMax, this.totalCount});

  @override
  List<Object?> get props => [work, hasReachedMax, totalCount];
}

class InspectionFavPaginated extends InspectionState {
  final List<InspectionModel> work;
  final bool hasReachedMax;

  InspectionFavPaginated({required this.work, required this.hasReachedMax});

  @override
  List<Object> get props => [work, hasReachedMax];
}

class InspectionError extends InspectionState {
  final String errorMessage;
  InspectionError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionCreateLoading extends InspectionState {}

class InspectionCreateSuccess extends InspectionState {
  final InspectionModel? createdInspection; // ✅ Add created work data
  final int? createdInspectionId; // ✅ Add created work ID

  InspectionCreateSuccess({
    this.createdInspection,
    this.createdInspectionId,
  });

  @override
  List<Object?> get props => [createdInspection, createdInspectionId];
}

class InspectionEditLoading extends InspectionState {}

class InspectionEditSuccess extends InspectionState {
  final List<InspectionModel> editInspection;
  InspectionEditSuccess(this.editInspection);
  @override
  List<Object> get props => [editInspection];
}

class InspectionCreateError extends InspectionState {
  final String errorMessage;
  InspectionCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionEditError extends InspectionState {
  final String errorMessage;
  InspectionEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionDeleteSuccess extends InspectionState {
  InspectionDeleteSuccess();
  @override
  List<Object> get props => [];
}

class InspectionDeleteError extends InspectionState {
  final String errorMessage;
  InspectionDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
