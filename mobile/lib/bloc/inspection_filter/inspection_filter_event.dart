abstract class FilterCountEvent {}

class InspectionUpdateFilterCount extends FilterCountEvent {
  final String filterType;
  final bool isSelected;

  InspectionUpdateFilterCount(
      {required this.filterType, required this.isSelected});
}

class InspectionResetFilterCount extends FilterCountEvent {}

// filter_count_state.dart
