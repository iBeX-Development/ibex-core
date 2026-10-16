class FilterCountStateOfTrade {
  final int count;
  final Map<String, bool> activeFilters;

  FilterCountStateOfTrade({
    required this.count,
    required this.activeFilters,
  });

  factory FilterCountStateOfTrade.initial() {
    return FilterCountStateOfTrade(
      count: 0,
      activeFilters: {
        'statuses': false,
        'users': false,
        'status': false,
        'priorities': false,
        'tags': false,
        'date': false,
      },
    );
  }

  FilterCountStateOfTrade copyWith({
    int? count,
    Map<String, bool>? activeFilters,
  }) {
    return FilterCountStateOfTrade(
      count: count ?? this.count,
      activeFilters: activeFilters ?? this.activeFilters,
    );
  }
}
