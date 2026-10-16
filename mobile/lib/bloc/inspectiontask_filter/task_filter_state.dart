class InspectionTaskFilterCountState {
  final int count;
  final Map<String, bool> activeFilters;

  InspectionTaskFilterCountState({
    required this.count,
    required this.activeFilters,
  });

  factory InspectionTaskFilterCountState.initial() {
    return InspectionTaskFilterCountState(
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

  InspectionTaskFilterCountState copyWith({
    int? count,
    Map<String, bool>? activeFilters,
  }) {
    return InspectionTaskFilterCountState(
      count: count ?? this.count,
      activeFilters: activeFilters ?? this.activeFilters,
    );
  }
}
