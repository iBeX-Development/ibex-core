abstract class FilterCountOfTradeEvent {}

class WorkUpdateFilterCountOfTrade extends FilterCountOfTradeEvent {
  final String filterType;
  final bool isSelected;

  WorkUpdateFilterCountOfTrade(
      {required this.filterType, required this.isSelected});
}

class WorkResetFilterCountOfTrade extends FilterCountOfTradeEvent {}

// filter_count_state.dart
