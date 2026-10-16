import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/inspectiontask_filter/task_filter_event.dart';

import 'package:ibex/bloc/inspectiontask_filter/task_filter_state.dart';

class InspectionTaskFilterCountBloc extends Bloc<InspectionTaskFilterCountEvent,
    InspectionTaskFilterCountState> {
  InspectionTaskFilterCountBloc()
      : super(InspectionTaskFilterCountState.initial()) {
    on<UpdateFilterCount>(_onUpdateFilterCount);
    on<InspectionTaskResetFilterCount>(_onResetFilterCount);
  }

  void _onUpdateFilterCount(
    UpdateFilterCount event,
    Emitter<InspectionTaskFilterCountState> emit,
  ) {
    final updatedFilters = Map<String, bool>.from(state.activeFilters);
    updatedFilters[event.filterType.toLowerCase()] = event.isSelected;

    // Count how many filter types are active
    final newCount = updatedFilters.values.where((isActive) => isActive).length;

    emit(state.copyWith(activeFilters: updatedFilters, count: newCount));
  }

  void _onResetFilterCount(
    InspectionTaskResetFilterCount event,
    Emitter<InspectionTaskFilterCountState> emit,
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

    emit(InspectionTaskFilterCountState(activeFilters: resetFilters, count: 0));
  }
}
