import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/inspection_filter/inspection_filter_event.dart';
import 'package:ibex/bloc/inspection_filter/inspection_filter_state.dart';

class InspectionFilterCountBloc
    extends Bloc<FilterCountEvent, FilterCountState> {
  InspectionFilterCountBloc() : super(FilterCountState.initial()) {
    on<InspectionUpdateFilterCount>(_onUpdateFilterCount);
    on<InspectionResetFilterCount>(_onResetFilterCount);
  }

  void _onUpdateFilterCount(
    InspectionUpdateFilterCount event,
    Emitter<FilterCountState> emit,
  ) {
    final updatedFilters = Map<String, bool>.from(state.activeFilters);
    updatedFilters[event.filterType.toLowerCase()] = event.isSelected;

    // Count how many filter types are active
    final newCount = updatedFilters.values.where((isActive) => isActive).length;

    emit(state.copyWith(activeFilters: updatedFilters, count: newCount));
  }

  void _onResetFilterCount(
    InspectionResetFilterCount event,
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
