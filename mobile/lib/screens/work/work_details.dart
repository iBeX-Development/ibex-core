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
import 'package:ibex/utils/user_id_mapper.dart';
import '../../bloc/auth/auth_bloc.dart';

import '../../bloc/comments/comments_bloc.dart';

import '../../bloc/work/work_event.dart';
import '../../bloc/work/work_state.dart';
import '../../bloc/work/work_bloc.dart';
import '../../bloc/work_discussion/work_milestone_filter/work_milestone_filter_bloc.dart';
import '../../bloc/work_discussion/work_milestone_filter/work_milestone_filter_event.dart';
import '../../bloc/work_id/workid_bloc.dart';
import '../../bloc/work_id/workid_event.dart';
import '../../bloc/work_id/workid_state.dart';
import '../../bloc/setting/settings_bloc.dart';

import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';

import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../data/localStorage/hive.dart';
import '../../data/model/Work/all_work.dart';
import '../../data/model/worktask/task_model.dart';
import '../../data/repositories/Worktask/task_repo.dart';
import '../../data/repositories/work/work_repo.dart';
import '../../data/repositories/workspace/workspace_repo.dart';
import '../../routes/routes.dart';
import '../../utils/widgets/status_priority_row.dart';
import '../../utils/widgets/toast_widget.dart';
import '../../utils/widgets/user_client_row_detail_page.dart';
// import '../../utils/widgets/check_with_task_details.dart';
import '../../utils/widgets/task_with_check.dart';
import '../../utils/widgets/task_with_input.dart';

import '../../utils/widgets/user_team_row_detail_page.dart';
import '../dash_board/dashboard.dart';
import '../notes/widgets/notes_shimmer_widget.dart';
import '../task/Widget/users_field.dart';
import '../widgets/back_bar.dart';
import '../widgets/custom_container.dart';
import '../widgets/detail_page_menu.dart';
import '../widgets/html_widget.dart';
import '../widgets/no_data.dart';
import '../widgets/side_bar.dart';
import '../widgets/status_page_menu.dart';
import '../widgets/user_client_box.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import '../../utils/widgets/status_action_row.dart';
import '../home_screen/home_widgets/drawer_widgets.dart';
import '../widgets/custom_app_bar.dart';
import 'package:logger/logger.dart';

final logger = Logger();
class WorkDetails extends StatefulWidget {
  final int? id;
  final bool? fromNoti;
  final int? team_id;
  final String? from;
  final String? type;
  final WorkModel workModel;
  final String? autoNumber;

  const WorkDetails({
    super.key,
    this.id,
    this.fromNoti,
    this.from,
    this.type,
    this.team_id,
    this.autoNumber,
    required this.workModel,
  });

  @override
  State<WorkDetails> createState() => _WorkDetailsState();
}

class _WorkDetailsState extends State<WorkDetails> {
  // List of items in our dropdown menu

  // Function to handle checkbox state change
  List<int> userId = [];
  List<int> assetId = [];
  List<WorkUsers>? users;
  List<WorkUsers>? task_users;
  int? teamId; // ✅ Store team ID to prevent recalculation
  bool isTeamLeader = false; // ✅ Check if current user is team leader
  bool isAssignedToWorkOrder =
      false; // ✅ Check if user is assigned to this work order
  List<int>? usersIds = [];
  List<int>? clientIds = [];
  List<Tag>? tags = [];
  List<int>? tagIds = [];
  List<WorkClients>? clients;
  List<String>? clientList;
  List<String>? userList;
  List<int> clientId = [];
  List<String>? tagList;
  String? statusFrom;
  String? priority;

  // Helper method to validate UUID format
  bool _isValidUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    // UUID format: 8-4-4-4-12 hex characters
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

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
  List<WorkTasks> task = [];
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
  bool _isSidebarOpen = false; // Track sidebar open/close state
  List<String>? usersName;
  List<int>? selectedusersNameId;

  Map<String, dynamic>? assigned_to;
  bool isLoadingTask = false;
  WorkModel? model;
  List<WorkModel> work = [];
  final _key = GlobalKey<ExpandableFabState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Add ScrollController
  bool isExpand = false;

  void toggleDrawer(bool expanded) {
    setState(() {
      isExpand = expanded;
    });
  }

  // ✅ Debounce timer болон pending updates
  Timer? _debounceTimer;
  final Map<int?, String> _pendingUpdates = {};

  // ✅ Check if current user is team leader
  Future<void> _checkTeamLeaderPermission() async {
    try {
      // Get current user's UUID
      int myIntId = await HiveStorage.getUserId();
      String myUuid = UserIdMapper().convertIntsToUuids([myIntId]).first;

      // ✅ Always recalculate teamId to avoid using stale data
      int? currentTeamId;

      // Try widget.team_id first
      if (widget.team_id != null) {
        currentTeamId = widget.team_id;
      } else {
        // Get assigned team ID from users list (teams have team_name)
        final teamUser = users?.firstWhere(
          (u) => u.team_name != null,
          orElse: () => WorkUsers(),
        );

        if (teamUser?.id != null) {
          currentTeamId = teamUser!.id!;
        }
      }

      // Store for this work order
      teamId = currentTeamId;

      if (currentTeamId != null) {
        // Check if current user is in team leaders
        final result = await WorkRepo().getTeamLeader(
          users_id: [myUuid],
          teams_id: currentTeamId,
        );

        setState(() {
          if (result['error'] == true) {
            isTeamLeader = false;
          } else if (result['data'] != null) {
            final teamLeadersList = result['data'] as List;
            isTeamLeader = teamLeadersList.isNotEmpty;
          } else {
            isTeamLeader = false;
          }
        });
      } else {
        setState(() {
          isTeamLeader = false;
        });
      }
    } catch (e) {
      setState(() {
        isTeamLeader = false;
      });
    }
  }

  Future<void> _getUsersForWorkOrder() async {
    try {
      // ✅ Get current user's UUID to check assignment
      int myIntId = await HiveStorage.getUserId();
      String myUuid = UserIdMapper().convertIntsToUuids([myIntId]).first;

      // ✅ Fetch users from work order
      final result =
          await WorkRepo().getUsersToWorkOrder(workOrderId: widget.id!);

      // ✅ Fetch teams from workspace (teams associated with this work order)
      // final teamsResult = await WorkRepo().getTeamsForWorkOrder(
      //   workOrderId: widget.id!,
      // );

      setState(() {
        List<WorkUsers> fetchedUsers = [];
        bool foundMyUser = false; // ✅ Track if current user is in the list

        // ✅ Process users
        if (result['error'] != true && result['data'] != null) {
          final usersList = result['data'] as List;

          fetchedUsers = usersList
              .map((item) {
                // Extract user_id object from the work_order_users item
                final userIdData = item['user_id'];
                if (userIdData != null) {
                  // ✅ Check if this is the current user
                  if (userIdData['id'] == myUuid) {
                    foundMyUser = true;
                  }

                  return WorkUsers(
                    id: userIdData['id'] is String
                        ? UserIdMapper()
                            .convertUuidsToInts([userIdData['id']]).first
                        : userIdData['id'],
                    firstName: userIdData['first_name'] ?? '',
                    lastName: userIdData['last_name'] ?? '',
                    email: userIdData['email'] ?? '',
                    photo: userIdData['avatar'] ?? '',
                  );
                }
                return null;
              })
              .whereType<WorkUsers>()
              .toList();

          // ✅ Set isAssignedToWorkOrder based on whether we found current user
          isAssignedToWorkOrder = foundMyUser;
        }

        // ✅ Process teams
        // if (teamsResult['error'] != true && teamsResult['data'] != null) {
        //   final teamsList = teamsResult['data'] as List;

        //   final teamsAsUsers = teamsList
        //       .map((item) {
        //         // Teams have team_name field
        //         if (item['id'] != null && item['name'] != null) {
        //           return WorkUsers(
        //             id: item['id'],
        //             firstName: '', // Teams don't have first/last name
        //             lastName: '',
        //             email: item['email'] ?? '',
        //             photo: item['avatar'],
        //             team_name: item['name'], // ✅ Set team_name
        //           );
        //         }
        //         return null;
        //       })
        //       .whereType<WorkUsers>()
        //       .toList();

        //   fetchedUsers.addAll(teamsAsUsers);
        // }

        task_users = fetchedUsers;

        // ✅ Merge task_users into users (avoid duplicates)
        if (users == null) {
          users = task_users;
        } else if (task_users != null) {
          final existingIds = users!.map((u) => u.id).toSet();
          final newUsers =
              task_users!.where((u) => !existingIds.contains(u.id)).toList();
          users!.addAll(newUsers);
        }
      });

      // ✅ Check team leader permission after fetching users
      await _checkTeamLeaderPermission();
    } catch (e) {
      // Error fetching users
    }
  }

  _getTask() async {
    setState(() {
      isLoadingTask = true;
    });
    Map<String, dynamic> result = await WorkTaskRepo()
        .getTask(token: true, projectId: [widget.id!], limit: -1);

    // ✅ 1. Эхлээд бүх task-уудыг flat list болгож авах
    List<WorkTasks> allTasks = List<WorkTasks>.from(
      result['data'].map((workData) => WorkTasks.fromJson(workData)),
    );

    // ✅ 2. Flat array-ийг nested tree болгох
    task = _buildTaskTree(allTasks);

    // _printAllTasks(task, 0); // Recursive хэвлэх функц дуудалт
    setState(() {
      isLoadingTask = false;
    });
  }

  // ✅ Flat array-ийг nested tree болгох helper функц
  List<WorkTasks> _buildTaskTree(List<WorkTasks> flatList) {
    // Task ID-аар Map үүсгэх (хурдан хайлт хийхийн тулд)
    Map<int, WorkTasks> taskMap = {};
    for (var task in flatList) {
      if (task.id != null) {
        taskMap[task.id!] = task;
        task.children = []; // Children-ийг анх хоослох
      }
    }

    // Root tasks (parent == null) болон children-ийг холбох
    List<WorkTasks> rootTasks = [];

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

  void _onDeleteWork(projectId) {
    final setting = context.read<WorkBloc>();
    BlocProvider.of<WorkBloc>(context).add(DeleteWork(projectId));
    setting.stream.listen((state) {
      if (state is WorkDeleteSuccess) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            CupertinoPageRoute(
              builder: (context) => const DashBoard(initialIndex: 1),
            ),
            (route) {
              return route is! CupertinoPageRoute ||
                  route.settings.name != 'WorkDetails';
            },
          );

          flutterToastCustom(
            msg: AppLocalizations.of(context)!.deletedsuccessfully,
            color: AppColors.primary,
          );
        }
      }
      if (state is WorkDeleteError) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            CupertinoPageRoute(
              builder: (context) => const DashBoard(initialIndex: 1),
            ),
            (route) {
              return route is! CupertinoPageRoute ||
                  route.settings.name != 'WorkDetails';
            },
          );

          flutterToastCustom(msg: state.errorMessage);
        }
      }
      if (state is WorkDeleteError) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            CupertinoPageRoute(
              builder: (context) => const DashBoard(initialIndex: 1),
            ),
            (route) {
              return route is! CupertinoPageRoute ||
                  route.settings.name != 'WorkDetails';
            },
          );

          flutterToastCustom(msg: state.errorMessage);
        }
      }
    });
  }

  void _onEditWork() {
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

    context.read<PermissionsBloc>().iseditWork == true
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

  @override
  void initState() {
    // ✅ Reset teamId when entering new work order details
    teamId = null;
    hasGuard = context.read<AuthBloc>().guard;
    // _getRole();
    _getTask();
    _getUsersForWorkOrder();

    workType = widget.type ?? 'open';

    currency = context.read<SettingsBloc>().currencySymbol;
    currencyPosition = context.read<SettingsBloc>().currencyPosition;
    context.read<WorkFilterCountOfMilestoneBloc>().add(
          WorkResetFilterCountOfMilestone(),
        );
    BlocProvider.of<WorkidBloc>(context).add(WorkIdListId(widget.id));
    super.initState();
  }

  Future<void> _getRole() async {
    role = await HiveStorage.getRole();
  }

  Future<void> _onRefresh() async {
    // ✅ Reset teamId on refresh to get fresh data
    teamId = null;
    _getTask();
    _getUsersForWorkOrder();

    BlocProvider.of<WorkidBloc>(context).add(WorkIdListId(widget.id));
  }

  final SlidableBarController controller = SlidableBarController(
    initialStatus: false,
  );

  @override
  Widget build(BuildContext context) {
    bool isCreateTask = context.read<PermissionsBloc>().iscreatetask ?? false;
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;

    bool isLightTheme = currentTheme is LightThemeState;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return; // ✅ Already popped, don't pop again

        if (widget.from == "fav") {
          router.pop();
          BlocProvider.of<WorkBloc>(context)
              .add(WorkDashBoardFavList(isFav: 1));
        } else if (widget.from == "dashboard") {
          router.pop();
        } else {
          router.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).colorScheme.backGroundColor,
        drawer: DrawerWidgets(
          isExpand: isExpand,
          toggleDrawer: toggleDrawer,
        ),
        floatingActionButtonLocation: ExpandableFab.location,
        floatingActionButton:
            (context.read<PermissionsBloc>().isdeleteWork == true ||
                    context.read<PermissionsBloc>().iseditWork == true)
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
                onSideBarToggle: (isOpen) {
                  setState(() {
                    _isSidebarOpen = isOpen;
                  });
                },
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
                            title: AppLocalizations.of(context)!.workdetails,
                            onMenuPressed: () {
                              setState(() {
                                isExpand = false;
                              });
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                          const SizedBox(height: 10),
                          BlocConsumer<WorkidBloc, WorkidState>(
                            listener: (context, state) {
                              if (state is WorkDeleteSuccess) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        const DashBoard(initialIndex: 1),
                                  ),
                                  (route) {
                                    return route is! CupertinoPageRoute ||
                                        route.settings.name != 'WorkDetails';
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
                              if (state is WorkidWithId) {
                                for (var item in state.work) {
                                  title = item.title;
                                  status = item.status;
                                  statusIds = item.statusId; //int
                                  priority = item.priority;
                                  priorityId = item.priorityId;
                                  // ✅ Rebuild users list from task_users + BLoC teams (prevent duplicates)
                                  if (item.users != null &&
                                      item.users!.isNotEmpty) {
                                    // Start fresh with task_users (from API)
                                    List<WorkUsers> combinedUsers =
                                        task_users != null
                                            ? List.from(task_users!)
                                            : [];

                                    // Get existing IDs and team names
                                    final existingIds =
                                        combinedUsers.map((u) => u.id).toSet();
                                    final existingTeamNames = combinedUsers
                                        .where((u) => u.team_name != null)
                                        .map((u) => u.team_name)
                                        .toSet();

                                    // Add only new teams from BLoC
                                    final newTeams = item.users!.where((u) {
                                      if (existingIds.contains(u.id))
                                        return false;
                                      if (u.team_name != null &&
                                          existingTeamNames.contains(
                                              u.team_name)) return false;
                                      return true;
                                    }).toList();

                                    combinedUsers.addAll(newTeams);
                                    users = combinedUsers;
                                  } else if (task_users != null) {
                                    // No BLoC teams, just use task_users
                                    users = List.from(task_users!);
                                  }
                                  usersIds = item.userId;
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
                              if (state is WorkidWithId) {
                                for (var item in state.work) {
                                  model = WorkModel(
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
                                  // ✅ Rebuild users list from task_users + BLoC teams (prevent duplicates)
                                  if (item.users != null &&
                                      item.users!.isNotEmpty) {
                                    // Start fresh with task_users (from API)
                                    List<WorkUsers> combinedUsers =
                                        task_users != null
                                            ? List.from(task_users!)
                                            : [];

                                    // Get existing IDs and team names
                                    final existingIds =
                                        combinedUsers.map((u) => u.id).toSet();
                                    final existingTeamNames = combinedUsers
                                        .where((u) => u.team_name != null)
                                        .map((u) => u.team_name)
                                        .toSet();

                                    // Add only new teams from BLoC
                                    final newTeams = item.users!.where((u) {
                                      if (existingIds.contains(u.id))
                                        return false;
                                      if (u.team_name != null &&
                                          existingTeamNames.contains(
                                              u.team_name)) return false;
                                      return true;
                                    }).toList();

                                    combinedUsers.addAll(newTeams);
                                    users = combinedUsers;
                                  } else if (task_users != null) {
                                    // No BLoC teams, just use task_users
                                    users = List.from(task_users!);
                                  }
                                  usersIds = item.userId ?? [];
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
                                    assigned_to != null
                                        ? SizedBox(height: 20.h)
                                        : SizedBox.shrink(),
                                    assigned_to != null
                                        ? Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 18.w,
                                            ),
                                            child: _assignedTo(
                                              label: AppLocalizations.of(
                                                context,
                                              )!
                                                  .assignedto,
                                              title: assigned_to?['role']
                                                      ?['name'] ??
                                                  '',
                                              email:
                                                  assigned_to?['email'] ?? '',
                                              name: assigned_to?['last_name'] ??
                                                  '',
                                              image:
                                                  assigned_to?['avatar'] ?? '',
                                            ),
                                          )
                                        : SizedBox.shrink(),
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
                                      SizedBox(height: 20.h),
                                      Divider(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.dividerClrChange,
                                      ),

                                      // ✅ Complete Button (хамгийн дээр)
                                      if (widget.type != 'request' &&
                                          widget.type != 'completed' &&
                                          (isTeamLeader ||
                                              isAssignedToWorkOrder))
                                        Center(
                                          child: Container(
                                            width: 150.w,
                                            margin:
                                                EdgeInsets.only(bottom: 10.h),
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                // ✅ Confirmation dialog
                                                showDialog(
                                                  context: context,
                                                  builder: (dialogContext) {
                                                    return AlertDialog(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10.r),
                                                      ),
                                                      backgroundColor: Theme.of(
                                                              context)
                                                          .colorScheme
                                                          .alertBoxBackGroundColor,
                                                      title: Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .status,
                                                      ),
                                                      content: Text(
                                                        'Mark work order as completed?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    dialogContext)
                                                                .pop();
                                                          },
                                                          child: Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .no,
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () async {
                                                            Navigator.of(
                                                                    dialogContext)
                                                                .pop();
                                                            // ✅ Update to completed status
                                                            try {
                                                              // Get completed status ID (usually 3)
                                                              final completedStatusId =
                                                                  3;

                                                              await WorkRepo()
                                                                  .updateWorkOrderStatus(
                                                                workOrderId:
                                                                    widget.id!,
                                                                statusId:
                                                                    completedStatusId,
                                                              );

                                                              // ✅ Refresh
                                                              _onRefresh();

                                                              flutterToastCustom(
                                                                msg:
                                                                    'Work order marked as completed',
                                                                color: AppColors
                                                                    .primary,
                                                              );
                                                            } catch (e) {
                                                              flutterToastCustom(
                                                                msg:
                                                                    'Failed to complete work order',
                                                              );
                                                            }
                                                          },
                                                          child: Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .yes,
                                                            style: TextStyle(
                                                                color: AppColors
                                                                    .primary),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 12.h),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.r),
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
                                        ),

                                      SizedBox(height: 50.h),
                                    ]
                                  ],
                                );
                              }
                              if (state is WorkidLoading) {
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
                              if (state is WorkidInitial) {
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
                hasGuard: hasGuard,
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
        isChat: false,
        onpressChat: () {
          _key.currentState?.toggle();
          // router.push(
          //   "/commentsection",
          //   extra: {
          //     "id": widget.id,
          //     "title": widget.workModel.title,
          //     "isProject": true,
          //   },
          // );
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
          _key.currentState?.toggle();
          router.push(
            "/workDiscussionTabs",
            extra: {"isDetail": true, "id": widget.id, "type": workType},
          );
        },
      );
    } else {
      return detailMenu(
        isChat: false,
        onpressChat: () {
          _key.currentState?.toggle();
          // router.push(
          //   "/commentsection",
          //   extra: {
          //     "id": widget.id,
          //     "title": widget.workModel.title,
          //     "isProject": false,
          //     "model": "workcomment",
          // },
          // );
          context.read<CommentsBloc>().isProject = true;
        },
        isDiscuss: true,
        isEdit: (context.read<PermissionsBloc>().iseditWork ?? false) &&
                isTeamLeader
            ? true
            : false,
        isDelete: (context.read<PermissionsBloc>().isdeleteWork ?? false) &&
                isTeamLeader
            ? true
            : false,
        key: _key,
        context: context,
        onpressEdit: () {
          _onEditWork();
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
                      _onDeleteWork(widget.id);
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
          _key.currentState?.toggle();
          router.push(
            "/workDiscussionTabs",
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

  /// workModel-аас work order дугаарыг гаргаж авна
  String _resolveWorkOrderNumber() {
    if (widget.autoNumber != null && widget.autoNumber!.isNotEmpty) {
      return widget.autoNumber!;
    }
    final m = widget.workModel;
    final ct = (m.createType ?? '').toLowerCase();
    final prefix = (m.wo_prefix ?? '').toUpperCase();
    if (prefix == 'REQ' || ct == 'request') {
      return '${(m.req_number ?? m.id ?? '').toString()}';
    } else if (prefix == 'PM' || ct == 'pm_generated') {
      return (m.wo_number ?? m.id ?? '').toString();
    } else if (prefix == 'PDM' || ct == 'pdm_generated') {
      return (m.wo_number ?? m.id ?? '').toString();
    } else if (prefix == 'INSP' || ct == 'ins_generated') {
      return (m.wo_number ?? m.id ?? '').toString();
    } else {
      return (m.wo_number ?? m.id ?? '').toString();
    }
  }

  String _resolveWorkOrderPrefix() {
    final m = widget.workModel;
    // wo_prefix backend-с ирсэн бол шууд ашиглана
    if (m.wo_prefix != null && m.wo_prefix!.isNotEmpty) {
      return m.wo_prefix!.toUpperCase();
    }
    // Байхгүй бол createType-ээс гаргана
    const prefixMap = {
      'request':       'REQ',
      'pm_generated':  'PM',
      'pdm_generated': 'PDM',
      'ins_generated': 'INSP',
      'open':          'WO',
    };
    final ct = (m.createType ?? '').toLowerCase();
    return prefixMap[ct] ?? 'WO';
  }

  Widget _workCard(int? action_status, BuildContext context) {
    final workOrderNumber = _resolveWorkOrderNumber();
    return customContainer(
      context: context,
      addWidget: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            statusActionRowInt(action_status ?? 0, context,
                detailPage: true, workId: workOrderNumber, workPrefix: _resolveWorkOrderPrefix()),
            CustomText(
              text: title ?? "",
              fontWeight: FontWeight.w700,
              size: 18,
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
                  child: statusClientRow(status, priority, context, true),
                ),

                SizedBox(width: 10.w),

                // ✅ More Action Button (hide for request type)
                if (widget.type != 'request' && widget.type != 'completed')
                  Padding(
                    padding: EdgeInsets.only(
                        top: 22.h), // ✅ Дээрээс 15.h padding нэмэх
                    child: MoreStatusButton(
                      context: context,
                      itemId: widget.id,
                      itemTitle: widget.workModel.title,
                      isProject: true,
                      isSmall: true,
                      clientCanDiscuss: widget.workModel.clientCanDiscuss,
                      role: role,
                      onStatusChanged: (newStatusId, newStatusText) {
                        // ✅ Status солих confirmation dialog
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .alertBoxBackGroundColor,
                              title: Text(
                                AppLocalizations.of(context)!.status,
                              ),
                              content: Text(
                                'Change status to "$newStatusText"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.no,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(dialogContext).pop();
                                    // ✅ Status update хийх (WorkRepo service дуудах)
                                    try {
                                      await WorkRepo().updateWorkOrderStatus(
                                        workOrderId: widget.id!,
                                        statusId: newStatusId,
                                      );

                                      // ✅ Refresh
                                      _onRefresh();

                                      flutterToastCustom(
                                        msg: 'Status updated to $newStatusText',
                                        color: AppColors.primary,
                                      );
                                    } catch (e) {
                                      flutterToastCustom(
                                        msg: 'Failed to update status',
                                      );
                                    }
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.yes,
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
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
                      backgroundImage: image.isNotEmpty && _isValidUuid(image)
                          ? NetworkImage('${activePictureUrl}/${image}')
                          : null,
                      radius: 18.r,
                      child: image.isEmpty || !_isValidUuid(image)
                          ? Icon(
                              Icons.person,
                              size: 20.sp,
                              color: Colors.grey,
                            )
                          : null,
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

  void _handleUsersSelected(
    List<String> category,
    List<int> catId,
    void Function(void Function()) setState,
  ) {
    // print("🔄 _handleUsersSelected called");
    // print("📋 Selected user names: $category");
    // print("🆔 Selected user IDs: $catId");
    // print("📈 Previous user names: $usersName");
    // print("📈 Previous user IDs: $selectedusersNameId");

    setState(() {
      usersName = category;
      selectedusersNameId = catId;
    });
  }

// Add this method to show the add user dialog
  void _showAddUserDialog(BuildContext context) async {
    Map<String, dynamic> workspaceResult =
        await WorkspaceRepo().workspaceIds(id: widget.team_id);

    // ✅ Extract directus_users_id from workspace result
    List<int> workspaceUserIds = [];
    Map<String, dynamic> filter = {};

    if (workspaceResult['data'] != null && workspaceResult['data'] is List) {
      List<String> userUuids = (workspaceResult['data'] as List)
          .map((item) => item['directus_users_id'] as String?)
          .whereType<String>()
          .toList();

      // ✅ Convert UUIDs to integer IDs
      if (userUuids.isNotEmpty) {
        filter = {
          'id': {
            '_in': userUuids,
          },
        };
      }
    }

    List<int> existingUserIds = users?.map((u) => u.id!).toList() ?? [];

    List<String> tempSelectedNames = [];
    List<int> tempSelectedIds = [];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r),
              ),
              backgroundColor: Theme.of(context).colorScheme.backGroundColor,
              title: Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 10.w),
                        CustomText(
                          text: AppLocalizations.of(context)!.selectmembers,
                          fontWeight: FontWeight.w700,
                          size: 16.sp,
                          color: Theme.of(context).colorScheme.textClrChange,
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(
                        height: 15.h,
                        color: Theme.of(context)
                            .colorScheme
                            .dividerClrChange
                            .withValues(alpha: 0.2),
                      ),
                      SizedBox(height: 10.h),
                      UsersField(
                        isRequired: false,
                        isCreate: true,
                        usersname: tempSelectedNames,
                        usersid: tempSelectedIds,
                        filter: filter,
                        project: const [],
                        onSelected: (selectedNames, selectedIds) {
                          dialogSetState(() {
                            tempSelectedNames = selectedNames;
                            tempSelectedIds = selectedIds;
                          });
                        },
                      ),
                      SizedBox(height: 15.h),
                      // Show selected count
                      if (tempSelectedIds.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              SizedBox(width: 8.w),
                              CustomText(
                                text:
                                    '${tempSelectedIds.length} member${tempSelectedIds.length > 1 ? 's' : ''} selected',
                                size: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: CustomText(
                    text: AppLocalizations.of(context)!.cancel,
                    color: AppColors.greyColor,
                    fontWeight: FontWeight.w600,
                    size: 12.sp,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                  ),
                  onPressed: tempSelectedIds.isEmpty
                      ? null
                      : () async {
                          // Add selected users to the work via API
                          try {
                            Navigator.pop(dialogContext);

                            // Show loading toast
                            flutterToastCustom(
                              msg: 'Adding members...',
                              color: AppColors.greyColor,
                            );

                            // Convert integer IDs to UUIDs
                            List<String> userUuids = UserIdMapper()
                                .convertIntsToUuids(tempSelectedIds);

                            // Call API to add users with UUIDs
                            final response =
                                await WorkRepo().addUsersToWorkOrder(
                              workOrderId: widget.id!,
                              userIds: userUuids,
                            );

                            // Check if successful
                            if (response['error'] != true &&
                                !response.containsKey('errors')) {
                              // Update local state
                              setState(() {
                                // Merge with existing users, avoiding duplicates
                                for (int i = 0;
                                    i < tempSelectedIds.length;
                                    i++) {
                                  if (selectedusersNameId != null &&
                                      !selectedusersNameId!
                                          .contains(tempSelectedIds[i])) {
                                    selectedusersNameId!
                                        .add(tempSelectedIds[i]);
                                    if (usersName != null) {
                                      usersName!.add(tempSelectedNames[i]);
                                    }
                                  }
                                }
                              });

                              // Refresh work details
                              await _onRefresh();

                              flutterToastCustom(
                                msg:
                                    'Added ${tempSelectedIds.length} member${tempSelectedIds.length > 1 ? 's' : ''} successfully',
                                color: AppColors.primary,
                              );
                            } else {
                              // Handle error
                              final errorMessage = response['errors']?[0]
                                      ?['message'] ??
                                  response['message'] ??
                                  'Failed to add members';
                              flutterToastCustom(
                                msg: errorMessage,
                              );
                            }
                          } catch (error) {
                            flutterToastCustom(
                              msg: 'Error occurred while adding members',
                            );
                          }
                        },
                  child: CustomText(
                    text: AppLocalizations.of(context)!.selectmembers ??
                        'Add Members',
                    color: AppColors.pureWhiteColor,
                    fontWeight: FontWeight.w600,
                    size: 12.sp,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _usersCard(context, users) {
    return InkWell(
      onTap: () {
        userClientDialog(
          context: context,
          title: AppLocalizations.of(context)!.allusers,
          list: users?.isEmpty ?? true ? [] : users!,
          from: 'user',
        );
      },
      child: customContainer(
        context: context,
        addWidget: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
          child: Column(
            children: [
              UserTeamRowDetailPage(
                list: users?.isEmpty ?? true ? [] : users!,
                title: "${AppLocalizations.of(context)!.workspace} & Users",
                onRemove: isTeamLeader
                    ? (removedUser) async {
                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .alertBoxBackGroundColor,
                              title: Text(
                                AppLocalizations.of(context)!.confirmDelete,
                              ),
                              content: Text(
                                'Remove this user from work order?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(false);
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(true);
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.delete,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed == true) {
                          // Call API to remove user from work order
                          try {
                            // Convert user ID to UUID
                            String? userUuid =
                                UserIdMapper().getUuid(removedUser.id!);

                            if (userUuid == null) {
                              flutterToastCustom(
                                msg: 'Could not find user UUID',
                              );
                              return;
                            }

                            final result =
                                await WorkRepo().removeUserFromWorkOrder(
                              workOrderId: widget.id!,
                              userId: userUuid,
                            );

                            if (result['error'] != true) {
                              // Remove from local state
                              setState(() {
                                users?.removeWhere(
                                    (u) => u.id == removedUser.id);
                                task_users?.removeWhere(
                                    (u) => u.id == removedUser.id);
                              });

                              flutterToastCustom(
                                msg: 'User removed successfully',
                                color: AppColors.primary,
                              );
                            } else {
                              flutterToastCustom(
                                msg: result['message'] ??
                                    'Failed to remove user',
                              );
                            }
                          } catch (e) {
                            flutterToastCustom(
                              msg: 'Failed to remove user',
                            );
                          }
                        }
                      }
                    : null,
              ),
              SizedBox(height: 10.h),
              // ✅ Show add user button only if team leader
              if (isTeamLeader)
                InkWell(
                  onTap: () {
                    // Open dialog to add new user
                    _showAddUserDialog(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8.w),
                      CustomText(
                        text: AppLocalizations.of(context)!
                            .selectmembers, // or "Add User"
                        color: AppColors.primary,
                        size: 14,
                        fontWeight: FontWeight.w600,
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

  Widget _requestInfoCard(context, List<WorkTasks> tasks) {
    String? requestInfo;

    for (int i = 0; i < tasks.length; i++) {
      // print('🔥 Task[$i]: ${tasks[i].toJson()}');
      // print('🔥 Task[$i] requestInfo: ${tasks[i].requestInfo}');

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
            isCreateTask == true && workType != 'completed'
                ? InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () {
                      // BlocProvider.of<UserBloc>(context).add(UserList());
                      // BlocProvider.of<StatusBloc>(context).add(StatusList());
                      router.push(
                        '/createworktask',
                        extra: {
                          "id": 0,
                          "isCreate": true,
                          "title": "",
                          "desc": "",
                          "start": "",
                          "end": "",
                          "users": [],
                          'priority': "",
                          'priorityId': 0,
                          'statusId': 1,
                          'status': "",
                          'note': "",
                          'project': '',
                          'projectId': widget.id,
                          'tasksModel': WorkTasks(),
                          'req': <WorkTasks>[],
                        },
                      );
                    },
                    child: Container(
                      height: 25.h,
                      width: 34.w,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        color: AppColors.primary,
                      ),
                      child: const HeroIcon(
                        size: 15,
                        HeroIcons.plus,
                        style: HeroIconStyle.outline,
                        color: AppColors.pureWhiteColor,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
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
  void _printAllTasks(List<WorkTasks> tasks, int level) {
    for (var task in tasks) {
      // String indent = '  ' * level; // Indent өгөх
      // print('$indent├─ Task ID: ${task.id}, Title: ${task.title}');

      if (task.children != null && task.children!.isNotEmpty) {
        _printAllTasks(
            task.children!.cast<WorkTasks>(), level + 1); // Recursive дуудалт
      }
    }
  }

  // ✅ Recursive task list builder
  Widget _buildNestedTaskList(List<WorkTasks> tasks, int level) {
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
                    '/worktaskdetail',
                    extra: {"id": task.id},
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
                        title: task.title ?? '',
                        workType: workType ?? '',
                        value: task.taskValue ?? '', // ✅ Input утга
                        isEditable: isTeamLeader ||
                            isAssignedToWorkOrder, // ✅ Team leader ЭСВЭЛ assigned user
                        onTap: () async {
                          final result = await router.push(
                            '/worktaskdetail',
                            extra: {"id": task.id},
                          );

                          if (result == true ||
                              result == 1 ||
                              result == "true") {
                            _onRefresh();
                          }
                        },
                        onValueChanged: (newValue) {
                          // ✅ Input өөрчлөгдөхөд backend-руу update илгээх
                          _updateTaskValue(task.id, newValue);
                        },
                        onCreateSubTask: () {
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
                        title: task.title ?? '',
                        isEditable: isTeamLeader ||
                            isAssignedToWorkOrder, // ✅ Team leader ЭСВЭЛ assigned user
                        isCompleted: task.taskValue ==
                            '1', // ✅ Check if taskValue is '1'
                        onTap: () async {
                          final result = await router.push(
                            '/worktaskdetail',
                            extra: {"id": task.id},
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
                task.children is List<WorkTasks>
                    ? task.children as List<WorkTasks>
                    : (task.children as List)
                        .map((e) => e as WorkTasks)
                        .toList(),
                level + 1,
              ),
          ],
        );
      },
    );
  }

  // ✅ Sub-task үүсгэх функц
  void _createSubTask(int? parentTaskId) async {
    if (parentTaskId == null) return;

    // ✅ Task үүсгэх хуудас руу шилжих
    final result = await router.push(
      '/createworktask',
      extra: {
        "id": null, // Шинэ task
        "isCreate": true,
        "parent": parentTaskId, // ✅ Parent task ID дамжуулах
        "workid": widget.id, // ✅ Work ID дамжуулах
      },
    );

    // ✅ Амжилттай үүссэн бол refresh хийх
    if (result == true) {
      _onRefresh();
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

        try {
          // Backend-руу PATCH request илгээх
          await WorkTaskRepo().updateTaskCompletion(
            taskId: taskId,
            value: valueToSend,
          );

          // ✅ Pending update-ийг устгах
          _pendingUpdates.remove(taskId);

          // ✅ Wait for backend to process, then update wo_percent only
          await Future.delayed(const Duration(milliseconds: 500));
          await _updateWorkOrderPercent();
        } catch (e) {
          // Error updating task
        }
      }
    });
  }

  void _updateTaskCompletion(int? taskId, bool isCompleted) async {
    if (taskId == null) return;

    // ✅ Local state update (UI дээр шууд харуулах)
    _updateTaskInLocalState(taskId, isCompleted ? '1' : '0');

    // ✅ Calculate and update wo_percent immediately from local state
    _updateWorkOrderPercentFromLocalState();

    // ✅ Backend-руу PATCH request илгээх (non-blocking)
    WorkTaskRepo()
        .updateTaskCompletion(
      taskId: taskId,
      value: isCompleted ? '1' : '0',
    )
        .catchError((e) {
      return {};
    });
  }

  // ✅ Helper function: Update task value in local state without refetching entire list
  void _updateTaskInLocalState(int taskId, String newValue) {
    bool updated = false;

    // Recursive function to find and update task
    void updateTaskRecursive(List<WorkTasks> tasks) {
      for (var t in tasks) {
        if (t.id == taskId) {
          t.taskValue = newValue;
          updated = true;
          break;
        }
        // Check children recursively
        if (t.children != null && t.children!.isNotEmpty) {
          // ✅ Safely cast children to List<WorkTasks>
          final childrenList = t.children is List<WorkTasks>
              ? t.children as List<WorkTasks>
              : (t.children as List).map((e) => e as WorkTasks).toList();
          updateTaskRecursive(childrenList);
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

  // ✅ Fast wo_percent update from local state (no backend call)
  void _updateWorkOrderPercentFromLocalState() {
    if (task.isEmpty) return;

    // ✅ Count total and completed tasks (recursively)
    int totalTasks = 0;
    int completedTasks = 0;

    void countTasks(List<WorkTasks> tasks) {
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
          // ✅ Safely cast children to List<WorkTasks>
          final childrenList = t.children is List<WorkTasks>
              ? t.children as List<WorkTasks>
              : (t.children as List).map((e) => e as WorkTasks).toList();
          countTasks(childrenList);
        }
      }
    }

    countTasks(task);

    // ✅ Calculate percentage
    double percentage =
        totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;
    String woPercent = percentage.toStringAsFixed(2);

    // ✅ Update work order (non-blocking)
    WorkRepo()
        .updateWorkOrderPercent(
      workOrderId: widget.id!,
      woPercent: woPercent,
    )
        .catchError((e) {
      return {};
    });
  }

  // ✅ Work order percent update хийх функц
  Future<void> _updateWorkOrderPercent() async {
    try {
      // ✅ Fetch fresh task list from backend to avoid stale data
      Map<String, dynamic> result = await WorkTaskRepo().getTask(
        token: true,
        projectId: [widget.id!],
        limit: -1,
      );

      // ✅ Build task tree
      List<WorkTasks> allTasks = List<WorkTasks>.from(
        result['data'].map((workData) => WorkTasks.fromJson(workData)),
      );
      List<WorkTasks> freshTaskTree = _buildTaskTree(allTasks);

      if (freshTaskTree.isEmpty) {
        return;
      }

      // ✅ Count total and completed tasks (recursively)
      // Only count checkbox (type 5) and input field (type 7) tasks
      int totalTasks = 0;
      int completedTasks = 0;

      void countTasks(List<WorkTasks> tasks) {
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
            // ✅ Safely cast children to List<WorkTasks>
            final childrenList = t.children is List<WorkTasks>
                ? t.children as List<WorkTasks>
                : (t.children as List).map((e) => e as WorkTasks).toList();
            countTasks(childrenList);
          }
        }
      }

      countTasks(freshTaskTree);

      // ✅ Calculate percentage
      double percentage =
          totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;
      String woPercent = percentage.toStringAsFixed(2);

      // ✅ Update work order
      await WorkRepo().updateWorkOrderPercent(
        workOrderId: widget.id!,
        woPercent: woPercent,
      );
    } catch (e) {
      // Error updating work order percent
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
        WorkTaskRepo()
            .updateTaskCompletion(
          taskId: taskId!,
          value: value,
        )
            .catchError((e) {
          return {};
        });
      });
    }

    super.dispose();
  }
}
