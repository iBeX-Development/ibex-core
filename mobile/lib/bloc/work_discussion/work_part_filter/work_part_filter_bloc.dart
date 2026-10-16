import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/work_discussion/work_part_filter/work_part_filter_event.dart';
import 'package:ibex/bloc/work_discussion/work_part_filter/work_part_filter_state.dart';

class WorkFilterCountOfPartBloc
    extends Bloc<FilterCountOfPartEvent, FilterCountStateOfPart> {
  WorkFilterCountOfPartBloc() : super(FilterCountStateOfPart.initial()) {
    on<WorkUpdateFilterCountOfPart>(_onUpdateFilterCountOfPart);
    on<WorkResetFilterCountOfPart>(_onResetFilterCountOfPart);
  }

  void _onUpdateFilterCountOfPart(
    WorkUpdateFilterCountOfPart event,
    Emitter<FilterCountStateOfPart> emit,
  ) {
    final updatedFilters = Map<String, bool>.from(state.activeFilters);
    updatedFilters[event.filterType.toLowerCase()] = event.isSelected;

    // Count how many filter types are active
    final newCount = updatedFilters.values.where((isActive) => isActive).length;

    emit(state.copyWith(activeFilters: updatedFilters, count: newCount));
  }

  void _onResetFilterCountOfPart(
    WorkResetFilterCountOfPart event,
    Emitter<FilterCountStateOfPart> emit,
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

    emit(FilterCountStateOfPart(activeFilters: resetFilters, count: 0));
  }
}
