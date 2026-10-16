abstract class FilterCountEvent {}

class WorkUpdateFilterCount extends FilterCountEvent {
  final String filterType;
  final bool isSelected;

  WorkUpdateFilterCount({required this.filterType, required this.isSelected});
}

class WorkResetFilterCount extends FilterCountEvent {}

// filter_count_state.dart
