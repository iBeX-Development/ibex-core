import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/worktask_filter/task_filter_event.dart';

import 'package:ibex/bloc/worktask_filter/task_filter_state.dart';

class WorkTaskFilterCountBloc
    extends Bloc<WorkTaskFilterCountEvent, WorkTaskFilterCountState> {
  WorkTaskFilterCountBloc() : super(WorkTaskFilterCountState.initial()) {
    on<UpdateFilterCount>(_onUpdateFilterCount);
    on<WorkTaskResetFilterCount>(_onResetFilterCount);
  }

  void _onUpdateFilterCount(
    UpdateFilterCount event,
    Emitter<WorkTaskFilterCountState> emit,
  ) {
    final updatedFilters = Map<String, bool>.from(state.activeFilters);
    updatedFilters[event.filterType.toLowerCase()] = event.isSelected;

    // Count how many filter types are active
    final newCount = updatedFilters.values.where((isActive) => isActive).length;

    emit(state.copyWith(activeFilters: updatedFilters, count: newCount));
  }

  void _onResetFilterCount(
    WorkTaskResetFilterCount event,
    Emitter<WorkTaskFilterCountState> emit,
  ) {
    // Create a new map with all filters set to false
    final resetFilters = {
      'clients': false,
      'users': false,
      'status': false,
      'priorities': false,
      'projects': false,
      'date': false,
    };

    emit(WorkTaskFilterCountState(activeFilters: resetFilters, count: 0));
  }
}
