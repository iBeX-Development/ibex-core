import 'package:equatable/equatable.dart';

abstract class WorkPartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkPartList extends WorkPartEvent {
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

  WorkPartList(
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

class SearchWorkPart extends WorkPartEvent {
  final int? id;
  final String? fromDate;
  final String? dateBetweenFrom;
  final String? dateBetweenTo;
  final String? startDateFrom;
  final String? startDateTo;
  final String? endDateFrom;
  final String? endDateTo;
  final String? searchQuery;

  SearchWorkPart(
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

class WorkPartLoadMore extends WorkPartEvent {
  final int? id;
  final String? searchQuery;
  final String? fromDate;
  final String? dateBetweenFrom;
  final String? dateBetweenTo;
  final String? startDateFrom;
  final String? startDateTo;
  final String? endDateFrom;
  final String? endDateTo;

  WorkPartLoadMore(
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

class UpdatePartWork extends WorkPartEvent {
  final int id;
  final int workId;
  final String title;
  final String status;

  final String startDate;
  final String endDate;
  final String desc;
  final String cost;
  final int? progress;

  UpdatePartWork({
    required this.id,
    required this.workId,
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

class WorkPartCreated extends WorkPartEvent {
  final int projId;
  final String title;
  final String status;

  final String startDate;
  final String endDate;
  final String desc;
  final String cost;

  WorkPartCreated({
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

class DeleteWorkPart extends WorkPartEvent {
  final int workPartId;

  DeleteWorkPart(this.workPartId);

  @override
  List<Object?> get props => [workPartId];
}
