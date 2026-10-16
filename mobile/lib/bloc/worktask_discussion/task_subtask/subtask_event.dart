import 'package:equatable/equatable.dart';

abstract class WorkMilestoneEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MileStoneList extends WorkMilestoneEvent {
  final int? id;

  final String? fromDate;
  final String? dateBetweenFrom;
  final String? dateBetweenTo;
  final String? startDateFrom;
  final String? startDateTo;
  final String? endDateFrom;
  final String? endDateTo;
  final String? searchQuery;
  final String? status;

  MileStoneList(
      {this.id,
      this.searchQuery,
      this.dateBetweenFrom,
      this.dateBetweenTo,
      this.endDateTo,
      this.endDateFrom,
      this.startDateTo,
      this.startDateFrom,
      this.fromDate,
      this.status});

  @override
  List<Object?> get props => [
        id,
        searchQuery,
        dateBetweenTo,
        dateBetweenTo,
        dateBetweenTo,
        dateBetweenFrom,
        startDateTo,
        startDateFrom,
        endDateTo,
        endDateFrom
      ];
}

class SearchWorkMilestone extends WorkMilestoneEvent {
  final int? id;
  final String? fromDate;
  final String? dateBetweenFrom;
  final String? dateBetweenTo;
  final String? startDateFrom;
  final String? startDateTo;
  final String? endDateFrom;
  final String? endDateTo;
  final String? searchQuery;

  SearchWorkMilestone(
      this.id,
      this.searchQuery,
      this.dateBetweenFrom,
      this.dateBetweenTo,
      this.endDateTo,
      this.endDateFrom,
      this.startDateTo,
      this.startDateFrom,
      this.fromDate);

  @override
  List<Object?> get props => [
        id,
        searchQuery,
        dateBetweenTo,
        dateBetweenTo,
        dateBetweenTo,
        dateBetweenFrom,
        startDateTo,
        startDateFrom,
        endDateTo,
        endDateFrom
      ];
}

class WorkMilestoneLoadMore extends WorkMilestoneEvent {
  final int? id;
  final String? searchQuery;
  final String? fromDate;
  final String? dateBetweenFrom;
  final String? dateBetweenTo;
  final String? startDateFrom;
  final String? startDateTo;
  final String? endDateFrom;
  final String? endDateTo;

  WorkMilestoneLoadMore(
      this.id,
      this.searchQuery,
      this.fromDate,
      this.dateBetweenFrom,
      this.dateBetweenTo,
      this.startDateFrom,
      this.startDateTo,
      this.endDateFrom,
      this.endDateTo);

  @override
  List<Object?> get props => [
        searchQuery,
        fromDate,
        dateBetweenTo,
        dateBetweenFrom,
        startDateTo,
        startDateFrom,
        endDateTo,
        endDateFrom
      ];
}

class UpdateMilestoneWork extends WorkMilestoneEvent {
  final int id;
  final String title;
  final String status;

  final String startDate;
  final String endDate;
  final String desc;
  final String cost;
  final int? progress;

  UpdateMilestoneWork({
    required this.id,
    required this.title,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.desc,
    this.progress,
    required this.cost,
  });
  @override
  List<Object> get props => [id, title, status, startDate, endDate, desc, cost];
}

class WorkMilestoneCreated extends WorkMilestoneEvent {
  final int projId;
  final String title;
  final String status;

  final String startDate;
  final String endDate;
  final String desc;
  final String cost;

  WorkMilestoneCreated({
    required this.title,
    required this.status,
    required this.projId,
    required this.startDate,
    required this.endDate,
    required this.desc,
    required this.cost,
  });
  @override
  List<Object> get props =>
      [title, status, projId, startDate, endDate, desc, cost];
}

class DeleteWorkMilestone extends WorkMilestoneEvent {
  final int projectMilestoneId;

  DeleteWorkMilestone(this.projectMilestoneId);

  @override
  List<Object?> get props => [projectMilestoneId];
}
