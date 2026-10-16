import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';
import 'package:slidable_bar/slidable_bar.dart';
import 'package:ibex/bloc/theme/theme_state.dart';
import 'package:ibex/config/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ibex/screens/widgets/custom_container.dart';

import 'package:ibex/utils/widgets/status_priority_row.dart';

import '../../bloc/comments/comments_bloc.dart';

import '../../bloc/permissions/permissions_bloc.dart';
import '../../bloc/worktask/task_bloc.dart';
import '../../bloc/worktask/task_event.dart';
import '../../bloc/worktask/task_state.dart';
import '../../bloc/worktask_id/taskid_bloc.dart';
import '../../bloc/worktask_id/taskid_event.dart';
import '../../bloc/worktask_id/taskid_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../config/constants.dart';
import '../../data/model/create_task_model.dart';
import '../../data/model/worktask/task_model.dart';
import '../../routes/routes.dart';
import '../../utils/widgets/custom_text.dart';
import '../../utils/widgets/my_theme.dart';
import '../../utils/widgets/toast_widget.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import '../dash_board/dashboard.dart';
import '../notes/widgets/notes_shimmer_widget.dart';
import '../widgets/back_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/detail_page_menu.dart';
import '../widgets/html_widget.dart';
import '../widgets/side_bar.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import '../home_screen/home_widgets/drawer_widgets.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class WorkTaskDetailScreen extends StatefulWidget {
  final bool? fromNoti;
  final String? from;
  final int? id;
  const WorkTaskDetailScreen({super.key, this.fromNoti, this.from, this.id});

  @override
  State<WorkTaskDetailScreen> createState() => _WorkTaskDetailScreenState();
}

class _WorkTaskDetailScreenState extends State<WorkTaskDetailScreen> {
  DateTime selectedDateStarts = DateTime.now();
  DateTime selectedDateEnds = DateTime.now();

  String selectedCategory = '';
  final _key = GlobalKey<ExpandableFabState>();

  List<WorkTasks> task = [];
  List<String> username = [];

  int? id;
  int? workspaceId;
  String? title;
  WorkTasks? taskModel;
  String? status;
  int? statusId;
  String? priority;
  int? priorityId;
  List<WorkTaskUsers>? users;
  List<int>? userId;
  List<WorkTaskClients>? clients;
  String? startDate;
  String? dueDate;
  String? project;
  int? projectId;
  int? canClientDiscuss;
  String? description;
  String? frequencyType;
  String? timeOfDay;
  int? isReminderEnabled;
  int? isRecurrenceTaskEnabled;
  int? dayOfWeek;
  int? dayOfMonth;
  String? recurenceFrequency;
  int? recDayOfWeek;
  int? recDayOfMonth;
  int? recMonthOfYear;
  String? recStartsFrom;
  int? recOcurrences;
  int? completedOcurrences;
  String? note;
  String? createdAt;
  String? updatedAt;
  String? dateCreated = '';
  String? dateUpdated = '';
  String? dateStart = '';
  String? dateEnd = '';
  WorkTasks? model;

  final SlidableBarController sideBarController = SlidableBarController(
    initialStatus: false,
  );
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Add ScrollController
  bool isExpand = false;
  bool _isSidebarOpen = false; // Track sidebar open/close state

  void toggleDrawer(bool expanded) {
    setState(() {
      isExpand = expanded;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkTaskidBloc>().add(WorkTaskIdListId(widget.id));
    });
  }

  void _onWorkDeleteTask(taskId) {
    BlocProvider.of<WorkTaskBloc>(context).add(WorkDeleteTask(taskId));

    // Navigator.of(context).pop(); // Close the dialog
  }

  Future<void> _onRefresh() async {
    if (kDebugMode) {
      logger.d('Refreshing_task: ${widget.id}');
    }
    BlocProvider.of<WorkTaskidBloc>(context).add(WorkTaskIdListId(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;

    bool isLightTheme = currentTheme is LightThemeState;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        BlocProvider.of<WorkTaskidBloc>(
          context,
        ).add(WorkTaskIdListId(widget.id));
        if (!didPop) {
          router.pop();
        }
      },
      child: MultiBlocListener(
        listeners: [
          // ✅ WorkTaskBloc listener нэмэх
          BlocListener<WorkTaskBloc, WorkTaskState>(
            listener: (context, state) {
              if (state is WorkTaskEditSuccess ||
                  state is WorkTaskCreateSuccess) {
                _onRefresh();
              }

              // ✅ Delete success үед
              if (state is WorkTaskDeleteSuccess) {
                flutterToastCustom(
                  msg: AppLocalizations.of(context)!.deletedsuccessfully,
                  color: AppColors.primary,
                );

                // ✅ Dialog хаах
                if (Navigator.of(context).canPop()) {
                  if (kDebugMode) {
                    logger.d('🔥 [UI] Closing dialog');
                  }
                  Navigator.of(context).pop(); // Close confirm dialog
                }

                // // ✅ State reset (delayed)
                // Future.delayed(Duration(milliseconds: 500), () {
                //   if (mounted) {
                //     print('🔥 [UI] Resetting WorkTaskBloc state');
                //     context.read<WorkTaskBloc>().add(
                //         AllWorkTaskListOnTask()); // ← Task list дахин ачаалах
                //   }
                // });

                // ✅ WorkTaskBloc state-ийг reset хийх
                context.read<WorkTaskBloc>().add(ResetWorkTaskState());

                // ✅ Task detail хуудас хаах (work_details руу буцах)
                router.pop(); // Return with refresh signal
              }

              // ✅ Delete error үед
              if (state is WorkTaskDeleteError) {
                flutterToastCustom(msg: state.errorMessage);

                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }

                Navigator.of(context).pushAndRemoveUntil(
                  CupertinoPageRoute(
                    builder: (context) => const DashBoard(initialIndex: 2),
                  ),
                  (route) => false,
                );
              }

              // ✅ General error үед
              if (state is WorkTaskError) {
                flutterToastCustom(msg: state.errorMessage);

                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }

                Navigator.of(context).pushAndRemoveUntil(
                  CupertinoPageRoute(
                    builder: (context) => const DashBoard(initialIndex: 2),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
        child: Scaffold(
          key: _scaffoldKey,
          drawer: DrawerWidgets(isExpand: isExpand, toggleDrawer: toggleDrawer),
          backgroundColor: Theme.of(context).colorScheme.backGroundColor,
          floatingActionButtonLocation: ExpandableFab.location,
          floatingActionButton:
              context.read<PermissionsBloc>().isdeleteTask == true ||
                      context.read<PermissionsBloc>().iseditTask == true
                  ? detailMenu(
                      onpressChat: () {
                        _key.currentState?.toggle();
                        router.push(
                          "/commentsection",
                          extra: {
                            "id": widget.id,
                            "title": title,
                            "isProject": false,
                            "model": "worktaskcomment",
                          },
                        );
                        context.read<CommentsBloc>().isProject = false;
                      },
                      isChat: false,
                      isDiscuss: false,
                      isEdit: context.read<PermissionsBloc>().iseditTask,
                      isDelete: context.read<PermissionsBloc>().isdeleteTask,
                      key: _key,
                      context: context,
                      onpressEdit: () {
                        _key.currentState?.toggle();
                        // List<String> username = [];
                        // for (var names in users!) {
                        //   username.add(names.firstName!);
                        // }
                        // List<int>? ids = [];
                        // for (var i in users!) {
                        //   ids.add(i.id!);
                        // }

                        router.push(
                          '/createworktask',
                          extra: {
                            "id": widget.id,
                            "isCreate": false,
                            "fromDetail": true,
                            "title": title,
                            "users": [],
                            "user": '',
                            "usersid": [],
                            "desc": description,
                            "start": startDate,
                            "end": dueDate,
                            'priority': priority,
                            'priorityId': priorityId,
                            'statusId': statusId,
                            'note': note,
                            'project': '',
                            "userList": users,
                            "tasksModel": WorkTasks.empty(),
                            'projectId': projectId,
                            'status': status,
                            'req': <CreateTaskModel>[],
                          },
                        );
                        // Navigator.pop(context);
                      },
                      onpressDelete: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            // ✅ dialogContext ашиглах
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  10.r,
                                ), // Set the desired radius here
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.alertBoxBackGroundColor,
                              title: Text(
                                AppLocalizations.of(context)!.confirmDelete,
                              ),
                              content: Text(
                                AppLocalizations.of(context)!.areyousure,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(
                                      dialogContext,
                                    ).pop(); // ✅ Dialog хаах

                                    _onWorkDeleteTask(widget.id);
                                  },
                                  child: const Text('Delete'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                    ).pop(false); // Cancel deletion
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onpressdiscuss: () {
                        _key.currentState?.toggle();
                        router.push(
                          "/worktaskdiscussionTabs",
                          extra: {"isDetail": true, "id": widget.id},
                        );
                      },
                    )
                  : SizedBox.shrink(),
          body: Stack(
            children: [
              SideBar(
                context: context,
                scaffoldKey: _scaffoldKey, // Шинээр нэмэх
                controller: sideBarController,
                onSideBarToggle: (isOpen) {
                  setState(() {
                    _isSidebarOpen = isOpen;
                  });
                },
                underWidget: RefreshIndicator(
                  color: AppColors.primary, // Spinner color
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.backGroundColor,
                  onRefresh: _onRefresh,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0.w),
                    child: SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(), // Ensure always scrollable

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomAppBar(
                            title: AppLocalizations.of(context)!.taskdetail,
                            onMenuPressed: () {
                              setState(() {
                                isExpand = false;
                              });
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                          SizedBox(height: 10.h),
                          BlocConsumer<WorkTaskidBloc, WorkTaskidState>(
                            listener: (context, state) {
                              if (state is WorkTaskidWithId) {
                                dateCreated = '';
                                dateUpdated = '';
                                dateStart = '';
                                dateEnd = '';
                                for (var item in state.task) {
                                  model = WorkTasks(
                                    title: item.title ?? "",
                                    status: item.status ?? "",
                                    statusId: item.statusId ?? 0,
                                    priority: item.priority ?? "",
                                    priorityId: item.priorityId ?? 0,
                                    description: item.description ?? "",
                                    note: item.note ?? "",
                                    startDate: item.startDate ?? "",
                                    dueDate: item.dueDate ?? "",
                                    createdAt: item.createdAt ?? "",
                                    updatedAt: item.updatedAt ?? "",
                                    users: item.users ?? [],
                                    clientCanDiscuss:
                                        item.clientCanDiscuss ?? 0,
                                    userId: item.userId ?? [],
                                    clients: item.clients ?? [],
                                    projectId: item.projectId ?? 0,
                                    project: item.project ?? "",
                                  );

                                  title = item.title;
                                  status = item.status;
                                  priority = item.priority;
                                  users = item.users;
                                  clients = item.clients;
                                  project = item.project;
                                  startDate = item.startDate;
                                  dueDate = item.dueDate;
                                  description = item.description;
                                  note = item.note;
                                  createdAt = item.createdAt;
                                  updatedAt = item.updatedAt;
                                  taskModel = item;
                                  priorityId = item.priorityId;
                                  userId = item.userId;
                                  users = item.users;
                                  statusId = item.statusId;
                                  projectId = item.projectId;
                                  username = [];
                                  if (users != null && users!.isNotEmpty) {
                                    for (var user in users!) {
                                      if (user.firstName != null &&
                                          user.firstName!.isNotEmpty) {
                                        username.add(user.firstName!);
                                      }
                                    }
                                  }

                                  // ✅ Null check before parsing
                                  if (createdAt != null &&
                                      createdAt!.isNotEmpty) {
                                    dateCreated = parseDateTimeFormat(
                                      createdAt!,
                                    );
                                  }
                                  if (updatedAt != null &&
                                      updatedAt!.isNotEmpty) {
                                    dateUpdated = parseDateTimeFormat(
                                      updatedAt!,
                                    );
                                  }
                                  if (startDate != null &&
                                      startDate!.isNotEmpty) {
                                    dateStart = parseDateTimeFormat(startDate!);
                                  }
                                  if (dueDate != null && dueDate!.isNotEmpty) {
                                    dateEnd = parseDateTimeFormat(dueDate!);
                                  }
                                  // clientIds = item.c;
                                }
                              }
                            },
                            builder: (context, state) {
                              if (state is WorkTaskidWithId) {
                                dateCreated = '';
                                dateUpdated = '';
                                dateStart = '';
                                dateEnd = '';

                                for (var item in state.task) {
                                  title = item.title ?? "";
                                  status = item.status ?? "";
                                  priority = item.priority ?? "";
                                  users = item.users ?? [];
                                  clients = item.clients ?? [];
                                  userId = item.userId ?? [];

                                  project = item.project ?? "";
                                  startDate = item.startDate ?? "";
                                  dueDate = item.dueDate ?? "";
                                  description = item.description ?? "";
                                  note = item.note ?? "";
                                  createdAt = item.createdAt ?? "";
                                  updatedAt = item.updatedAt ?? "";
                                  priorityId = item.priorityId;
                                  statusId = item.statusId ?? 0;
                                  projectId = item.projectId ?? 0;
                                  frequencyType = item.frequencyType ?? "";
                                  timeOfDay = item.timeOfDay ?? "";
                                  isReminderEnabled = item.enableReminder ?? 0;
                                  isRecurrenceTaskEnabled =
                                      item.enableRecurringTask ?? 0;
                                  dayOfWeek = item.dayOfWeek ?? 0;
                                  dayOfMonth = item.dayOfMonth ?? 0;
                                  canClientDiscuss = item.clientCanDiscuss ?? 0;
                                  taskModel = item;
                                  recurenceFrequency =
                                      item.recurrenceFrequency ?? "";
                                  recDayOfWeek = item.recurrenceDayOfWeek ?? 0;
                                  recDayOfMonth =
                                      item.recurrenceDayOfMonth ?? 0;
                                  recMonthOfYear =
                                      item.recurrenceMonthOfYear ?? 0;
                                  recStartsFrom =
                                      item.recurrenceStartsFrom ?? "";
                                  recOcurrences =
                                      item.recurrenceOccurrences ?? 0;
                                  completedOcurrences =
                                      item.completedOccurrences ?? 0;

                                  username = [];
                                  if (users != null && users!.isNotEmpty) {
                                    for (var user in users!) {
                                      if (user.firstName != null &&
                                          user.firstName!.isNotEmpty) {
                                        username.add(user.firstName!);
                                      }
                                    }
                                  }

                                  // ✅ Null check before parsing
                                  if (createdAt != null &&
                                      createdAt!.isNotEmpty) {
                                    dateCreated = parseDateTimeFormat(
                                      createdAt!,
                                    );
                                  }
                                  if (updatedAt != null &&
                                      updatedAt!.isNotEmpty) {
                                    dateUpdated = parseDateTimeFormat(
                                      updatedAt!,
                                    );
                                  }
                                  if (startDate != null &&
                                      startDate!.isNotEmpty) {
                                    dateStart = parseDateTimeFormat(startDate!);
                                  }
                                  if (dueDate != null && dueDate!.isNotEmpty) {
                                    dateEnd = parseDateTimeFormat(dueDate!);
                                  }

                                  // clientIds = item.c;
                                }

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 18.w,
                                      ),
                                      child: _taskCard(),
                                    ),
                                    SizedBox(height: 20.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 18.w,
                                      ),
                                      child: _descCard(),
                                    ),
                                    SizedBox(height: 20.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 18.w,
                                      ),
                                      child: _dateCard(
                                        dateStart,
                                        dateEnd,
                                        dateCreated,
                                        dateUpdated,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    Divider(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.dividerClrChange,
                                    ),
                                    SizedBox(height: 15.h),
                                  ],
                                );
                              }
                              if (state is WorkTaskLoading) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18.w,
                                  ),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                        isLightTheme,
                                        context,
                                        150.h,
                                      ),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                        isLightTheme,
                                        context,
                                        150.h,
                                      ),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                        isLightTheme,
                                        context,
                                        50.h,
                                      ),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                        isLightTheme,
                                        context,
                                        120.h,
                                      ),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                        isLightTheme,
                                        context,
                                        120.h,
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                );
                              }
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18.w),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    shimmerDetails(
                                      isLightTheme,
                                      context,
                                      150.h,
                                    ),
                                    const SizedBox(height: 20),
                                    shimmerDetails(
                                      isLightTheme,
                                      context,
                                      150.h,
                                    ),
                                    const SizedBox(height: 20),
                                    shimmerDetails(isLightTheme, context, 50.h),
                                    const SizedBox(height: 20),
                                    shimmerDetails(
                                      isLightTheme,
                                      context,
                                      120.h,
                                    ),
                                    const SizedBox(height: 20),
                                    shimmerDetails(
                                      isLightTheme,
                                      context,
                                      120.h,
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              BackBar(rightOffset: _isSidebarOpen ? 52.w : 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskCard() {
    return customContainer(
      width: double.infinity,
      context: context,
      addWidget: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CustomText(
              text: title ?? "",
              fontWeight: FontWeight.w700,
              size: 18,
              color: Theme.of(context).colorScheme.textClrChange,
            ),
            SizedBox(height: 10.h),
            SizedBox(
              // color: Colors.red,
              // width: 240.w,
              child: statusClientRow(status, priority, context, true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _descCard() {
    return customContainer(
      width: double.infinity,
      context: context,
      addWidget: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // ✅ Title with icon
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: HeroIcon(
                    HeroIcons.documentText,
                    style: HeroIconStyle.solid,
                    size: 14.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 10.w),
                CustomText(
                  text: AppLocalizations.of(context)!.description,
                  size: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.textClrChange,
                ),
              ],
            ),

            // ✅ Divider (optional)
            Container(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.dividerClrChange.withValues(alpha: 0.3),
            ),

            SizedBox(height: 12.h),

            // ✅ Description content
            ExpandableHtmlNoteWidget(
              text: description ?? "?",
              context: context,
              width: 290.w,
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _dateCard(dateStart, dateEnd, dateCreated, dateUpdated) {
    return customContainer(
      width: double.infinity,
      context: context,
      addWidget: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
        child: Column(
          children: [
            startDate != null && startDate!.isNotEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        text: "${AppLocalizations.of(context)!.startdate} : ",
                        size: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                      CustomText(
                        text: dateStart,
                        size: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            startDate != null && startDate!.isNotEmpty
                ? SizedBox(height: 10.h)
                : SizedBox.shrink(),
            dueDate != null && dueDate!.isNotEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        text: "${AppLocalizations.of(context)!.duedate} :",
                        size: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                      CustomText(
                        text: " $dateEnd",
                        size: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            dueDate != null && dueDate!.isNotEmpty
                ? SizedBox(height: 10.h)
                : SizedBox(),
            createdAt != null && createdAt!.isNotEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        text: "${AppLocalizations.of(context)!.createdat} : ",
                        size: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                      CustomText(
                        text: dateCreated,
                        size: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            SizedBox(height: 10.h),
            updatedAt != null && updatedAt!.isNotEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        text: "${AppLocalizations.of(context)!.updatedAt} :",
                        size: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                      CustomText(
                        text: " $dateUpdated",
                        size: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
