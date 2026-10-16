import 'package:equatable/equatable.dart';

abstract class WorkTradeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkTradeList extends WorkTradeEvent {
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

  WorkTradeList(
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

class SearchWorkTrade extends WorkTradeEvent {
  final int? id;
  final String? fromDate;
  final String? dateBetweenFrom;
  final String? dateBetweenTo;
  final String? startDateFrom;
  final String? startDateTo;
  final String? endDateFrom;
  final String? endDateTo;
  final String? searchQuery;

  SearchWorkTrade(
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

class WorkTradeLoadMore extends WorkTradeEvent {
  final int? id;
  final String? searchQuery;
  final String? fromDate;
  final String? dateBetweenFrom;
  final String? dateBetweenTo;
  final String? startDateFrom;
  final String? startDateTo;
  final String? endDateFrom;
  final String? endDateTo;

  WorkTradeLoadMore(
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

class UpdateTradeWork extends WorkTradeEvent {
  final int id;
  final int workId;
  final String title;
  final String status;

  final String startDate;
  final String endDate;
  final String desc;
  final String cost;
  final int? progress;

  UpdateTradeWork({
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

class WorkTradeCreated extends WorkTradeEvent {
  final int projId;
  final String title;
  final String status;

  final String startDate;
  final String endDate;
  final String desc;
  final String cost;

  WorkTradeCreated({
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

class DeleteWorkTrade extends WorkTradeEvent {
  final int workTradeId;

  DeleteWorkTrade(this.workTradeId);

  @override
  List<Object?> get props => [workTradeId];
}
