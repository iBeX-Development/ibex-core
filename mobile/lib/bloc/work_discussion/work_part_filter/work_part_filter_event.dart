abstract class FilterCountOfPartEvent {}

class WorkUpdateFilterCountOfPart extends FilterCountOfPartEvent {
  final String filterType;
  final bool isSelected;

  WorkUpdateFilterCountOfPart(
      {required this.filterType, required this.isSelected});
}

class WorkResetFilterCountOfPart extends FilterCountOfPartEvent {}

// filter_count_state.dart
