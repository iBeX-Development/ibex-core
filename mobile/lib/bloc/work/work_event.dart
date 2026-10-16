import 'package:equatable/equatable.dart';

abstract class WorkEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkList extends WorkEvent {
  final int? userId;
  final int? clientId;
  final int? priorityId;
  final int? statusId;
  final int? tagId;
  WorkList(
      {this.tagId, this.clientId, this.userId, this.statusId, this.priorityId});

  @override
  List<Object?> get props => [tagId, clientId, userId, statusId, priorityId];
}

class WorkDashBoardFavList extends WorkEvent {
  final int? isFav;
  WorkDashBoardFavList({this.isFav});

  @override
  List<Object?> get props => [isFav];
}

class WorkMindMap extends WorkEvent {
  final int? id;
  WorkMindMap({this.id});

  @override
  List<Object?> get props => [id];
}

class WorkDashBoardList extends WorkEvent {
  final List<int>? userId;
  final int? id;
  final int? isFav;
  final int? active;
  final int? location;
  final int? assetId;
  final List<int>? clientId;
  final List<int>? priorityId;
  final List<int>? statusId;
  final List<int>? tagId;
  final String? fromDate;
  final String? toDate;
  final String? createType;
  final String? workType;
  final List<int>? woStatus;
  final List<int>? teamIds;
  final Map<String, dynamic>? actionStatus; // ✅ Add action_status filter
  final List<int>? workOrderIds; // ✅ Filter by work order IDs

  WorkDashBoardList(
      {this.tagId,
      this.id,
      this.isFav,
      this.clientId,
      this.active,
      this.location,
      this.createType,
      this.workType,
      this.woStatus,
      this.teamIds,
      this.userId,
      this.statusId,
      this.priorityId,
      this.fromDate,
      this.assetId,
      this.actionStatus, // ✅ Add to constructor
      this.workOrderIds, // ✅ Add to constructor
      this.toDate});

  @override
  List<Object?> get props => [
        tagId,
        id,
        clientId,
        isFav,
        active,
        location,
        woStatus,
        workType,
        createType,
        teamIds,
        userId,
        statusId,
        priorityId,
        fromDate,
        assetId,
        actionStatus,
        workOrderIds,
        toDate
      ];
}

// class MileStoneList extends WorkEvent {
//   final int? id;
//   final String? fromDate;
//   final String? dateBetweenFrom;
//   final String? dateBetweenTo;
//   final String? startDateFrom;
//   final String? startDateTo;
//   final String? endDateFrom;
//   final String? endDateTo;
//
//
//
//   MileStoneList({this.id,this.fromDate,this.dateBetweenFrom,this.dateBetweenTo,this.endDateFrom,this.endDateTo,this.startDateFrom,this.startDateTo});
//
//   @override
//   List<Object?> get props => [id,fromDate,dateBetweenFrom,dateBetweenTo,startDateFrom,startDateTo,endDateFrom,endDateTo];
// }
class SearchWork extends WorkEvent {
  final List<int>? clientId;
  final List<int>? userId;
  final String? searchQuery;

  SearchWork(this.searchQuery, this.clientId, this.userId);

  @override
  List<Object?> get props => [searchQuery, userId, clientId];
}

class WorkId extends WorkEvent {
  final int? id;

  WorkId(this.id);

  @override
  List<Object?> get props => [id];
}

class WorkLoadMore extends WorkEvent {
  final String? searchQuery;
  final List<int>? clientId;
  final List<int>? userId;

  WorkLoadMore(this.searchQuery, this.clientId, this.userId);

  @override
  List<Object?> get props => [searchQuery, clientId, userId];
}

class SelectedWork extends WorkEvent {
  final int selectedIndex;
  final String selectedTitle;

  SelectedWork(this.selectedIndex, this.selectedTitle);
  @override
  List<Object> get props => [selectedIndex, selectedTitle];
}

class UpdateWork extends WorkEvent {
  final int id;
  final String title;
  final int? statusId;
  final int? priorityId;
  final int? workType;
  final int? actionStatus;
  final String? startDate;
  final String? endDate;
  final String? desc;
  final String? note;
  final String? budget;
  final String? taskAccess;
  final String? userIdString;
  final List<int>? userId;
  final List<int>? locationId;
  final List<int>? clientId;
  final List<int>? assetId;
  final List<int>? tagId;
  final int? clientCanDiscuss;
  final int? enable;
  final Map<String, dynamic>? customFieldValues; // Declare the property
  UpdateWork({
    required this.id,
    required this.title,
    this.statusId,
    this.priorityId,
    this.workType,
    this.actionStatus,
    this.startDate,
    this.endDate,
    this.desc,
    this.taskAccess,
    this.clientCanDiscuss,
    this.note,
    this.budget,
    this.enable,
    this.userId,
    this.userIdString,
    this.locationId,
    this.assetId,
    this.clientId,
    this.customFieldValues, // Add this,
    this.tagId,
  });
  @override
  List<Object?> get props => [
        id,
        title,
        statusId,
        priorityId,
        workType,
        actionStatus,
        startDate,
        endDate,
        desc,
        note,
        taskAccess,
        budget,
        clientId,
        userId,
        userIdString,
        locationId,
        tagId,
        assetId ?? [],
        customFieldValues
      ];
}

class WorkCreated extends WorkEvent {
  final String title;
  final int? statusId;
  final int? priorityId;
  final int? workType;
  final int? actionStatus;
  final String? startDate;
  final String? endDate;
  final String? desc;
  final int? clientCanDiscuss;
  final int? enable;
  final String? note;
  final String? createdType;
  final String? budget;
  final String? taskAccess;
  final String? userIdString;
  final List<int>? userId;
  final List<int>? locationId;
  final List<int>? clientId;
  final List<int>? tagId;
  final List<int>? assetId;
  final Map<String, dynamic>? customFieldValues; // Declare the property

  WorkCreated(
      {required this.title,
      this.enable,
      this.clientCanDiscuss,
      this.statusId,
      this.priorityId,
      this.workType,
      this.actionStatus,
      this.startDate,
      this.endDate,
      this.desc,
      this.taskAccess,
      this.note,
      this.createdType,
      this.assetId,
      this.budget,
      this.userId,
      this.userIdString,
      this.locationId,
      this.clientId,
      this.tagId,
      this.customFieldValues});
  @override
  List<Object?> get props => [
        title,
        statusId,
        priorityId,
        workType,
        actionStatus,
        startDate,
        endDate,
        desc,
        note,
        createdType ?? '',
        taskAccess,
        budget,
        clientId,
        userId,
        userIdString,
        locationId,
        tagId,
        assetId ?? [],
        customFieldValues
      ];
}

class DeleteWork extends WorkEvent {
  final int workId;

  DeleteWork(this.workId);

  @override
  List<Object?> get props => [workId];
}
