import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/work_discussion/work_trade_filter/work_trade_filter_event.dart';
import 'package:ibex/bloc/work_discussion/work_trade_filter/work_trade_filter_state.dart';

class WorkFilterCountOfTradeBloc
    extends Bloc<FilterCountOfTradeEvent, FilterCountStateOfTrade> {
  WorkFilterCountOfTradeBloc() : super(FilterCountStateOfTrade.initial()) {
    on<WorkUpdateFilterCountOfTrade>(_onUpdateFilterCountOfTrade);
    on<WorkResetFilterCountOfTrade>(_onResetFilterCountOfTrade);
  }

  void _onUpdateFilterCountOfTrade(
    WorkUpdateFilterCountOfTrade event,
    Emitter<FilterCountStateOfTrade> emit,
  ) {
    final updatedFilters = Map<String, bool>.from(state.activeFilters);
    updatedFilters[event.filterType.toLowerCase()] = event.isSelected;

    // Count how many filter types are active
    final newCount = updatedFilters.values.where((isActive) => isActive).length;

    emit(state.copyWith(activeFilters: updatedFilters, count: newCount));
  }

  void _onResetFilterCountOfTrade(
    WorkResetFilterCountOfTrade event,
    Emitter<FilterCountStateOfTrade> emit,
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

    emit(FilterCountStateOfTrade(activeFilters: resetFilters, count: 0));
  }
}
