import 'package:equatable/equatable.dart';

abstract class WorkTaskEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkTaskCreated extends WorkTaskEvent {
  final String title;
  final int statusId;
  final int priorityId;
  final int canClientDiscuss;
  final String billingType;
  final int completionPercentage;
  final String enableReminder;
  final String enableRecurringTask;
  final String startDate;
  final String dueDate;
  final int parentId;
  final bool isSubtask;
  final String desc;
  final int project;
  final String note;
  final List<int> userId;
  final String? frequencyType;
  final String? template_type;
  final String? recurringFrequencyType;

  // Recurrence Fields
  final int? dayOfWeek;
  final int? dayOfMonth;
  final String? timeOfDay;
  final int? recurrenceDayOfWeek;
  final int? recurrenceDayOfMonth;
  final int? recurrenceMonthOfYear;
  final String? recurrenceStartsFrom;
  final int? recurrenceOccurrences;
  final Map<String, dynamic> customFieldValues; // Declare the property

  WorkTaskCreated({
    required this.title,
    required this.statusId,
    required this.canClientDiscuss,
    required this.enableRecurringTask,
    required this.enableReminder,
    required this.billingType,
    required this.completionPercentage,
    required this.priorityId,
    required this.startDate,
    required this.isSubtask,
    required this.parentId,
    required this.dueDate,
    required this.desc,
    required this.project,
    required this.userId,
    required this.customFieldValues,
    required this.note,

    // Recurrence Fields
    this.dayOfWeek,
    this.frequencyType,
    this.template_type,
    this.recurringFrequencyType,
    this.dayOfMonth,
    this.timeOfDay,
    this.recurrenceDayOfWeek,
    this.recurrenceDayOfMonth,
    this.recurrenceMonthOfYear,
    this.recurrenceStartsFrom,
    this.recurrenceOccurrences,
  });

  @override
  List<Object> get props => [
        title,
        statusId,
        priorityId,
        startDate,
        dueDate,
        completionPercentage,
        canClientDiscuss,
        parentId,
        isSubtask,
        customFieldValues,
        billingType,
        enableReminder,
        enableRecurringTask,
        desc,
        project,
        note,
        userId,
      ];
}

class WorkTaskDashBoardFavList extends WorkTaskEvent {
  final int? isFav;
  WorkTaskDashBoardFavList({this.isFav});

  @override
  List<Object?> get props => [isFav];
}

class AllWorkTaskListOnTask extends WorkTaskEvent {
  final List<int>? userId;
  final List<int>? clientId;
  final List<int>? priorityId;
  final List<int>? statusId;
  final List<int>? projectId;
  final String? fromDate;
  final String? toDate;
  final int? id;
  final bool isSubtask;
  AllWorkTaskListOnTask(
      {this.id,
      this.projectId,
      this.clientId,
      this.userId,
      this.statusId,
      this.priorityId,
      this.isSubtask = false,
      this.fromDate,
      this.toDate});

  @override
  List<Object?> get props =>
      [id, projectId, clientId, userId, statusId, priorityId, fromDate, toDate];
}

class AllWorkTaskList extends WorkTaskEvent {
  AllWorkTaskList();

  @override
  List<Object> get props => [];
}

class TodaysWorkTaskList extends WorkTaskEvent {
  final String fromDate;
  final String toDate;
  TodaysWorkTaskList(this.fromDate, this.toDate);

  @override
  List<Object> get props => [fromDate, toDate];
}

class WorkUpdateTask extends WorkTaskEvent {
  final int id;
  final String title;
  final int statusId;
  final int parentId;
  final bool isSubtask;
  final int priorityId;
  final String startDate;
  final String dueDate;
  final String desc;
  final String note;
  final List<int> userId;
  final int canClientDiscuss;
  final String billingType;
  final int completionPercentage;
  final String enableReminder;
  final String enableRecurringTask;

  // Recurrence Fields
  final int? dayOfWeek;
  final int? dayOfMonth;
  final String? timeOfDay;
  final int? recurrenceDayOfWeek;
  final int? recurrenceDayOfMonth;
  final int? recurrenceMonthOfYear;
  final String? recurrenceStartsFrom;
  final String? frequencyType;
  final String? template_type;
  final String? recurringFrequencyType;
  final int? recurrenceOccurrences;
  final Map<String, dynamic> customFieldValues; // Declare the property

  WorkUpdateTask({
    required this.id,
    required this.title,
    required this.statusId,
    required this.parentId,
    required this.isSubtask,
    required this.canClientDiscuss,
    required this.priorityId,
    required this.startDate,
    required this.enableRecurringTask,
    required this.enableReminder,
    required this.billingType,
    required this.completionPercentage,
    required this.customFieldValues,
    required this.dueDate,
    required this.desc,
    required this.userId,
    required this.note,
    this.dayOfWeek,
    this.recurringFrequencyType,
    this.frequencyType,
    this.template_type,
    this.dayOfMonth,
    this.timeOfDay,
    this.recurrenceDayOfWeek,
    this.recurrenceDayOfMonth,
    this.recurrenceMonthOfYear,
    this.recurrenceStartsFrom,
    this.recurrenceOccurrences,
  });

  @override
  List<Object> get props => [
        id,
        title,
        statusId,
        priorityId,
        isSubtask,
        parentId,
        startDate,
        customFieldValues,
        dueDate,
        desc,
        note,
        userId,
        completionPercentage,
        canClientDiscuss,
        billingType,
        enableReminder,
        enableRecurringTask,
      ];
}

class WorkDeleteTask extends WorkTaskEvent {
  final int taskId;

  WorkDeleteTask(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class WorkSearchTasks extends WorkTaskEvent {
  final String searchQuery;
  final int? isFav;
  final bool? isSubtask;

  WorkSearchTasks(this.searchQuery, {this.isFav, this.isSubtask});

  @override
  List<Object?> get props => [searchQuery, isFav];
}

class WorkLoadMore extends WorkTaskEvent {
  final List<int>? userId;
  final List<int>? clientId;
  final List<int>? priorityId;
  final List<int>? statusId;
  final List<int>? projectId;
  final String? fromDate;
  final String? toDate;
  final String? searchQuery;
  final int? id;
  final int? isFav;
  WorkLoadMore(
      {this.id,
      this.projectId,
      this.clientId,
      this.userId,
      this.statusId,
      this.priorityId,
      this.fromDate,
      this.toDate,
      this.searchQuery,
      this.isFav});

  @override
  List<Object?> get props => [
        id,
        projectId,
        searchQuery,
        clientId,
        userId,
        statusId,
        priorityId,
        fromDate,
        toDate
      ];
}

class WorkLoadMoreToday extends WorkTaskEvent {
  final String fromDate;
  final String toDate;
  WorkLoadMoreToday(this.toDate, this.fromDate);

  @override
  List<Object?> get props => [];
}

class ResetWorkTaskState extends WorkTaskEvent {
  ResetWorkTaskState();

  @override
  List<Object?> get props => [];
}
