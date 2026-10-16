class WorkProjectUpdateFilterCountOfMileStone {
  final int count;
  final Map<String, bool> activeFilters;

  WorkProjectUpdateFilterCountOfMileStone({
    required this.count,
    required this.activeFilters,
  });

  factory WorkProjectUpdateFilterCountOfMileStone.initial() {
    return WorkProjectUpdateFilterCountOfMileStone(
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

  WorkProjectUpdateFilterCountOfMileStone copyWith({
    int? count,
    Map<String, bool>? activeFilters,
  }) {
    return WorkProjectUpdateFilterCountOfMileStone(
      count: count ?? this.count,
      activeFilters: activeFilters ?? this.activeFilters,
    );
  }
}
