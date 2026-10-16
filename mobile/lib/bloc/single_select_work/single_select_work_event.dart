import 'package:equatable/equatable.dart';

abstract class SingleSelectWorkEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchSingleWork extends SingleSelectWorkEvent {
  final String searchQuery;

  SearchSingleWork(this.searchQuery);
  @override
  List<Object> get props => [searchQuery];
}

class SingleWorkList extends SingleSelectWorkEvent {
  SingleWorkList();
  @override
  List<Object> get props => [];
}

class SingleWorkLoadMore extends SingleSelectWorkEvent {
  final String searchQuery;

  SingleWorkLoadMore(this.searchQuery);

  @override
  List<Object?> get props => [searchQuery];
}

class SelectSingleWork extends SingleSelectWorkEvent {
  final int selectedIndex;
  final String selectedTitle;

  SelectSingleWork(this.selectedIndex, this.selectedTitle);
  @override
  List<Object> get props => [selectedIndex, selectedTitle];
}
