abstract class FilterCountOfMilestoneEvent {}

class WorkUpdateFilterCountOfMileStone extends FilterCountOfMilestoneEvent {
  final String filterType;
  final bool isSelected;

  WorkUpdateFilterCountOfMileStone(
      {required this.filterType, required this.isSelected});
}

class WorkResetFilterCountOfMilestone extends FilterCountOfMilestoneEvent {}

// filter_count_state.dart
