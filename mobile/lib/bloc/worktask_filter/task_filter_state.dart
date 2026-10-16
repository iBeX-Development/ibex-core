class WorkTaskFilterCountState {
  final int count;
  final Map<String, bool> activeFilters;

  WorkTaskFilterCountState({
    required this.count,
    required this.activeFilters,
  });

  factory WorkTaskFilterCountState.initial() {
    return WorkTaskFilterCountState(
      count: 0,
      activeFilters: {
        'clients': false,
        'users': false,
        'status': false,
        'priorities': false,
        'projects': false,
        'date': false,
      },
    );
  }

  WorkTaskFilterCountState copyWith({
    int? count,
    Map<String, bool>? activeFilters,
  }) {
    return WorkTaskFilterCountState(
      count: count ?? this.count,
      activeFilters: activeFilters ?? this.activeFilters,
    );
  }
}
