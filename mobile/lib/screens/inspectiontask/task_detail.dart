import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:slidable_bar/slidable_bar.dart';
import 'package:ibex/bloc/theme/theme_state.dart';
import 'package:ibex/config/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ibex/screens/widgets/custom_container.dart';

import 'package:ibex/utils/widgets/status_priority_row.dart';

import '../../bloc/comments/comments_bloc.dart';
import '../../bloc/inspectiontask_discussion/task_media/task_media_bloc.dart';
// import '../../bloc/inspectiontask_discussion/task_media/task_media_event.dart';

import '../../bloc/inspectiontask_discussion/task_media/task_media_state.dart';
import '../../bloc/inspectiontask/task_bloc.dart';
import '../../bloc/inspectiontask/task_event.dart';
import '../../bloc/inspectiontask/task_state.dart';
import '../../bloc/inspectiontask_id/taskid_bloc.dart';
import '../../bloc/inspectiontask_id/taskid_event.dart';
import '../../bloc/inspectiontask_id/taskid_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../config/constants.dart';

import '../../data/model/inspectiontask/task_model.dart';
import '../../data/repositories/comments/comment_repo.dart';
import '../home_screen/home_widgets/drawer_widgets.dart';
import '../widgets/custom_app_bar.dart';
import 'task_discussion_screen/task_media_screen.dart';
import '../../routes/routes.dart';
import '../../utils/widgets/custom_text.dart';
import '../../utils/widgets/my_theme.dart';
import '../../utils/widgets/toast_widget.dart';

import '../dash_board/dashboard.dart';
import '../notes/widgets/notes_shimmer_widget.dart';

import '../widgets/back_bar.dart';
import '../widgets/side_bar.dart';
import '../comment/comment_page.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionTaskDetailScreen extends StatefulWidget {
  final bool? fromNoti;
  final String? from;
  final int? id;
  final int? work_order;
  const InspectionTaskDetailScreen(
      {super.key, this.fromNoti, this.from, this.id, this.work_order});

  @override
  State<InspectionTaskDetailScreen> createState() =>
      _InspectionTaskDetailScreenState();
}

class _InspectionTaskDetailScreenState
    extends State<InspectionTaskDetailScreen> {
  DateTime selectedDateStarts = DateTime.now();
  DateTime selectedDateEnds = DateTime.now();

  String selectedCategory = '';

  List<InspectionTasks> task = [];
  List<String> username = [];

  int? id;
  int? InspectionspaceId;
  String? title;
  InspectionTasks? taskModel;
  String? status;
  int? statusId;
  String? priority;
  int? priorityId;
  List<InspectionTaskUsers>? users;
  List<int>? userId;
  List<InspectionTaskClients>? clients;
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
  InspectionTasks? model;

  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final SlidableBarController sideBarController = SlidableBarController(
    initialStatus: false,
  );
  bool _isSidebarOpen = false; // Track sidebar open/close state

  // Add ScrollController
  bool isExpand = false;

  void toggleDrawer(bool expanded) {
    setState(() {
      isExpand = expanded;
    });
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      logger.d('InspectionTaskDetailScreen initialized with id: ${widget.id}');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<InspectionTaskidBloc>()
          .add(InspectionTaskIdListId(widget.id));
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        File photoFile = File(photo.path);
        await _uploadFileToServer(photoFile);
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error taking photo: $e");
      }
      flutterToastCustom(
        msg: 'Failed to take photo',
        color: Colors.red,
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isNotEmpty) {
        for (var image in images) {
          File imageFile = File(image.path);
          await _uploadFileToServer(imageFile);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error picking from gallery: $e");
      }
      flutterToastCustom(
        msg: 'Failed to pick images',
        color: Colors.red,
      );
    }
  }

  Future<void> _uploadFileToServer(File file) async {
    try {
      context.read<InspectionTaskMediaBloc>().add(
            InspectionUploadTaskMediaOnTask(
              id: widget.id!,
              media: [file],
            ),
          );

      flutterToastCustom(
        msg: 'File uploaded successfully',
        color: AppColors.primary,
      );

      // Refresh media list
      await Future.delayed(Duration(seconds: 1));
      context.read<InspectionTaskMediaBloc>().add(
            InspectionTaskMediaList(id: widget.id!),
          );
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error uploading file: $e");
      }
      flutterToastCustom(
        msg: 'Failed to upload file',
        color: Colors.red,
      );
    }
  }

  Future<void> _onRefresh() async {
    if (kDebugMode) {
      logger.d('Refreshing_task: ${widget.id}');
    }
    BlocProvider.of<InspectionTaskidBloc>(context)
        .add(InspectionTaskIdListId(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      logger.d('Building InspectionTaskDetailScreen with id: ${widget.id}');
    }
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;

    bool isLightTheme = currentTheme is LightThemeState;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        BlocProvider.of<InspectionTaskidBloc>(
          context,
        ).add(InspectionTaskIdListId(widget.id));
        if (!didPop) {
          router.pop();
        }
      },
      child: MultiBlocListener(
        listeners: [
          // ✅ InspectionTaskBloc listener нэмэх
          BlocListener<InspectionTaskBloc, InspectionTaskState>(
            listener: (context, state) {
              if (state is InspectionTaskEditSuccess ||
                  state is InspectionTaskCreateSuccess) {
                _onRefresh();
              }

              // ✅ Delete success үед
              if (state is InspectionTaskDeleteSuccess) {
                if (kDebugMode) {
                  logger.d('🔥 [UI] Task deleted successfully');
                }

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
                //     print('🔥 [UI] Resetting InspectionTaskBloc state');
                //     context.read<InspectionTaskBloc>().add(
                //         AllInspectionTaskListOnTask()); // ← Task list дахин ачаалах
                //   }
                // });

                // ✅ InspectionTaskBloc state-ийг reset хийх
                if (kDebugMode) {
                  logger.d('🔥 [UI] Resetting InspectionTaskBloc state');
                }
                context
                    .read<InspectionTaskBloc>()
                    .add(ResetInspectionTaskState());

                // ✅ Task detail хуудас хаах (Inspection_details руу буцах)
                router.pop(); // Return with refresh signal
              }

              // ✅ Delete error үед
              if (state is InspectionTaskDeleteError) {
                if (kDebugMode) {
                  logger.d('🔥 [UI] Delete error: ${state.errorMessage}');
                }

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
              if (state is InspectionTaskError) {
                if (kDebugMode) {
                  logger.d('🔥 [UI] Task error: ${state.errorMessage}');
                }

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
          backgroundColor: Theme.of(context).colorScheme.backGroundColor,
          drawer: DrawerWidgets(
            isExpand: isExpand,
            toggleDrawer: toggleDrawer,
          ),
          // floatingActionButtonLocation: ExpandableFab.location,
          // floatingActionButton: context.read<PermissionsBloc>().isdeleteTask ==
          //             true ||
          //         context.read<PermissionsBloc>().iseditTask == true
          //     ? detailMenu(
          //         onpressChat: () {
          //           _key.currentState?.toggle();
          //           router.push(
          //             "/commentsection",
          //             extra: {
          //               "id": widget.id,
          //               "work_order": widget.work_order,
          //               "title": title,
          //               "model": "inspectioncomment",
          //               "isProject": false,
          //             },
          //           );
          //           context.read<CommentsBloc>().isProject = false;
          //         },
          //         isChat: canClientDiscuss == 1,
          //         isDiscuss: canClientDiscuss == 1,
          //         isEdit: context.read<PermissionsBloc>().iseditTask,
          //         isDelete: context.read<PermissionsBloc>().isdeleteTask,
          //         key: _key,
          //         context: context,
          //         onpressEdit: () {
          //           _key.currentState?.toggle();
          //           // List<String> username = [];
          //           // for (var names in users!) {
          //           //   username.add(names.firstName!);
          //           // }
          //           // List<int>? ids = [];
          //           // for (var i in users!) {
          //           //   ids.add(i.id!);
          //           // }

          //           print('sdoo_coom');
          //           router.push(
          //             '/createinspectiontask',
          //             extra: {
          //               "id": widget.id,
          //               "isCreate": false,
          //               "fromDetail": true,
          //               "title": title,
          //               "users": [],
          //               "user": '',
          //               "usersid": [],
          //               "desc": description,
          //               "start": startDate,
          //               "end": dueDate,
          //               'priority': priority,
          //               'priorityId': priorityId,
          //               'statusId': statusId,
          //               'note': note,
          //               'project': '',
          //               "userList": users,
          //               "tasksModel": InspectionTasks.empty(),
          //               'projectId': projectId,
          //               'status': status,
          //               'req': <CreateTaskModel>[],
          //             },
          //           );
          //           // Navigator.pop(context);
          //         },
          //         onpressDelete: () {
          //           showDialog(
          //             context: context,
          //             builder: (dialogContext) {
          //               // ✅ dialogContext ашиглах
          //               return AlertDialog(
          //                 shape: RoundedRectangleBorder(
          //                   borderRadius: BorderRadius.circular(
          //                     10.r,
          //                   ), // Set the desired radius here
          //                 ),
          //                 backgroundColor: Theme.of(
          //                   context,
          //                 ).colorScheme.alertBoxBackGroundColor,
          //                 title: Text(
          //                   AppLocalizations.of(context)!.confirmDelete,
          //                 ),
          //                 content:
          //                     Text(AppLocalizations.of(context)!.areyousure),
          //                 actions: [
          //                   TextButton(
          //                     onPressed: () {
          //                       print('Deleting task: ${widget.id}');

          //                       Navigator.of(dialogContext)
          //                           .pop(); // ✅ Dialog хаах

          //                       _onInspectionDeleteTask(widget.id);
          //                     },
          //                     child: const Text('Delete'),
          //                   ),
          //                   TextButton(
          //                     onPressed: () {
          //                       Navigator.of(
          //                         context,
          //                       ).pop(false); // Cancel deletion
          //                     },
          //                     child: const Text('Cancel'),
          //                   ),
          //                 ],
          //               );
          //             },
          //           );
          //         },
          //         // Remove the discuss button since comments are inline
          //         onpressdiscuss: null,
          //       )
          //     : SizedBox.shrink(),
          body: Stack(
            children: [
              SideBar(
                context: context,
                controller: sideBarController,
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
                      physics:
                          const AlwaysScrollableScrollPhysics(), // Ensure always scrollable

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
                          BlocConsumer<InspectionTaskidBloc,
                              InspectionTaskidState>(
                            listener: (context, state) {
                              if (state is InspectionTaskidWithId) {
                                dateCreated = '';
                                dateUpdated = '';
                                dateStart = '';
                                dateEnd = '';
                                for (var item in state.task) {
                                  model = InspectionTasks(
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
                                    dateCreated =
                                        parseDateTimeFormat(createdAt!);
                                  }
                                  if (updatedAt != null &&
                                      updatedAt!.isNotEmpty) {
                                    dateUpdated =
                                        parseDateTimeFormat(updatedAt!);
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
                              if (state is InspectionTaskidWithId) {
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
                                    dateCreated =
                                        parseDateTimeFormat(createdAt!);
                                  }
                                  if (updatedAt != null &&
                                      updatedAt!.isNotEmpty) {
                                    dateUpdated =
                                        parseDateTimeFormat(updatedAt!);
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
                                          horizontal: 18.w),
                                      child: _taskCard(),
                                    ),
                                    SizedBox(height: 20.h),
                                    // Description card removed
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 18.w),
                                      child: _dateCard(
                                        dateStart,
                                        dateEnd,
                                        dateCreated,
                                        dateUpdated,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),

                                    // Comments Section
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 18.w),
                                      child: _buildCommentsSection(),
                                    ),
                                    SizedBox(height: 20.h),
                                    Divider(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.dividerClrChange,
                                    ),
                                    // Media Section
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 18.w),
                                      child: _buildMediaSection(),
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
                              if (state is InspectionTaskLoading) {
                                return Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 18.w),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 20),
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
                                    const SizedBox(height: 20),
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
                        ],
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

  Widget _buildMediaSection() {
    return BlocBuilder<InspectionTaskMediaBloc, InspectionTaskMediaState>(
      builder: (context, state) {
        bool hasMedia = false;
        if (state is InspectionTaskMediaPaginated) {
          hasMedia = state.TaskMediaList.isNotEmpty;
        }

        return customContainer(
          width: double.infinity,
          context: context,
          // height: hasMedia ? 400.h : 200.h,
          addWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(15.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: HeroIcon(
                        HeroIcons.photo,
                        style: HeroIconStyle.solid,
                        size: 14.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    CustomText(
                      text: AppLocalizations.of(context)!.media,
                      size: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.textClrChange,
                    ),
                    Spacer(),
                    // Upload button
                    IconButton(
                      icon: HeroIcon(
                        HeroIcons.arrowUpTray,
                        size: 20.sp,
                        color: AppColors.primary,
                      ),
                      onPressed: () async {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.backGroundColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(25.r),
                                topRight: Radius.circular(25.r),
                              ),
                            ),
                            height: 300.h,
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40.w,
                                    height: 4.h,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2.r),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    "Attach files",
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .textClrChange,
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                  ListTile(
                                    leading: HeroIcon(
                                      HeroIcons.camera,
                                      style: HeroIconStyle.outline,
                                      color: AppColors.primary,
                                    ),
                                    title: Text('Camera'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await _takePhoto();
                                    },
                                  ),
                                  ListTile(
                                    leading: HeroIcon(
                                      HeroIcons.photo,
                                      style: HeroIconStyle.outline,
                                      color: Colors.green,
                                    ),
                                    title: Text('Gallery'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await _pickFromGallery();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      tooltip: "Файл оруулах",
                    ),
                    if (hasMedia)
                      IconButton(
                        icon: HeroIcon(
                          HeroIcons.chevronRight,
                          size: 16.sp,
                          color: const Color(0xFF1F2937),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) => InspectionTaskMediaBloc()
                                  ..add(
                                      InspectionTaskMediaList(id: widget.id!)),
                                child: Scaffold(
                                  appBar: AppBar(
                                    title: Text(
                                      AppLocalizations.of(context)!.media,
                                    ),
                                  ),
                                  body: TaskMediaScreen(id: widget.id!),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: Theme.of(context)
                    .colorScheme
                    .dividerClrChange
                    .withValues(alpha: 0.3),
              ),
              SizedBox(
                height: hasMedia ? 300.h : 80.h,
                child: BlocProvider.value(
                  value: context.read<InspectionTaskMediaBloc>(),
                  child: TaskMediaScreen(id: widget.id!),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsSection() {
    return customContainer(
      width: double.infinity,
      context: context,
      addWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(15.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: HeroIcon(
                    HeroIcons.chatBubbleBottomCenterText,
                    style: HeroIconStyle.solid,
                    size: 14.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 10.w),
                CustomText(
                  text: AppLocalizations.of(context)!.comments,
                  size: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.textClrChange,
                ),
                Spacer(),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) => CommentsBloc(
                            discussionRepo: DiscussionRepo(),
                          ),
                          child: CommentSection(
                            id: widget.id,
                            title: title ?? "",
                            model: "inspectioncomment",
                            isProject: false,
                            work_order: widget.work_order,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: HeroIcon(
                          HeroIcons.chevronLeft,
                          size: 16.sp,
                          color: const Color(0xFF1F2937),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Theme.of(context)
                .colorScheme
                .dividerClrChange
                .withValues(alpha: 0.3),
          ),
          SizedBox(
            height: 300.h,
            child: BlocProvider(
              create: (context) => CommentsBloc(
                discussionRepo: DiscussionRepo(),
              ),
              child: CommentSection(
                id: widget.id,
                title: title ?? "",
                model: "inspectioncomment",
                isProject: false,
                work_order: widget.work_order,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
