import 'package:equatable/equatable.dart';

abstract class InspectionPartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionPartList extends InspectionPartEvent {
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

  InspectionPartList(
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

class SearchInspectionPart extends InspectionPartEvent {
  final int? id;
  final String? fromDate;
  final String? dateBetweenFrom;
  final String? dateBetweenTo;
  final String? startDateFrom;
  final String? startDateTo;
  final String? endDateFrom;
  final String? endDateTo;
  final String? searchQuery;

  SearchInspectionPart(
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

class InspectionPartLoadMore extends InspectionPartEvent {
  final int? id;
  final String? searchQuery;
  final String? fromDate;
  final String? dateBetweenFrom;
  final String? dateBetweenTo;
  final String? startDateFrom;
  final String? startDateTo;
  final String? endDateFrom;
  final String? endDateTo;

  InspectionPartLoadMore(
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

class UpdatePartInspection extends InspectionPartEvent {
  final int id;
  final int workId;
  final String title;
  final String status;

  final String startDate;
  final String endDate;
  final String desc;
  final String cost;
  final int? progress;

  UpdatePartInspection({
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

class InspectionPartCreated extends InspectionPartEvent {
  final int projId;
  final String title;
  final String status;

  final String startDate;
  final String endDate;
  final String desc;
  final String cost;

  InspectionPartCreated({
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

class DeleteInspectionPart extends InspectionPartEvent {
  final int workPartId;

  DeleteInspectionPart(this.workPartId);

  @override
  List<Object?> get props => [workPartId];
}
