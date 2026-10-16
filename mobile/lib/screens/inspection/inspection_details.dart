import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';

import 'package:slidable_bar/slidable_bar.dart';
import 'package:ibex/bloc/permissions/permissions_bloc.dart';
import 'package:ibex/utils/widgets/custom_text.dart';
import '../../bloc/auth/auth_bloc.dart';

import '../../bloc/comments/comments_bloc.dart';

import '../../bloc/inspection/inspection_event.dart';
import '../../bloc/inspection/inspection_state.dart';
import '../../bloc/inspection/inspection_bloc.dart';
import '../../bloc/inspection_id/inspectionid_bloc.dart';
import '../../bloc/inspection_id/inspectionid_event.dart';
import '../../bloc/inspection_id/inspectionid_state.dart';
import '../../bloc/inspectiontask_id/taskid_bloc.dart';
import '../../bloc/inspectiontask_id/taskid_event.dart';
import '../../bloc/setting/settings_bloc.dart';

import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';

import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../data/localStorage/hive.dart';
import '../../data/model/inspection/inspection.dart';
import '../../data/model/inspectiontask/task_model.dart';
import '../../data/repositories/inspection/inspection_repo.dart';
import '../../data/repositories/inspectiontask/task_repo.dart';
import '../../routes/routes.dart';
import '../../utils/widgets/back_arrow.dart';
import '../../utils/widgets/status_priority_row.dart';
import '../../utils/widgets/toast_widget.dart';
import '../../utils/widgets/user_client_row_detail_page.dart';
// import '../../utils/widgets/check_with_task_details.dart';
import '../../utils/widgets/task_with_check.dart';
import '../../utils/widgets/task_with_input.dart';

import '../dash_board/dashboard.dart';
import '../notes/widgets/notes_shimmer_widget.dart';
import '../widgets/back_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_container.dart';
import '../widgets/detail_page_menu.dart';
import '../widgets/html_widget.dart';
import '../widgets/no_data.dart';
import '../widgets/side_bar.dart';
import '../home_screen/home_widgets/drawer_widgets.dart';

import '../widgets/user_client_box.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import '../../utils/widgets/status_action_row.dart';
import 'inspection_from_drawer.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionDetails extends StatefulWidget {
  final int? id;
  final bool? fromNoti;
  final String? from;
  final String? type;
  final InspectionModel workModel;

  const InspectionDetails({
    super.key,
    this.id,
    this.fromNoti,
    this.from,
    this.type,
    required this.workModel,
  });

  @override
  State<InspectionDetails> createState() => _InspectionDetailsState();
}

class _InspectionDetailsState extends State<InspectionDetails> {
  // List of items in our dropdown menu

  // Function to handle checkbox state change
  List<int> userId = [];
  List<int> assetId = [];
  List<InspectionUsers>? users;
  List<int>? usersIds = [];
  List<int>? clientIds = [];
  List<Tag>? tags = [];
  List<int>? tagIds = [];
  List<InspectionClients>? clients;
  List<String>? clientList;
  List<String>? userList;
  List<int> clientId = [];
  List<String>? tagList;
  String? statusFrom;
  String? priority;
  String? note;
  String? createdAt;
  String? updatedAt;
  String? taskAccessibility;
  String? workType;
  int? priorityId;
  int? action_status;
  List<int>? workTypeId;
  List<int>? tagId;
  int? statusId;
  String? title;
  String? status;
  bool? isLoading = true;
  bool? isLoadingOnRefresh = true;
  String? description;
  List<InspectionTasks> task = [];
  int? statusIds;
  int? canClientDiscuss;
  int? enable;
  String? currency;
  String? currencyPosition;

  String? budget;
  String? endDate;
  String? hasGuard;
  String? startDate;
  String? taskAccess;
  String dateCreated = '';
  String dateUpdated = '';
  String dateStart = '';
  String dateEnd = '';
  String role = '';
  String taskAssignee = '';
  Map<String, dynamic>? asset;
  List<Map<String, dynamic>>? assetList; // ← Map биш List болгох

  final _key = GlobalKey<ExpandableFabState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isExpand = true;
  Map<String, dynamic>? assigned_to;
  bool isLoadingTask = false;
  InspectionModel? model;
  List<InspectionModel> work = [];
  dynamic woStatusData;

  // ✅ Debounce timer for task value updates
  Timer? _debounceTimer;
  final Map<int?, String> _pendingUpdates = {};

  _getTask() async {
    setState(() {
      isLoadingTask = true;
    });
    Map<String, dynamic> result = await InspectionTaskRepo()
        .getTask(token: true, projectId: [widget.id!], limit: -1);

    // ✅ 1. Эхлээд бүх task-уудыг flat list болгож авах
    List<InspectionTasks> allTasks = List<InspectionTasks>.from(
      result['data'].map((workData) => InspectionTasks.fromJson(workData)),
    );

    // ✅ 2. Flat array-ийг nested tree болгох
    task = _buildTaskTree(allTasks);

    // _printAllTasks(task, 0); // Recursive хэвлэх функц дуудалт
    setState(() {
      isLoadingTask = false;
    });
  }

  // ✅ Flat array-ийг nested tree болгох helper функц
  List<InspectionTasks> _buildTaskTree(List<InspectionTasks> flatList) {
    // Task ID-аар Map үүсгэх (хурдан хайлт хийхийн тулд)
    Map<int, InspectionTasks> taskMap = {};
    for (var task in flatList) {
      taskMap[task.id!] = task;
      task.children = []; // Children-ийг анх хоослох
    }

    // Root tasks (parent == null) болон children-ийг холбох
    List<InspectionTasks> rootTasks = [];

    for (var task in flatList) {
      // Хэрвээ parent байвал parent-д нэмэх
      if (task.parent != null && taskMap.containsKey(task.parent)) {
        taskMap[task.parent]!.children!.add(task);
      } else {
        // Parent байхгүй бол root task
        rootTasks.add(task);
      }
    }

    return rootTasks;
  }

  void _onDeleteInspection(projectId) {
    final setting = context.read<InspectionBloc>();
    BlocProvider.of<InspectionBloc>(context).add(DeleteInspection(projectId));
    setting.stream.listen((state) {
      if (state is InspectionDeleteSuccess) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            CupertinoPageRoute(
              builder: (context) => const DashBoard(initialIndex: 1),
            ),
            (route) {
              return route is! CupertinoPageRoute ||
                  route.settings.name != 'InspectionDetails';
            },
          );

          flutterToastCustom(
            msg: AppLocalizations.of(context)!.deletedsuccessfully,
            color: AppColors.primary,
          );
        }
      }
      if (state is InspectionDeleteError) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            CupertinoPageRoute(
              builder: (context) => const DashBoard(initialIndex: 1),
            ),
            (route) {
              return route is! CupertinoPageRoute ||
                  route.settings.name != 'InspectionDetails';
            },
          );

          flutterToastCustom(msg: state.errorMessage);
        }
      }
      if (state is InspectionDeleteError) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            CupertinoPageRoute(
              builder: (context) => const DashBoard(initialIndex: 1),
            ),
            (route) {
              return route is! CupertinoPageRoute ||
                  route.settings.name != 'InspectionDetails';
            },
          );

          flutterToastCustom(msg: state.errorMessage);
        }
      }
    });
  }

  void _onEditInspection() {
    _key.currentState?.toggle();
    List<String>? userList = [];
    List<String>? assetsList = [];

    List<String>? clientList = [];
    List<String>? tagList = [];
    List<int> assetIdList = []; // ✅ Local list үүсгэх

    if (users != null) {
      for (var user in users!) {
        userList.add(user.firstName!);
        userId.add(user.id!);
      }
    }

    // ✅ Fix: asset handling
    if (asset != null) {
      final assetCode = asset!['asset_code'];
      final id = asset!['id'];

      if (assetCode != null) {
        assetsList.add(assetCode.toString());
      }

      if (id != null) {
        assetIdList.add(id is int ? id : int.tryParse(id.toString()) ?? 0);
      }
    }
    if (clients != null) {
      for (var client in clients!) {
        clientList.add(client.firstName!);
        clientId.add(client.id!);
      }
    }

    if (tags != null) {
      for (var tag in tags!) {
        tagList.add(tag.title!);
      }
    }

    context.read<PermissionsBloc>().iseditInspection == true
        ? router.push(
            '/creatework',
            extra: {
              "id": widget.id,
              "isCreate": false,
              "fromDetail": true,
              "title": title,
              "desc": description,
              "start": startDate ?? "",
              "end": endDate ?? "",
              "budget": budget,
              'priority': widget.workModel.priority,
              'priorityId': widget.workModel.priorityId,
              'statusId': widget.workModel.statusId,
              'note': note,
              "clientNames": clientList,
              "userNames": userList,
              "teamsNames": userList,
              "assetNames": assetsList,
              "tagNames": tagList,
              "userId": userId,
              "assetId": assetIdList,
              "tagId": tagId,
              "clientId": clientId,
              "access": taskAccessibility,
              'status': widget.workModel.status,
              "canClientDiscuss": widget.workModel.clientCanDiscuss,
              'customFieldsModel': widget.workModel,
            },
          )
        : null;
  }

  Future<void> _completeInspection() async {
    try {
      // Update inspection status to Completed (statusId = 3)
      final repo = InspectionRepo();
      await repo.updateInspection(
        id: widget.id!,
        statusId: 3, // 3 = Completed status
      );

      // Refresh the inspection data
      BlocProvider.of<InspectionidBloc>(context)
          .add(InspectionIdListId(widget.id));

      // Show success message
      flutterToastCustom(
        msg: 'Inspection completed successfully',
        color: AppColors.primary,
      );

      if (kDebugMode) {
        logger.d('🔥 Inspection ${widget.id} marked as completed');
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('❌ Error completing inspection: $e');
      }
      flutterToastCustom(
        msg: 'Failed to complete inspection',
        color: Colors.red,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    hasGuard = context.read<AuthBloc>().guard;
    // _getRole();
    _getTask();

    workType = widget.type ?? 'open';

    currency = context.read<SettingsBloc>().currencySymbol;
    currencyPosition = context.read<SettingsBloc>().currencyPosition;

    BlocProvider.of<InspectionidBloc>(context)
        .add(InspectionIdListId(widget.id));

    // ✅ Status data-г Hive-с уншина (API дуудалт биш)
    _initAsync();
  }

  Future<void> _initAsync() async {
    woStatusData = await HiveStorage.getAllStatusData();
  }

  Future<void> _getRole() async {
    role = await HiveStorage.getRole();

    logger.d(
      "fhDZFKh ${role == "Client" && widget.workModel.clientCanDiscuss == 1}",
    );
  }

  Future<void> _onRefresh() async {
    _getTask();

    BlocProvider.of<InspectionidBloc>(context)
        .add(InspectionIdListId(widget.id));
  }

  final SlidableBarController controller = SlidableBarController(
    initialStatus: false,
  );
  bool _isSidebarOpen = false; // Track sidebar open/close state

  @override
  Widget build(BuildContext context) {
    bool isCreateTask = context.read<PermissionsBloc>().iscreatetask ?? false;
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;
    // print('widget-> ${widget.workModel.toJson()}');
    // print('widget_from-> ${widget.from}');

    bool isLightTheme = currentTheme is LightThemeState;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (widget.from == "dashboard") {
          router.pop();
          BlocProvider.of<InspectionBloc>(context)
              .add(InspectionDashBoardList());
          BlocProvider.of<InspectionTaskidBloc>(
            context,
          ).add(InspectionTaskIdListId(widget.id));
        }
        if (!didPop) {
          router.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: DrawerWidgets(
          isExpand: isExpand,
          toggleDrawer: (value) {
            setState(() {
              isExpand = value;
            });
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.backGroundColor,
        floatingActionButtonLocation: ExpandableFab.location,
        floatingActionButton:
            (context.read<PermissionsBloc>().isdeleteInspection == true ||
                    context.read<PermissionsBloc>().iseditInspection == true)
                ? _menubttn(widget.type)
                : SizedBox.shrink(),
        body: Stack(
          children: [
            Container(
              color: Theme.of(context).colorScheme.backGroundColor,
              child: SideBar(
                context: context,
                controller: controller,
                scaffoldKey: _scaffoldKey, // Шинээр нэмэх
                isExpand: isExpand, // Шинээр нэмэх
                onSideBarToggle: (isOpen) {
                  setState(() {
                    _isSidebarOpen = isOpen;
                  });
                },
                toggleDrawer: (value) {
                  // Шинээр нэмэх
                  setState(() {
                    isExpand = value;
                  });
                },
                hasGuard: hasGuard,
                underWidget: RefreshIndicator(
                  color: AppColors.primary, // Spinner color
                  backgroundColor:
                      Theme.of(context).colorScheme.backGroundColor,
                  onRefresh: _onRefresh,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0.w),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomAppBar(
                            title:
                                AppLocalizations.of(context)!.inspectiondetails,
                            onMenuPressed: () {
                              setState(() {
                                isExpand = false;
                              });
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                          const SizedBox(height: 10),
                          BlocConsumer<InspectionidBloc, InspectionidState>(
                            listener: (context, state) {
                              if (kDebugMode) {
                                logger.d("WORKDETAILS_listener");
                              }

                              if (state is InspectionDeleteSuccess) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        const DashBoard(initialIndex: 1),
                                  ),
                                  (route) {
                                    return route is! CupertinoPageRoute ||
                                        route.settings.name !=
                                            'InspectionDetails';
                                  },
                                );

                                flutterToastCustom(
                                  msg: AppLocalizations.of(
                                    context,
                                  )!
                                      .deletedsuccessfully,
                                  color: AppColors.primary,
                                );
                              }
                              if (state is InspectionidWithId) {
                                users = <InspectionUsers>[];
                                usersIds = <int>[];
                                for (var useritem in state.inspectionsUsers) {
                                  // Parse Map to InspectionUsers if needed
                                  if (useritem is Map<String, dynamic>) {
                                    final user =
                                        InspectionUsers.fromJson(useritem);
                                    users?.add(user);
                                    if (user.id != null) {
                                      usersIds?.add(user.id!);
                                    }
                                  } else if (useritem is InspectionUsers) {
                                    users?.add(useritem);
                                    if (useritem.id != null) {
                                      usersIds?.add(useritem.id!);
                                    }
                                  }
                                }

                                for (var item in state.work) {
                                  title = item.title;
                                  status = item.status;
                                  statusIds = item.statusId; //int
                                  priority = item.priority;
                                  priorityId = item.priorityId;
                                  // users = item.users;
                                  // usersIds = item.userId;
                                  clients = item.clients;
                                  status = item.status;
                                  clientIds = item.clientId;
                                  asset =
                                      item.asset ?? {'asset_code': 'Unknown'};
                                  // ✅ Fix: asset check
                                  // if (item.asset != null) {
                                  //   if (item.asset is List) {
                                  //     assetList = List<Map<String, dynamic>>.from(
                                  //         item.asset as List);
                                  //   } else if (item.asset is Map) {
                                  //     assetList = [
                                  //       item.asset as Map<String, dynamic>
                                  //     ];
                                  //   }
                                  // } else {
                                  //   assetList = null;
                                  // }
                                  assigned_to = item.assigned_to ??
                                      {'assigned_to': 'None'};
                                  tags = item.tags; //list int
                                  tagIds = item.tagIds; //list int
                                  startDate = item.startDate;
                                  endDate = item.endDate;
                                  action_status = item.action_status;
                                  budget = item.budget;
                                  taskAccessibility = item.taskAccessibility;
                                  description = item.description;
                                  note = item.note;
                                  createdAt = item.createdAt;
                                  updatedAt = item.updatedAt;
                                  enable = item.enable!;
                                  canClientDiscuss = item.clientCanDiscuss!;
                                  // ✅ Safe date parsing
                                  if (createdAt != null &&
                                      createdAt!.isNotEmpty) {
                                    dateCreated =
                                        parseDateTimeFormat(createdAt!);
                                  } else {
                                    dateCreated = '';
                                  }

                                  if (updatedAt != null &&
                                      updatedAt!.isNotEmpty) {
                                    dateUpdated =
                                        parseDateTimeFormat(updatedAt!);
                                  } else {
                                    dateUpdated = '';
                                  }

                                  if (startDate != null &&
                                      startDate!.isNotEmpty) {
                                    dateStart = parseDateTimeFormat(startDate!);
                                  } else {
                                    dateStart = '';
                                  }

                                  if (endDate != null && endDate!.isNotEmpty) {
                                    dateEnd = parseDateTimeFormat(endDate!);
                                  } else {
                                    dateEnd = '';
                                  }
                                  // clientIds = item.c;
                                }
                              }
                            },
                            builder: (context, state) {
                              // print("WORKDETAILS_builder task ${widget.type}");
                              if (state is InspectionidWithId) {
                                // print("WORKDETAILS_builder ${state.work}");
                                // print(
                                //     "INSPECTIONS USERS ${state.inspectionsUsers}");

                                // ✅ Collect all users from inspectionsUsers
                                users = <InspectionUsers>[];
                                usersIds = <int>[];
                                for (var useritem in state.inspectionsUsers) {
                                  // Parse Map to InspectionUsers if needed
                                  if (useritem is Map<String, dynamic>) {
                                    final user =
                                        InspectionUsers.fromJson(useritem);
                                    users?.add(user);
                                    if (user.id != null) {
                                      usersIds?.add(user.id!);
                                    }
                                  } else if (useritem is InspectionUsers) {
                                    users?.add(useritem);
                                    if (useritem.id != null) {
                                      usersIds?.add(useritem.id!);
                                    }
                                  }
                                }

                                for (var item in state.work) {
                                  model = InspectionModel(
                                    title: item.title,
                                    status: item.status,
                                    statusId: item.statusId,
                                    priorityId: item.priorityId,
                                    asset: item.asset,
                                    assigned_to: item.assigned_to,
                                    budget: item.budget ?? '',
                                    taskAccessibility:
                                        item.taskAccessibility ?? '',
                                    description: item.description ?? '',
                                    note: item.note ?? '',
                                    enable: item.enable! ?? 1,
                                    clientCanDiscuss:
                                        item.clientCanDiscuss! ?? 0,
                                    startDate: item.startDate,
                                    endDate: item.endDate,
                                    action_status: item.action_status ?? 0,
                                    createdAt: item.createdAt ?? '',
                                    updatedAt: item.updatedAt ?? '',
                                    users: item.users ?? [],
                                    userId: item.userId ?? [],
                                    clients: item.clients ?? [],
                                    clientId: item.clientId ?? [],
                                    tags: item.tags ?? [],
                                    tagIds: item.tagIds ?? [],
                                  );
                                  title = item.title;
                                  status = item.status ?? '';
                                  statusIds = item.statusId ?? 0; //int
                                  priority = item.priority ?? '';
                                  priorityId = item.priorityId ?? 0;
                                  // users and usersIds are collected from state.inspectionsUsers above
                                  clients = item.clients ?? [];
                                  status = item.status ?? '';
                                  clientIds = item.clientId ?? [];
                                  tags = item.tags ?? []; //list int
                                  tagIds = item.tagIds ?? []; //list int
                                  startDate = item.startDate ?? '';
                                  endDate = item.endDate ?? '';
                                  action_status = item.action_status ?? 0;
                                  budget = item.budget ?? '';
                                  taskAccessibility =
                                      item.taskAccessibility ?? '';
                                  description = item.description ?? '';
                                  note = item.note ?? '';
                                  createdAt = item.createdAt ?? '';
                                  enable = item.enable! ?? 1;
                                  canClientDiscuss =
                                      item.clientCanDiscuss! ?? 0;
                                  updatedAt = item.updatedAt ?? '';

                                  // ✅ Safe date parsing
                                  if (createdAt != null &&
                                      createdAt!.isNotEmpty) {
                                    dateCreated =
                                        parseDateTimeFormat(createdAt!);
                                  } else {
                                    dateCreated = '';
                                  }

                                  if (updatedAt != null &&
                                      updatedAt!.isNotEmpty) {
                                    dateUpdated =
                                        parseDateTimeFormat(updatedAt!);
                                  } else {
                                    dateUpdated = '';
                                  }

                                  if (startDate != null &&
                                      startDate!.isNotEmpty) {
                                    dateStart = parseDateTimeFormat(startDate!);
                                  } else {
                                    dateStart = '';
                                  }

                                  if (endDate != null && endDate!.isNotEmpty) {
                                    dateEnd = parseDateTimeFormat(endDate!);
                                  } else {
                                    dateEnd = '';
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
                                      child: _workCard(action_status, context),
                                    ),
                                    SizedBox(height: 20.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 18.w,
                                      ),
                                      child: _assetCard(asset, context),
                                    ),
                                    SizedBox(height: 20.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 18.w,
                                      ),
                                      child: _dateCard(
                                        context,
                                        dateStart,
                                        dateEnd,
                                        dateCreated,
                                        dateUpdated,
                                      ),
                                    ),
                                    description != null &&
                                            description!.isNotEmpty
                                        ? SizedBox(height: 20.h)
                                        : SizedBox.shrink(),
                                    description != null &&
                                            description!.isNotEmpty
                                        ? Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 18.w,
                                            ),
                                            child: _noteCard(),
                                          )
                                        : SizedBox.shrink(),
                                    users != null && users!.isNotEmpty
                                        ? SizedBox(height: 20.h)
                                        : SizedBox.shrink(),
                                    users != null && users!.isNotEmpty
                                        ? Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 18.w,
                                            ),
                                            child: _usersCard(context, users),
                                          )
                                        : SizedBox.shrink(),
                                    clients != null && clients!.isNotEmpty
                                        ? SizedBox(height: 20.h)
                                        : SizedBox.shrink(),
                                    clients != null && clients!.isNotEmpty
                                        ? Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 18.w,
                                            ),
                                            child:
                                                _clientsCard(context, clients),
                                          )
                                        : SizedBox.shrink(),
                                    if (widget.type == 'request') ...[
                                      Divider(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.dividerClrChange,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 18.w,
                                        ),
                                        child: _requestInfoCard(
                                          context,
                                          task,
                                        ),
                                      ),
                                    ],
                                    if (widget.type != 'request') ...[
                                      Divider(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.dividerClrChange,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 18.w,
                                        ),
                                        child: _taskCard(
                                          context,
                                          task,
                                          isCreateTask,
                                          isLoadingTask,
                                        ),
                                      ),
                                      SizedBox(height: 15.h),
                                      Divider(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.dividerClrChange,
                                      ),
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: _completeInspection,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            minimumSize: Size(120.w, 32.h),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 24.w),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                            ),
                                          ),
                                          child: Text(
                                            'Complete',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 15.h),
                                      SizedBox(height: 50.h),
                                    ]
                                  ],
                                );
                              }
                              if (state is InspectionidLoading) {
                                return Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 18.w),
                                  child: Column(
                                    children: [
                                      shimmerDetails(
                                          isLightTheme, context, 150.h),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                          isLightTheme, context, 150.h),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                          isLightTheme, context, 50.h),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                          isLightTheme, context, 120.h),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                          isLightTheme, context, 120.h),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                );
                              }
                              if (state is InspectionidInitial) {
                                return Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 18.w),
                                  child: Column(
                                    children: [
                                      shimmerDetails(
                                          isLightTheme, context, 150.h),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                          isLightTheme, context, 150.h),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                          isLightTheme, context, 50.h),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                          isLightTheme, context, 120.h),
                                      const SizedBox(height: 20),
                                      shimmerDetails(
                                          isLightTheme, context, 120.h),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                );
                              }
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18.w),
                                child: Column(
                                  children: [
                                    shimmerDetails(
                                        isLightTheme, context, 150.h),
                                    const SizedBox(height: 20),
                                    shimmerDetails(
                                        isLightTheme, context, 150.h),
                                    const SizedBox(height: 20),
                                    shimmerDetails(isLightTheme, context, 50.h),
                                    const SizedBox(height: 20),
                                    shimmerDetails(
                                        isLightTheme, context, 120.h),
                                    const SizedBox(height: 20),
                                    shimmerDetails(
                                        isLightTheme, context, 120.h),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            BackBar(
              rightOffset: _isSidebarOpen ? 52.w : 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menubttn(worktype) {
    if (worktype == 'completed') {
      return detailMenu(
        isChat: role != "Client" || widget.workModel.clientCanDiscuss == 1,
        onpressChat: () {
          _key.currentState?.toggle();
          router.push(
            "/commentsection",
            extra: {
              "id": widget.id,
              "title": widget.workModel.title,
              "isProject": true,
              "model": "inspectioncomment",
            },
          );
          context.read<CommentsBloc>().isProject = true;
        },
        isDiscuss: true,
        isEdit: false,
        isDelete: false,
        key: _key,
        context: context,
        onpressEdit: false,
        onpressDelete: false,
        onpressdiscuss: () {
          if (kDebugMode) {
            logger.d(' Navigating to  with type: $workType');
          }
          _key.currentState?.toggle();
          router.push(
            "/inspectionDiscussionTabs",
            extra: {
              "isDetail": true,
              "id": widget.id,
              "type": workType,
            },
          );
        },
      );
    } else {
      return detailMenu(
        isChat: role != "Client" || widget.workModel.clientCanDiscuss == 1,
        onpressChat: () {
          _key.currentState?.toggle();
          router.push(
            "/commentsection",
            extra: {
              "id": widget.id,
              "title": widget.workModel.title,
              "isProject": true,
              "model": "inspectioncomment",
            },
          );
          context.read<CommentsBloc>().isProject = true;
        },
        isDiscuss: true,
        isEdit: context.read<PermissionsBloc>().iseditInspection,
        isDelete: context.read<PermissionsBloc>().isdeleteInspection,
        key: _key,
        context: context,
        onpressEdit: () {
          _onEditInspection();
          // Navigator.pop(context);
        },
        onpressDelete: () {
          showDialog(
            context: context,
            builder: (context) {
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
                content: Text(AppLocalizations.of(context)!.areyousure),
                actions: [
                  TextButton(
                    onPressed: () {
                      _onDeleteInspection(widget.id);
                    },
                    child: Text(AppLocalizations.of(context)!.delete),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(false); // Cancel deletion
                    },
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ],
              );
            },
          );
        },
        onpressdiscuss: () {
          if (kDebugMode) {
            logger.d(' Navigating to  with type: $workType');
          }
          _key.currentState?.toggle();
          router.push(
            "/inspectionDiscussionTabs",
            extra: {"isDetail": true, "id": widget.id, "type": workType},
          );
        },
      );
    }
  }

  Widget _noteCard() {
    return customContainer(
      width: double.infinity,
      context: context,
      addWidget: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: "${AppLocalizations.of(context)!.note}  ",
              size: 12.sp,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.textClrChange,
            ),
            SizedBox(height: 10.w),
            CustomText(
              text: description ?? "",
              size: 14.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.textClrChange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _workCard(int? action_status, BuildContext context) {
    return customContainer(
      context: context,
      addWidget: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            statusActionRowInt(action_status ?? 0, context,
                detailPage: true, workId: widget.id.toString()),
            CustomText(
              text: title ?? "",
              fontWeight: FontWeight.w700,
              size: 18.sp,
              color: Theme.of(context).colorScheme.textClrChange,
            ),
            budget != null ? SizedBox(height: 10.h) : SizedBox(),
            budget != null
                ? ExpandableHtmlNoteWidget(
                    text: " ${budget.toString()} %",
                    context: context,
                  )
                : SizedBox(),
            SizedBox(height: 10.h),

            // ✅ statusClientRow болон More button (actionMenu шиг)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and Priority
                Flexible(
                  flex: 3,
                  child: statusClientRow(
                    status,
                    priority,
                    context,
                    true,
                  ),
                ),

                SizedBox(width: 10.w),

                // ✅ More Action Button
                // Padding(
                //   padding: EdgeInsets.only(
                //       top: 22.h), // ✅ Дээрээс 15.h padding нэмэх
                //   child: MoreStatusButton(
                //     context: context,
                //     itemId: widget.id,
                //     itemTitle: widget.workModel.title,
                //     isProject: true,
                //     isSmall: true,
                //     clientCanDiscuss: widget.workModel.clientCanDiscuss,
                //     role: role,
                //     onStatusChanged: (newStatusId, newStatusText) {
                //       // ✅ Status солих confirmation dialog
                //       showDialog(
                //         context: context,
                //         builder: (dialogContext) {
                //           return AlertDialog(
                //             shape: RoundedRectangleBorder(
                //               borderRadius: BorderRadius.circular(10.r),
                //             ),
                //             backgroundColor: Theme.of(context)
                //                 .colorScheme
                //                 .alertBoxBackGroundColor,
                //             title: Text(
                //               AppLocalizations.of(context)!.status,
                //             ),
                //             content: Text(
                //               'Change status to "$newStatusText"?',
                //             ),
                //             actions: [
                //               TextButton(
                //                 onPressed: () {
                //                   Navigator.of(dialogContext).pop();
                //                   // ✅ Status update хийх
                //                   BlocProvider.of<InspectionBloc>(context).add(
                //                     UpdateInspection(
                //                       id: widget.id!,
                //                       title: title ?? '',
                //                       statusId: newStatusId,
                //                     ),
                //                   );

                //                   // ✅ Refresh
                //                   _onRefresh();

                //                   flutterToastCustom(
                //                     msg: 'Status updated to $newStatusText',
                //                     color: AppColors.primary,
                //                   );
                //                 },
                //                 child: Text(
                //                   AppLocalizations.of(context)!.approve,
                //                   style: TextStyle(color: AppColors.primary),
                //                 ),
                //               ),
                //               TextButton(
                //                 onPressed: () {
                //                   Navigator.of(dialogContext).pop();
                //                 },
                //                 child: Text(
                //                   AppLocalizations.of(context)!.cancel,
                //                 ),
                //               ),
                //             ],
                //           );
                //         },
                //       );
                //     },
                //   ),
                // ),
              ],
            ),

            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _assetCard(Object? asset, context) {
    return customContainer(
      width: 600.w,
      context: context,
      addWidget: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: "${AppLocalizations.of(context)!.equipment}: ",
                  size: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.textClrChange,
                ),
                CustomText(
                  text: (asset is Map && asset['asset_code'] != null)
                      ? asset['asset_code']
                      : "?",
                  size: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.textClrChange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _assignedTo({
    required String label,
    required String title,
    required String email,
    required String name,
    required String image,
  }) {
    return customContainer(
      width: 600.w,
      context: context,
      addWidget: SizedBox(
        // width: iswidth == true ? 290 : 140.w,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: label,
                color: Theme.of(context).colorScheme.textClrChange,
                size: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: image != "" || image != null
                          ? NetworkImage('${activePictureUrl}/${image}')
                          : null,
                      radius: 18.r, // Size of the profile image
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: title,
                          color: Theme.of(context).colorScheme.textClrChange,
                          size: 12.sp,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w400,
                        ),
                        CustomText(
                          text: email,
                          color: Theme.of(context).colorScheme.textClrChange,
                          size: 12.sp,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _budgetAndTaskAccess(context) {
    return customContainer(
      width: 600.w,
      context: context,
      addWidget: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: "${AppLocalizations.of(context)!.budget}:  ",
                  size: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.textClrChange,
                ),
                // SizedBox(width: 50.w,),
                budget != null && budget != ""
                    ? currencyPosition == "before"
                        ? CustomText(
                            text: "$currency$budget",
                            size: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.textClrChange,
                          )
                        : CustomText(
                            text: " $budget$currency",
                            size: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.textClrChange,
                          )
                    : CustomText(
                        text: "-",
                        size: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
              ],
            ),
            taskAccess != null ? SizedBox(height: 10.h) : SizedBox(),
            taskAccess != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text:
                            "${AppLocalizations.of(context)!.taskaccessibility}  ",
                        size: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                      // SizedBox(width: 50.w,),
                      CustomText(
                        text: "$taskAccess",
                        size: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                    ],
                  )
                : SizedBox.shrink(),

            // users != null && users.isNotEmpty
            //     ? SizedBox(
            //         height: 20.h,
            //       )
            //     : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _dateCard(context, String? dateStart, String? dateEnd,
      String? dateCreated, String? dateUpdated) {
    return customContainer(
      width: 600.w,
      context: context,
      addWidget: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        child: Column(
          children: [
            // ✅ Start date - check if not null and not empty
            if (dateStart != null && dateStart.isNotEmpty) ...[
              Row(
                children: [
                  CustomText(
                    text: "${AppLocalizations.of(context)!.startdate}: ",
                    size: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.textClrChange,
                  ),
                  CustomText(
                    text: dateStart,
                    size: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.textClrChange,
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],

            // ✅ End date - check if not null and not empty
            if (dateEnd != null && dateEnd.isNotEmpty) ...[
              Row(
                children: [
                  CustomText(
                    text: "${AppLocalizations.of(context)!.duedate}: ",
                    size: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.textClrChange,
                  ),
                  CustomText(
                    text: dateEnd,
                    size: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.textClrChange,
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],

            // ✅ Created date - check if not null and not empty
            if (dateCreated != null && dateCreated.isNotEmpty) ...[
              Row(
                children: [
                  CustomText(
                    text: "${AppLocalizations.of(context)!.createdat}: ",
                    size: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.textClrChange,
                  ),
                  CustomText(
                    text: dateCreated,
                    size: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.textClrChange,
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],

            // ✅ Updated date - check if not null and not empty
            if (dateUpdated != null && dateUpdated.isNotEmpty) ...[
              Row(
                children: [
                  CustomText(
                    text: "${AppLocalizations.of(context)!.completedAt}: ",
                    size: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.textClrChange,
                  ),
                  CustomText(
                    text: dateUpdated,
                    size: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.textClrChange,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _usersCard(context, users) {
    // for (var user in users ?? []) {
    //   print('User: ${user.toJson()}');
    // }

    return InkWell(
      onTap: () {
        userClientDialog(
          context: context,
          title: AppLocalizations.of(context)!.allusers,
          list: users!.isEmpty ? [] : users,
          from: 'user',
        );
      },
      child: customContainer(
        context: context,
        addWidget: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
          child: UserClientRowDetailPage(
            list: users!.isEmpty ? [] : users,
            title: AppLocalizations.of(context)!.users,
          ),
        ),
      ),
    );
  }

  Widget _clientsCard(context, clients) {
    return InkWell(
      onTap: () {
        userClientDialog(
          from: "client",
          context: context,
          title: AppLocalizations.of(context)!.allclients,
          list: clients!.isEmpty ? [] : clients,
        );
      },
      child: customContainer(
        context: context,
        addWidget: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
          child: UserClientRowDetailPage(
            list: clients!,
            title: AppLocalizations.of(context)!.clients,
          ),
        ),
      ),
    );
  }

  Widget _requestInfoCard(context, List<InspectionTasks> tasks) {
    String? requestInfo;

    for (int i = 0; i < tasks.length; i++) {
      if (tasks[i].requestInfo != null && tasks[i].requestInfo!.isNotEmpty) {
        requestInfo = tasks[i].requestInfo;
        break; // ✅ Эхний олдсон request_info-г авна
      }
    }
    if (requestInfo == null || requestInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    return customContainer(
      width: 600.w,
      context: context,
      addWidget: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Title
            Row(
              children: [
                HeroIcon(
                  HeroIcons.documentText,
                  style: HeroIconStyle.solid,
                  size: 16.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8.w),
                CustomText(
                  text: "Хүсэлтийн мэдээлэл",
                  size: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.textClrChange,
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // ✅ HTML content
            // ✅ Divider
            Container(
              height: 1,
              color: Theme.of(context)
                  .colorScheme
                  .dividerClrChange
                  .withValues(alpha: 0.3),
            ),

            SizedBox(height: 12.h),

            // ✅ Request info content
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ExpandableHtmlNoteWidget(
                text: requestInfo,
                context: context,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskCard(context, task, isCreateTask, isLoadingTask) {
    return Column(
      children: [
        // Complete button at top of tasks

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: AppLocalizations.of(context)!.tasks,
              size: 16.sp,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.textClrChange,
            ),
          ],
        ),
        SizedBox(height: 10.h),
        isLoadingTask == false
            ? task.isNotEmpty
                ? _buildNestedTaskList(task, 0) // ← Recursive widget дуудах
                : customContainer(
                    width: 400.w,
                    context: context,
                    addWidget: Padding(
                      padding: EdgeInsets.all(18.w),
                      child: NoData(isImage: true),
                    ),
                  )
            : const NotesShimmer(),
      ],
    );
  }

  // ✅ Helper функц: Бүх task-уудыг recursive хэвлэх
  void _printAllTasks(List<InspectionTasks> tasks, int level) {
    for (var task in tasks) {
      String indent = '  ' * level; // Indent өгөх
      if (kDebugMode) {
        logger.d('$indent├─ Task ID: ${task.id}, Title: ${task.title}');
      }

      if (task.children != null && task.children!.isNotEmpty) {
        _printAllTasks(task.children!.cast<InspectionTasks>(),
            level + 1); // Recursive дуудалт
      }
    }
  }

  // ✅ Recursive task list builder
  Widget _buildNestedTaskList(List<InspectionTasks> tasks, int level) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final hasChildren = task.children != null && task.children!.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parent task
            Padding(
              padding: EdgeInsets.only(left: (level * 15.0).w), // Indent өгөх
              child: InkWell(
                onTap: () async {
                  final result = await router.push(
                    '/inspectiontaskdetail',
                    extra: {
                      "id": task.id,
                      "work_order": task.projectId,
                    },
                  );

                  // ✅ Result true бол refresh хийх
                  if (result == true) {
                    _onRefresh();
                  }
                },
                child: task.template_type == 7
                    ? TaskInputListDetails(
                        // ✅ template_type == 7 үед input-тай component
                        id: task.id,
                        startDate: task.startDate,
                        endDate: task.dueDate,
                        clientList: [],
                        userList: [],
                        addSubTask: false,
                        title: task.title ?? '',
                        workType: workType ?? '',
                        value: task.taskValue ?? '', // ✅ Input утга
                        isEditable:
                            true, // ✅ TODO: Add team leader check if needed
                        onTap: () async {
                          if (kDebugMode) {
                            logger.d(' Tapping task ID: ${task.projectId}');
                          }

                          final result = await router.push(
                            '/inspectiontaskdetail',
                            extra: {
                              "id": task.id,
                              "work_order": task.projectId,
                            },
                          );

                          if (result == true ||
                              result == 1 ||
                              result == "true") {
                            _onRefresh();
                          }
                        },
                        onValueChanged: (newValue) {
                          // ✅ Input өөрчлөгдөхөд backend-руу update илгээх
                          logger.d(
                              '🔥 [inspection_details] Task ${task.id} value changed: $newValue');
                          _updateTaskValue(task.id, newValue);
                        },
                        onCreateSubTask: () {
                          if (kDebugMode) {
                            logger.d('onCreateSubTask, refreshing...');
                          }
                          // _createSubTask(task.id);
                        },
                      )
                    : TaskCheckListDetails(
                        id: task.id,
                        startDate: task.startDate,
                        endDate: task.dueDate,
                        clientList: [],
                        userList: [],
                        workType: workType ?? '',
                        addSubTask: false,
                        title: task.title ?? '',
                        isEditable:
                            true, // ✅ TODO: Add team leader check if needed
                        isCompleted:
                            task.taskValue != '0' && task.taskValue != null
                                ? true
                                : false, // ✅ Backend-аас ирэх утга
                        onTap: () async {
                          final result = await router.push(
                            '/inspectiontaskdetail',
                            extra: {
                              "id": task.id,
                              "work_order": task.projectId
                            },
                          );

                          if (result == true ||
                              result == 1 ||
                              result == "true") {
                            _onRefresh();
                          }
                        },
                        onCheckChanged: (isChecked) {
                          // ✅ Checkbox өөрчлөгдөхөд backend-руу update илгээх
                          _updateTaskCompletion(task.id, isChecked);
                        },
                        onCreateSubTask: () {
                          // _createSubTask(task.id);
                        },
                      ),
              ),
            ),

            // Children tasks (recursive)
            if (hasChildren)
              _buildNestedTaskList(
                task.children is List<InspectionTasks>
                    ? task.children as List<InspectionTasks>
                    : (task.children as List)
                        .map((e) => e as InspectionTasks)
                        .toList(),
                level + 1,
              ),
          ],
        );
      },
    );
  }

  // ✅ Helper function to calculate and update work order percentage
  Future<void> _updateWorkOrderPercent() async {
    try {
      // ✅ Fetch fresh task list from backend to avoid stale data
      Map<String, dynamic> result = await InspectionTaskRepo().getTask(
        token: true,
        projectId: [widget.id!],
        limit: -1,
      );

      // ✅ Build task tree
      List<InspectionTasks> allTasks = List<InspectionTasks>.from(
        result['data'].map((workData) => InspectionTasks.fromJson(workData)),
      );
      List<InspectionTasks> freshTaskTree = _buildTaskTree(allTasks);

      if (freshTaskTree.isEmpty) {
        return;
      }

      // ✅ Count total and completed tasks (recursively)
      // Only count checkbox (type 5) and input field (type 7) tasks
      int totalTasks = 0;
      int completedTasks = 0;

      void countTasks(List<InspectionTasks> tasks) {
        for (var t in tasks) {
          // ✅ Only count checkbox (5) and input field (7) tasks
          if (t.template_type == 5 || t.template_type == 7) {
            totalTasks++;
            // ✅ Task completed: value is "1" for checkbox, or not null/empty for input
            if (t.taskValue == '1' ||
                (t.taskValue != null &&
                    t.taskValue!.isNotEmpty &&
                    t.taskValue != '0')) {
              completedTasks++;
            }
          }
          // ✅ Recursively check children regardless of parent type
          if (t.children != null && t.children!.isNotEmpty) {
            countTasks(t.children!.cast<InspectionTasks>());
          }
        }
      }

      countTasks(freshTaskTree);

      // ✅ Calculate percentage
      double percentage =
          totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;
      String woPercent = percentage.toStringAsFixed(2);

      // ✅ Update work order
      await InspectionRepo().updateWorkOrderPercent(
        workOrderId: widget.id!,
        woPercent: woPercent,
      );
      if (kDebugMode) {
        logger.d(
            '🔥 [inspection_details] Work order percent updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        logger
            .d('🔥 [inspection_details] Error updating work order percent: $e');
      }
    }
  }

  // ✅ Task value update хийх функц (debounced)
  void _updateTaskValue(int? taskId, String newValue) {
    if (taskId == null) return;

    // ✅ Өмнөх timer-ийг цуцлах
    _debounceTimer?.cancel();

    // ✅ Pending update-ийг хадгалах
    _pendingUpdates[taskId] = newValue;

    // ✅ Local state update (UI дээр шууд харуулах)
    _updateTaskInLocalState(taskId, newValue);

    // ✅ 2 секунд хүлээгээд API request илгээх
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      if (_pendingUpdates.containsKey(taskId)) {
        final valueToSend = _pendingUpdates[taskId]!;

        // Backend-руу PATCH request илгээх
        BlocProvider.of<InspectionTaskidBloc>(context).add(
          UpdateTaskCompletion(taskId: taskId, value: valueToSend),
        );

        // ✅ Pending update-ийг устгах
        _pendingUpdates.remove(taskId);

        // ✅ Wait for backend to process, then update wo_percent only
        await Future.delayed(const Duration(milliseconds: 500));
        await _updateWorkOrderPercent();
      }
    });
  }

  void _updateTaskCompletion(int? taskId, bool isCompleted) async {
    if (taskId == null) return;

    // ✅ Local state update (UI дээр шууд харуулах)
    _updateTaskInLocalState(taskId, isCompleted ? '1' : '0');

    // Backend-руу PATCH request илгээх
    BlocProvider.of<InspectionTaskidBloc>(context).add(
      UpdateTaskCompletion(
        taskId: taskId,
        value: isCompleted ? '1' : '0',
      ),
    );

    // ✅ Wait for backend to process, then update wo_percent only
    await Future.delayed(const Duration(milliseconds: 500));
    await _updateWorkOrderPercent();
  }

  // ✅ Helper function: Update task value in local state without refetching entire list
  void _updateTaskInLocalState(int taskId, String newValue) {
    bool updated = false;

    // Recursive function to find and update task
    void updateTaskRecursive(List<InspectionTasks> tasks) {
      for (var t in tasks) {
        if (t.id == taskId) {
          t.taskValue = newValue;
          updated = true;
          break;
        }
        // Check children recursively
        if (t.children != null && t.children!.isNotEmpty) {
          updateTaskRecursive(t.children!.cast<InspectionTasks>());
        }
        if (updated) break;
      }
    }

    updateTaskRecursive(task);

    if (updated) {
      setState(() {
        // Trigger rebuild with updated task value
      });
    }
  }

  @override
  void dispose() {
    // ✅ Timer-ийг цуцлах
    _debounceTimer?.cancel();

    // ✅ Хэрэв pending updates байгаа бол шууд backend руу явуулах
    if (_pendingUpdates.isNotEmpty) {
      // Send all pending updates immediately
      _pendingUpdates.forEach((taskId, value) {
        InspectionTaskRepo()
            .updateTaskCompletion(
          taskId: taskId!,
          value: value,
        )
            .catchError((e) {
          logger.d(
              '🔥 [inspection_details] Error sending pending update on dispose: $e');
        });
      });
    }

    super.dispose();
  }
}
