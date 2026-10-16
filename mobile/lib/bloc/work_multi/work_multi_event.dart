import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../data/model/Work/all_work.dart';

abstract class WorkMultiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkMultiList extends WorkMultiEvent {
  WorkMultiList();
  @override
  List<Object> get props => [];
}

class WorkMultiLoadMore extends WorkMultiEvent {
  WorkMultiLoadMore();

  @override
  List<Object?> get props => [];
}

class SelectedWorkMulti extends WorkMultiEvent {
  final int selectedIndex;
  final String selectedTitle;

  SelectedWorkMulti(this.selectedIndex, this.selectedTitle);
  @override
  List<Object> get props => [selectedIndex, selectedTitle];
}

class ToggleWorkMultiSelection extends WorkMultiEvent {
  final int workMultiId;
  final String workMultiName;

  ToggleWorkMultiSelection(this.workMultiId, this.workMultiName);
}

class WorkMultisCreated extends WorkMultiEvent {
  final WorkModel workMultiList;

  final File? image;
  final String? profileImage;
  // final WorkMulti WorkMulti;

  WorkMultisCreated(this.workMultiList, this.image, this.profileImage);
  @override
  List<Object> get props => [workMultiList];
}

class AllWorkMultisList extends WorkMultiEvent {
  AllWorkMultisList();

  @override
  List<Object> get props => [];
}

class UpdateWorkMultis extends WorkMultiEvent {
  final WorkModel workMulti;

  UpdateWorkMultis(this.workMulti);
  @override
  List<Object> get props => [workMulti];
}

class DeleteWorkMultis extends WorkMultiEvent {
  final int workMultiId;

  DeleteWorkMultis(this.workMultiId);

  @override
  List<Object?> get props => [workMultiId];
}

class SearchWorkMultis extends WorkMultiEvent {
  final String searchQuery;

  SearchWorkMultis(this.searchQuery);

  @override
  List<Object?> get props => [searchQuery];
}
