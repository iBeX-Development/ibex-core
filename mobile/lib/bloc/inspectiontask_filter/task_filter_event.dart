abstract class InspectionTaskFilterCountEvent {}

class UpdateFilterCount extends InspectionTaskFilterCountEvent {
  final String filterType;
  final bool isSelected;

  UpdateFilterCount({required this.filterType, required this.isSelected});
}

class InspectionTaskResetFilterCount extends InspectionTaskFilterCountEvent {}

// filter_count_state.dart
