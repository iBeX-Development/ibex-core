import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hive/hive.dart';
import 'package:ibex/config/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobkit_dashed_border/mobkit_dashed_border.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../bloc/inspectiontask_discussion/task_media/task_media_bloc.dart';
import '../../bloc/inspectiontask_discussion/task_media/task_media_state.dart';

import '../../screens/inspectiontask/task_discussion_screen/task_media_screen.dart';

import '../../utils/widgets/custom_text.dart';
import '../../data/model/inspectiontask/task_model.dart';

import '../../bloc/permissions/permissions_bloc.dart';

import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';

import '../../config/internet_connectivity.dart';
import '../../config/strings.dart';
import '../../routes/routes.dart';
import '../../utils/widgets/back_arrow.dart';
import '../../utils/widgets/custom_dimissible.dart';
import '../../utils/widgets/no_internet_screen.dart';
import '../comment/comment_page.dart';
import '../widgets/custom_container.dart';
import '../widgets/speech_to_text.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionTaskDiscussionTabs extends StatefulWidget {
  final bool? fromDetail;
  final int? id;
  final int? work_order;
  final String? type;
  const InspectionTaskDiscussionTabs(
      {super.key, this.fromDetail, this.id, this.type, this.work_order});

  @override
  State<InspectionTaskDiscussionTabs> createState() =>
      _InspectionTaskDiscussionTabsState();
}

class _InspectionTaskDiscussionTabsState
    extends State<InspectionTaskDiscussionTabs> with TickerProviderStateMixin {
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  ConnectivityResult connectivityCheck = ConnectivityResult.none;
  bool? isLoading = true;
  bool isLoadingMore = false;
  int _selectedIndex = 0;
  String? selectedColorName;
  final Connectivity _connectivity = Connectivity();
  TextEditingController searchController = TextEditingController();
  TextEditingController mediaSearchController = TextEditingController();
  TextEditingController activityLogSearchController = TextEditingController();
  TextEditingController startController = TextEditingController();
  TextEditingController endController = TextEditingController();
  String fromDate = "";
  String toDate = "";
  TextEditingController startDateBetweenController = TextEditingController();
  TextEditingController endDateBetweenController = TextEditingController();
  TextEditingController startDateBetweenstartController =
      TextEditingController();
  TextEditingController endDateBetweenendController = TextEditingController();
  String fromDateBetween = "";
  String toDateBetween = "";
  String fromEndDateBetweenStart = "";
  String toDateEndBetweenEnd = "";
  late SpeechToTextHelper speechHelper;
  String selectedTabText = "";
  int isWhichIndex = 0;
  DateTime selectedDateStarts = DateTime.now();
  DateTime? selectedDateEnds = DateTime.now();
  DateTime selectedDateBetweenStarts = DateTime.now();
  DateTime? selectedDateBetweenEnds = DateTime.now();
  DateTime selectedDateEndBetweenStarts = DateTime.now();
  DateTime? selectedDateEndBetweenEnds = DateTime.now();
  bool? isFirstTimeUSer;
  bool? isFirst;
  String mileStoneSearchQuery = '';
  String mediaSearchQuery = '';
  String activityLogSearchQuery = '';

  TextEditingController titleController = TextEditingController();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late TabController _tabController;
  String? statusname;
  bool isDownloading = false;
  double progress = 0.0;

  List<String> status = ["Complete", "Incomplete"];
  final ValueNotifier<String> filterNameNotifier = ValueNotifier<String>(
    'Date between',
  );

  String filterName = 'Date between';
  ValueNotifier<List<File>> selectedFilesNotifier = ValueNotifier([]);

  void _navigateToIndex(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  _getFirstTimeUser() async {
    var box = await Hive.openBox(authBox);
    isFirstTimeUSer = box.get(firstTimeUserKey) ?? true;
  }

  _setIsFirst(value) async {
    isFirst = value;
    var box = await Hive.openBox(authBox);
    box.put("isFirstCase", value);
  }

  void onShowCaseCompleted() {
    _setIsFirst(false);
  }

  final List<String> filter = [
    'Date between',
    'Start date between',
    'End date between',
    'Statuses',
  ];

  @override
  void initState() {
    super.initState();
    CheckInternet.initConnectivity().then((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        setState(() {
          _connectionStatus = results;
        });
      }
    });

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty) {
        if (kDebugMode) {
          logger.d("ConnectivityResult  in Tab Screen: $results");
        }
        CheckInternet.updateConnectionStatus(results).then((value) {
          setState(() {
            _connectionStatus = value;
          });
        });
      }
    });
    searchController.addListener(() {
      setState(() {});
    });
    mediaSearchController.addListener(() {
      setState(() {});
    });
    activityLogSearchController.addListener(() {
      setState(() {});
    });
    _tabController = TabController(length: 2, vsync: this);
    speechHelper = SpeechToTextHelper(
      onSpeechResultCallback: (result) {
        setState(() {
          searchController.text = result;
        });
        Navigator.pop(context);
      },
    );
    speechHelper.initSpeech();
    // Listen for tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _getFirstTimeUser();
    BlocProvider.of<InspectionTaskMediaBloc>(
      context,
    ).add(InspectionTaskMediaList(id: widget.id));
    if (kDebugMode) {
      logger.d("widget.taskid in Discussion Tab: ${widget.id}");
    }
    if (kDebugMode) {
      logger.d("widget.work_order in Discussion Tab: ${widget.work_order}");
    }

    // BlocProvider.of<ActivityLogBloc>(
    //   context,
    // ).add(AllActivityLogList(type: "task", typeId: widget.id));
  }

  @override
  void dispose() {
    super.dispose();
    _connectivitySubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _pickFile() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'jpg',
          'xlsx',
          'png',
          // 'zip',
          // 'rar',
          'txt',
        ],
      );

      if (result != null) {
        List<File> pickedFiles =
            result.paths.whereType<String>().map((path) => File(path)).toList();

        // Update the ValueNotifier
        selectedFilesNotifier.value = [
          ...selectedFilesNotifier.value,
          ...pickedFiles,
        ];

        if (kDebugMode) {

          logger.d("Selected Files task: ${selectedFilesNotifier.value}");

        }
      }
    }

    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;

    bool isLightTheme = currentTheme is LightThemeState;
    return _connectionStatus.contains(connectivityCheck)
        ? NoInternetScreen()
        : Scaffold(
            backgroundColor: Theme.of(context).colorScheme.backGroundColor,
            body: Stack(
              children: [
                // Main content
                Column(
                  children: [
                    _appBar(isLightTheme),
                    SizedBox(height: 20.h),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          TaskMediaScreen(id: widget.id),
                          CommentSection(
                              title: 'comments',
                              id: widget.id,
                              isProject: false,
                              model: 'inspectioncomment',
                              work_order: widget.work_order),
                        ],
                      ),
                    ),
                    // Add bottom space to ensure content is visible behind the floating bar
                    // SizedBox(height: 60.h),
                  ],
                ),

                // Floating action button
                Visibility(
                  // visible: _selectedIndex != 2 && _selectedIndex != 3,
                  // Hide for index 2 and 3
                  child: Positioned(
                    right: 20.w,
                    bottom: 100.h,
                    child: FloatingActionButton(
                      isExtended: true,
                      onPressed: () {
                        if (_selectedIndex == 0 &&
                            context.read<PermissionsBloc>().iscreateMedia ==
                                true) {
                          // Media tab + permission
                          _uploadFile(
                            pickFile: _pickFile,
                            selectedFileName: selectedFilesNotifier,
                          );
                        } else if (_selectedIndex == 1 &&
                            context.read<PermissionsBloc>().iscreatetask ==
                                true) {
                          // Media tab + permission
                          // BlocProvider.of<UserBloc>(context).add(UserList());
                          // BlocProvider.of<StatusBloc>(
                          //   context,
                          // ).add(StatusList());
                          if (kDebugMode) {
                            logger.d("ghjkl ${widget.id}");
                          }
                          router.push(
                            '/createtask',
                            extra: {
                              "id": 0,
                              "parentId": widget.id,
                              "isSubTask": true,
                              "isCreate": true,
                              "title": "",
                              "desc": "",
                              "start": "",
                              "end": "",
                              "users": [],
                              'priority': "",
                              'priorityId': 0,
                              'statusId': 0,
                              'note': "",
                              'tasksModel': InspectionTasks.empty(),
                              'project': "",
                              'projectId': 0,
                              'status': "",
                              'req': <InspectionTasks>[],
                            },
                          );
                        }
                      },
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.add, color: AppColors.whiteColor),
                    ),
                  ),
                ),

                // Floating bottom navigation
                Positioned(
                  bottom: 20.h,
                  left: 18.w,
                  right: 18.w,
                  child: _floatingBottomNavBar(context, isLightTheme),
                ),
              ],
            ),
          );
  }

  Widget _tabItem(HeroIcons icon, String text, Color color, int index) {
    bool isSelected = _tabController.index == index;
    if (kDebugMode) {
      logger.d("isSelected Tab Item: $isSelected for index $index");
    }
    return GestureDetector(
      onTap: () {
        _navigateToIndex(index);
        isWhichIndex = index;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroIcon(
            icon,
            style: HeroIconStyle.outline,
            size: 18.sp,
            color: color,
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: isSelected
                ? Padding(
                    padding: EdgeInsets.only(top: 3.h),
                    child: Text(
                      text,
                      key: ValueKey(text), // Smooth transition
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _appBar(isLightTheme) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        child: BackArrow(
          projectId: widget.id,
          discussionScreen: "TaskDiscussion",
          iSBackArrow: true,
          iscreatePermission: true,
          title: (() {
            switch (_selectedIndex) {
              case 0:
                return AppLocalizations.of(context)!.media;
              case 1:
                return AppLocalizations.of(context)!.comments;
              default:
                return AppLocalizations.of(context)!.media;
            }
          })(),
          onPress: () {
            // _createEditStatus(isLightTheme: isLightTheme, isCreate: true);
          },
        ),
      ),
    );
  }

  Widget _floatingBottomNavBar(BuildContext context, bool isLightTheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 50.h, // Reduced height
          decoration: BoxDecoration(
            color: isLightTheme
                ? Colors.white.withValues(
                    alpha: 0.15,
                  ) // More transparent for light theme
                : Colors.black.withValues(
                    alpha: 0.15,
                  ), // More transparent for dark theme
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isLightTheme
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isLightTheme
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // if (context.read<PermissionsBloc>().isManageTask == true)
              //   _tabItem(
              //     HeroIcons.documentChartBar,
              //     "Sub Task",
              //     AppColors.orangeColor,
              //     0,
              //   ),
              if (context.read<PermissionsBloc>().isManageMedia == true)
                _tabItem(HeroIcons.photo, "Media", AppColors.photoColor, 0),
              _tabItem(
                HeroIcons.chartBar,
                "Comments",
                AppColors.activityLogColor,
                1,
              ),
              // _tabItem(HeroIcons.bars3, "Status", AppColors.yellow, 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget mediaCard(TaskMedia, index, media, startDate, endDate) {
    return DismissibleCard(
      direction: context.read<PermissionsBloc>().isdeleteTask == true &&
              context.read<PermissionsBloc>().iseditTask == true
          ? DismissDirection.horizontal // Allow both directions
          : context.read<PermissionsBloc>().isdeleteTask == true
              ? DismissDirection.endToStart // Allow delete
              : context.read<PermissionsBloc>().iseditTask == true
                  ? DismissDirection.startToEnd // Allow edit
                  : DismissDirection.none,
      title: index.toString(),
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (context.read<PermissionsBloc>().iseditTask == true) {
            return false;
          } else {
            // No edit permission, prevent swipe
            return false;
          }
        }

        // Handle deletion confirmation
        if (direction == DismissDirection.endToStart) {
          return await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(AppLocalizations.of(context)!.confirmDelete),
                    content: Text(AppLocalizations.of(context)!.areyousure),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(true), // Confirm
                        child: const Text('Delete'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(false), // Cancel
                        child: const Text('Cancel'),
                      ),
                    ],
                  );
                },
              ) ??
              false; // Default to false if dialog is dismissed without action
        }

        return false; // Default case for other directions
      },
      onDismissed: (DismissDirection direction) {
        if (direction == DismissDirection.endToStart &&
            context.read<PermissionsBloc>().isdeleteTask == true) {
          // setState(() {
          //   stateTask.removeAt(index);
          //   _onDeleteTask(id: stateTask[index].id);
          // });
        } else if (direction == DismissDirection.startToEnd &&
            context.read<PermissionsBloc>().iseditTask == true) {}
      },
      dismissWidget: InkWell(
        onTap: () {
          // router.push('/Taskdetails', extra: {
          //   "id": stateTask[index].id,
          // });
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: customContainer(
            context: context,
            addWidget: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Container(
                  // color: Colors.teal,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: "#${media.id.toString()}",
                        size: 14.sp,
                        color: Theme.of(context).colorScheme.textClrChange,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.all(10),
                              height: 50.h,
                              width: 50.w,
                              decoration: BoxDecoration(
                                // color: Colors.red,
                                image: DecorationImage(
                                  image: NetworkImage(media.preview),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Expanded(
                            flex: 3,
                            child: Container(
                              // color: Colors.yellow,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: CustomText(
                                          text: media.fileName,
                                          size: 15.sp,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.textClrChange,
                                          fontWeight: FontWeight.w700,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Download and Delete buttons
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Download button
                                          InkWell(
                                            onTap: () {
                                              if (kDebugMode) {
                                                logger.d("DZgfxzg ${media.file}");
                                              }
                                              context
                                                  .read<
                                                      InspectionTaskMediaBloc>()
                                                  .add(
                                                    InspectionTaskStartDownload(
                                                      fileUrl: media.file,
                                                      fileName: media.fileName,
                                                    ),
                                                  );
                                            },
                                            child: HeroIcon(
                                              HeroIcons.documentArrowDown,
                                              style: HeroIconStyle.outline,
                                              size: 25.sp,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.textClrChange,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          // Delete button
                                          InkWell(
                                            onTap: () async {
                                              // Show confirmation dialog
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text('Delete File'),
                                                    content: Text(
                                                      'Are you sure you want to delete "${media.fileName}"?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        style: TextButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.red,
                                                        ),
                                                        child: Text('Delete'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              if (confirm == true) {
                                                // TODO: Add delete event to bloc
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'File deleted successfully'),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            },
                                            child: HeroIcon(
                                              HeroIcons.trash,
                                              style: HeroIconStyle.outline,
                                              size: 25.sp,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomText(
                                        text: media.fileSize,
                                        size: 12.sp,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.textClrChange,
                                        fontWeight: FontWeight.w700,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 10.h),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: CustomText(
                                            text: startDate,
                                            size: 12.sp,
                                            color: AppColors.greyColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: Icon(
                                              Icons.compare_arrows,
                                              color: AppColors.greyColor,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 5,
                                          child: CustomText(
                                            text: endDate,
                                            size: 12.sp,
                                            color: AppColors.greyColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget StatusTimelineCard(TaskTimelineList, TaskTimeline, index) {
    Color? colorOfNewStatus;
    Color? colorOfOldStatus;

    switch (TaskTimeline.oldColor) {
      case "primary":
        colorOfOldStatus = AppColors.primary;
        break;
      case "secondary":
        colorOfOldStatus = Color(0xFF8592a3);
        break;
      case "success":
        colorOfOldStatus = Colors.green;
        break;
      case "danger":
        colorOfOldStatus = Colors.red;
        break;
      case "warning":
        colorOfOldStatus = Color(0xFFfaab01);
        break;
      case "info":
        colorOfOldStatus = Color(0xFF36c3ec);
        break;
      case "dark":
        colorOfOldStatus = Colors.black;
        break;
      default:
        colorOfOldStatus = Colors.grey; // Fallback color
    }
    switch (TaskTimeline.newColor) {
      case "primary":
        colorOfNewStatus = AppColors.primary;
        break;
      case "secondary":
        colorOfNewStatus = Color(0xFF8592a3);
        break;
      case "success":
        colorOfNewStatus = Colors.green;
        break;
      case "danger":
        colorOfNewStatus = Colors.red;
        break;
      case "warning":
        colorOfNewStatus = Color(0xFFfaab01);
        break;
      case "info":
        colorOfNewStatus = Color(0xFF36c3ec);
        break;
      case "dark":
        colorOfNewStatus = Colors.black;
        break;
      default:
        colorOfNewStatus = Colors.grey; // Fallback color
    }
    // Output: 2025-03-03
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: TimelineTile(
        isFirst: index == 0,
        isLast: index == TaskTimelineList.length - 1,
        beforeLineStyle: LineStyle(color: colorOfNewStatus, thickness: 3),
        indicatorStyle: IndicatorStyle(width: 15.w, color: colorOfNewStatus),
        endChild: Padding(
          padding: const EdgeInsets.all(10.0),
          child: customContainer(
            addWidget: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        TaskTimeline.timeDiff,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.textClrChange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    "${TaskTimeline.changedAt}  ${TaskTimeline.changedAtTime}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "changed status from ",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.textClrChange,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        height: 20.h,
                        // width: 110.w, //
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: colorOfOldStatus,
                        ), // Set the height of the dropdown
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: CustomText(
                              text: TaskTimeline.previousStatus,
                              color: AppColors.whiteColor,
                              size: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        " >> ",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.textClrChange,
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        height: 20.h,
                        // width: 110.w, //
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: colorOfNewStatus,
                        ), // Set the height of the dropdown
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: CustomText(
                              text: TaskTimeline.status,
                              color: AppColors.whiteColor,
                              size: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            context: context,
          ),
        ),
      ),
    );
  }

  final ImagePicker _imagePicker = ImagePicker(); // ✅ Add this

  // ✅ New method to take photo from camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress to 85% quality
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        File photoFile = File(photo.path);

        // Add to selected files
        selectedFilesNotifier.value = [
          ...selectedFilesNotifier.value,
          photoFile,
        ];

        if (kDebugMode) {

          logger.d("📸 Photo taken: ${photo.path}");

        }
        if (kDebugMode) {
          logger.d("📸 File size: ${photoFile.lengthSync()} bytes");
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Photo added successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error taking photo: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ New method to pick from gallery
  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isNotEmpty) {
        List<File> imageFiles = images.map((img) => File(img.path)).toList();

        selectedFilesNotifier.value = [
          ...selectedFilesNotifier.value,
          ...imageFiles,
        ];

        if (kDebugMode) {

          logger.d("🖼️ Selected ${images.length} image(s) from gallery");

        }
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error picking from gallery: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// ✅ Helper method to get file icon
  HeroIcons _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return HeroIcons.documentText;
      case 'doc':
      case 'docx':
        return HeroIcons.document;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return HeroIcons.photo;
      default:
        return HeroIcons.documentText;
    }
  }

  Future<void> _uploadFile({pickFile, selectedFileName}) {
    if (kDebugMode) {
      logger.d("Upload file called");
    }
    return showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: const [],
              borderRadius: BorderRadius.circular(25),
              color: Theme.of(context).colorScheme.backGroundColor,
            ),
            height: 550.h, // ✅ Increased height
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 40.h,
                            width: 40.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.greyColor.withValues(alpha: 0.3),
                            ),
                            child: HeroIcon(
                              HeroIcons.cloudArrowUp,
                              style: HeroIconStyle.outline,
                              size: 25.sp,
                              color: AppColors.greyColor,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Upload files",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Take photo or select files",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // ✅ Camera and Gallery buttons row
                  Row(
                    children: [
                      // Camera button
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            await _takePhoto();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                HeroIcon(
                                  HeroIcons.camera,
                                  style: HeroIconStyle.solid,
                                  size: 16.sp,
                                  color: AppColors.whiteColor,
                                ),
                                SizedBox(height: 8.h),
                                CustomText(
                                  text: "Take Photo",
                                  size: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.whiteColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 12.w),

                      // Gallery button
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            await _pickFromGallery();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade600,
                                  Colors.green.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                HeroIcon(
                                  HeroIcons.photo,
                                  style: HeroIconStyle.solid,
                                  size: 16.sp,
                                  color: AppColors.whiteColor,
                                ),
                                SizedBox(height: 8.h),
                                CustomText(
                                  text: "Gallery",
                                  size: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.whiteColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: CustomText(
                          text: "OR",
                          size: 12.sp,
                          color: AppColors.greyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // File picker area (existing code)
                  Container(
                    decoration: const BoxDecoration(
                      border: DashedBorder.fromBorderSide(
                        dashLength: 15,
                        side: BorderSide(color: AppColors.greyColor, width: 1),
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    width: double.infinity,
                    padding: EdgeInsets.all(8.w),
                    child: Column(
                      children: [
                        CustomText(
                          text: "Browse documents",
                          size: 12.sp,
                          textAlign: TextAlign.center,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.textClrChange,
                        ),
                        CustomText(
                          text: "PDF, DOC, DOCX, JPG, PNG",
                          color: AppColors.greyColor,
                          size: 10.sp,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10.h),
                        InkWell(
                          onTap: pickFile,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.greyColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.greyColor,
                                width: 1,
                              ),
                            ),
                            height: 25.h,
                            width: 80.w,
                            child: CustomText(
                              text: "Browse files",
                              size: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Selected files list (existing ValueListenableBuilder code)
                  Expanded(
                    child: ValueListenableBuilder<List<File>>(
                      valueListenable: selectedFilesNotifier,
                      builder: (context, files, child) {
                        if (files.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                HeroIcon(
                                  HeroIcons.documentPlus,
                                  style: HeroIconStyle.outline,
                                  size: 40.sp,
                                  color: AppColors.greyColor.withValues(alpha: 0.5),
                                ),
                                SizedBox(height: 8.h),
                                CustomText(
                                  text: "No files selected",
                                  size: 14.sp,
                                  color: AppColors.greyColor,
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            // Files header
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      HeroIcon(
                                        HeroIcons.documentCheck,
                                        style: HeroIconStyle.solid,
                                        size: 16.sp,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 6.w),
                                      CustomText(
                                        text:
                                            "${files.length} file(s) selected",
                                        size: 13.sp,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      selectedFilesNotifier.value = [];
                                    },
                                    style: TextButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.w),
                                    ),
                                    child: CustomText(
                                      text: "Clear all",
                                      size: 12.sp,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 8.h),

                            // Files list
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: files.length,
                                itemBuilder: (context, index) {
                                  final file = files[index];
                                  final fileName = file.path.split('/').last;
                                  final fileSize = (file.lengthSync() / 1024)
                                      .toStringAsFixed(1);
                                  final isImage = fileName
                                          .toLowerCase()
                                          .endsWith('.jpg') ||
                                      fileName
                                          .toLowerCase()
                                          .endsWith('.jpeg') ||
                                      fileName.toLowerCase().endsWith('.png');

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8.h),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 10.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // ✅ Show thumbnail for images
                                          if (isImage)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.file(
                                                file,
                                                width: 45.w,
                                                height: 45.h,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: EdgeInsets.all(8.w),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: HeroIcon(
                                                _getFileIcon(fileName),
                                                style: HeroIconStyle.solid,
                                                size: 18.sp,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CustomText(
                                                  text: fileName,
                                                  size: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                CustomText(
                                                  text: "$fileSize KB",
                                                  size: 11.sp,
                                                  color: AppColors.greyColor,
                                                ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              final newList =
                                                  List<File>.from(files);
                                              newList.removeAt(index);
                                              selectedFilesNotifier.value =
                                                  newList;
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(6.w),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.red.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                size: 16.sp,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Upload button (existing code)
                  ValueListenableBuilder<List<File>>(
                    valueListenable: selectedFilesNotifier,
                    builder: (context, files, child) {
                      final hasFiles = files.isNotEmpty;

                      return InkWell(
                        onTap: () {
                          if (!hasFiles) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select files first'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          logger.d(
                              "task_file_upload ${selectedFilesNotifier.value}");

                          // Dispatch upload event
                          context.read<InspectionTaskMediaBloc>().add(
                                InspectionUploadTaskMediaOnTask(
                                  id: widget.id!,
                                  media: selectedFilesNotifier.value,
                                ),
                              );

                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          // Listen for upload completion
                          final subscription = context
                              .read<InspectionTaskMediaBloc>()
                              .stream
                              .listen((state) {
                            if (state is InspectionTaskMediaUploadSuccess) {
                              // Close loading dialog
                              Navigator.of(context).pop();
                              // Close upload modal
                              Navigator.of(context).pop();

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Files uploaded successfully!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );

                              // Refresh media list
                              context.read<InspectionTaskMediaBloc>().add(
                                    InspectionTaskMediaList(id: widget.id),
                                  );

                              // Clear selected files
                              selectedFilesNotifier.value = [];
                            } else if (state is InspectionTaskMediaError) {
                              // Close loading dialog
                              Navigator.of(context).pop();

                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.white),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Upload failed:'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          });

                          // Cancel subscription after 30 seconds to prevent memory leaks
                          Future.delayed(Duration(seconds: 30), () {
                            subscription.cancel();
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: hasFiles
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppColors.greyColor.withValues(alpha: 0.3),
                                      AppColors.greyColor.withValues(alpha: 0.2),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: hasFiles
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          height: 45.h,
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HeroIcon(
                                HeroIcons.cloudArrowUp,
                                style: HeroIconStyle.solid,
                                size: 20.sp,
                                color: hasFiles
                                    ? AppColors.pureWhiteColor
                                    : AppColors.greyColor,
                              ),
                              SizedBox(width: 8.w),
                              CustomText(
                                text: hasFiles
                                    ? "Upload ${files.length} file${files.length > 1 ? 's' : ''}"
                                    : AppLocalizations.of(context)!.upload,
                                size: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: hasFiles
                                    ? AppColors.pureWhiteColor
                                    : AppColors.greyColor,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showToastWithProgress(BuildContext context, double progress) {
    OverlayState overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17.4),
              color: Theme.of(context).colorScheme.containerDark,
            ),

            // height: 50.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              child: Column(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text:
                        "Downloading... ${(progress * 100).toStringAsFixed(0)} %",
                    color: Theme.of(context).colorScheme.textClrChange,
                    size: 15.sp,
                  ),
                  SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.textClrChange,
                    minHeight: 8.h,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    // Remove after a few seconds or upon completion
    Future.delayed(Duration(seconds: 5), () {
      overlayEntry.remove();
    });
  }
}
