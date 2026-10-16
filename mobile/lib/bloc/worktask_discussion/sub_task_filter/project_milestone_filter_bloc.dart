import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/work_discussion/work_milestone_filter/work_milestone_filter_event.dart';
import 'package:ibex/bloc/work_discussion/work_milestone_filter/work_milestone_filter_state.dart';

class FilterCountOfMilestoneBloc
    extends Bloc<FilterCountOfMilestoneEvent, FilterCountStateOfMilestone> {
  FilterCountOfMilestoneBloc() : super(FilterCountStateOfMilestone.initial()) {
    on<WorkUpdateFilterCountOfMileStone>(_onUpdateFilterCountOfMilestone);
    on<WorkResetFilterCountOfMilestone>(_onResetFilterCountOfMilestone);
  }

  void _onUpdateFilterCountOfMilestone(
    WorkUpdateFilterCountOfMileStone event,
    Emitter<FilterCountStateOfMilestone> emit,
  ) {
    final updatedFilters = Map<String, bool>.from(state.activeFilters);
    updatedFilters[event.filterType.toLowerCase()] = event.isSelected;

    // Count how many filter types are active
    final newCount = updatedFilters.values.where((isActive) => isActive).length;

    emit(state.copyWith(activeFilters: updatedFilters, count: newCount));
  }

  void _onResetFilterCountOfMilestone(
    WorkResetFilterCountOfMilestone event,
    Emitter<FilterCountStateOfMilestone> emit,
  ) {
    // Create a new map with all filters set to false
    final resetFilters = {
      'dateBetweenStart': false,
      // 'dateBetweenEnd': false,
      'startDateBetweenStart': false,
      // 'startDateBetweenEnd': false,
      'endDateBetweenStart': false,
      // 'endDateBetweenEnd': false,
      'status': false,
    };

    emit(FilterCountStateOfMilestone(activeFilters: resetFilters, count: 0));
  }
}
