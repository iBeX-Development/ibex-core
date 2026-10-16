import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../data/model/Inspection/inspection.dart';

abstract class InspectionMultiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionMultiList extends InspectionMultiEvent {
  InspectionMultiList();
  @override
  List<Object> get props => [];
}

class InspectionMultiLoadMore extends InspectionMultiEvent {
  InspectionMultiLoadMore();

  @override
  List<Object?> get props => [];
}

class SelectedInspectionMulti extends InspectionMultiEvent {
  final int selectedIndex;
  final String selectedTitle;

  SelectedInspectionMulti(this.selectedIndex, this.selectedTitle);
  @override
  List<Object> get props => [selectedIndex, selectedTitle];
}

class ToggleInspectionMultiSelection extends InspectionMultiEvent {
  final int workMultiId;
  final String workMultiName;

  ToggleInspectionMultiSelection(this.workMultiId, this.workMultiName);
}

class InspectionMultisCreated extends InspectionMultiEvent {
  final InspectionModel workMultiList;

  final File? image;
  final String? profileImage;
  // final InspectionMulti InspectionMulti;

  InspectionMultisCreated(this.workMultiList, this.image, this.profileImage);
  @override
  List<Object> get props => [workMultiList];
}

class AllInspectionMultisList extends InspectionMultiEvent {
  AllInspectionMultisList();

  @override
  List<Object> get props => [];
}

class UpdateInspectionMultis extends InspectionMultiEvent {
  final InspectionModel workMulti;

  UpdateInspectionMultis(this.workMulti);
  @override
  List<Object> get props => [workMulti];
}

class DeleteInspectionMultis extends InspectionMultiEvent {
  final int workMultiId;

  DeleteInspectionMultis(this.workMultiId);

  @override
  List<Object?> get props => [workMultiId];
}

class SearchInspectionMultis extends InspectionMultiEvent {
  final String searchQuery;

  SearchInspectionMultis(this.searchQuery);

  @override
  List<Object?> get props => [searchQuery];
}
