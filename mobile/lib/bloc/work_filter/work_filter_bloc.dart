import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/work_filter/work_filter_event.dart';
import 'package:ibex/bloc/work_filter/work_filter_state.dart';

class WorkFilterCountBloc extends Bloc<FilterCountEvent, FilterCountState> {
  WorkFilterCountBloc() : super(FilterCountState.initial()) {
    on<WorkUpdateFilterCount>(_onUpdateFilterCount);
    on<WorkResetFilterCount>(_onResetFilterCount);
  }

  void _onUpdateFilterCount(
    WorkUpdateFilterCount event,
    Emitter<FilterCountState> emit,
  ) {
    final updatedFilters = Map<String, bool>.from(state.activeFilters);
    updatedFilters[event.filterType.toLowerCase()] = event.isSelected;

    // Count how many filter types are active
    final newCount = updatedFilters.values.where((isActive) => isActive).length;

    emit(state.copyWith(activeFilters: updatedFilters, count: newCount));
  }

  void _onResetFilterCount(
    WorkResetFilterCount event,
    Emitter<FilterCountState> emit,
  ) {
    // Create a new map with all filters set to false
    final resetFilters = {
      'clients': false,
      'users': false,
      'status': false,
      'priorities': false,
      'tags': false,
      'date': false,
    };

    emit(FilterCountState(activeFilters: resetFilters, count: 0));
  }
}
