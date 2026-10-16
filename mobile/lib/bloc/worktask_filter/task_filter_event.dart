abstract class WorkTaskFilterCountEvent {}

class UpdateFilterCount extends WorkTaskFilterCountEvent {
  final String filterType;
  final bool isSelected;

  UpdateFilterCount({required this.filterType, required this.isSelected});
}

class WorkTaskResetFilterCount extends WorkTaskFilterCountEvent {}

// filter_count_state.dart
