class FilterCountStateOfPart {
  final int count;
  final Map<String, bool> activeFilters;

  FilterCountStateOfPart({
    required this.count,
    required this.activeFilters,
  });

  factory FilterCountStateOfPart.initial() {
    return FilterCountStateOfPart(
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

  FilterCountStateOfPart copyWith({
    int? count,
    Map<String, bool>? activeFilters,
  }) {
    return FilterCountStateOfPart(
      count: count ?? this.count,
      activeFilters: activeFilters ?? this.activeFilters,
    );
  }
}
