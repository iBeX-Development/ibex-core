import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:ibex/data/localStorage/hive.dart';
import 'package:ibex/utils/widgets/safe_avatar.dart';
import 'package:ibex/utils/user_id_mapper.dart';
import 'package:slidable_bar/slidable_bar.dart';
import 'package:ibex/bloc/permissions/permissions_bloc.dart';
import 'package:ibex/bloc/permissions/permissions_event.dart';
import 'package:ibex/bloc/setting/settings_bloc.dart';
import 'package:ibex/data/model/Work/all_work.dart';
import 'package:ibex/utils/widgets/custom_dimissible.dart';
import 'package:ibex/utils/widgets/row_dashboard.dart';
import 'package:ibex/utils/widgets/shake_widget.dart';

import '../../bloc/priority/priority_state.dart';

import '../../bloc/work_filter/work_filter_bloc.dart';
import '../../bloc/work_filter/work_filter_event.dart';
import '../../bloc/work_filter/work_filter_state.dart';

import '../../bloc/priority_multi/priority_multi_bloc.dart';
import '../../bloc/priority_multi/priority_multi_event.dart';
import '../../bloc/priority_multi/priority_multi_state.dart';
import '../../bloc/status_multi/status_multi_bloc.dart';
import '../../bloc/status_multi/status_multi_event.dart';
import '../../bloc/status_multi/status_multi_state.dart';
import '../../bloc/task_filter/task_filter_bloc.dart';
import '../../bloc/task_filter/task_filter_event.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_event.dart';
import '../../bloc/user/user_state.dart';
import '../../config/constants.dart';
import '../../config/strings.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:intl/intl.dart';
import 'package:ibex/utils/widgets/custom_text.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/work/work_bloc.dart';
import '../../bloc/work/work_event.dart';
import '../../bloc/work/work_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';
import '../../config/colors.dart';
import '../../data/repositories/Work/work_repo.dart';
import '../../routes/routes.dart';
import '../../utils/widgets/my_theme.dart';
import '../../utils/widgets/status_priority_row.dart';
import '../../utils/widgets/toast_widget.dart';
import '../../utils/widgets/search_pop_up.dart';
import '../notes/widgets/notes_shimmer_widget.dart';
import '../widgets/back_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_date.dart';
import '../widgets/html_widget.dart';
import '../widgets/no_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../widgets/no_permission_screen.dart';
import '../widgets/search_field.dart';
import '../widgets/side_bar.dart';

import '../widgets/user_client_box.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import '../home_screen/home_widgets/drawer_widgets.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Work order-ийн дугаарыг created_type болон wo_prefix-ээс хамааруулан гаргаж авна.
/// JS логиктой ижил:
///   REQ / request      → req_number ?? id
///   PM  / pm_generated → source_pm ?? wo_number ?? id
///   PDM / pdm_generated→ source_pdm ?? wo_number ?? id
///   INSP/ ins_generated→ source_ins ?? wo_number ?? id
///   default            → wo_number ?? id
String getWorkOrderNumber(WorkModel work) {
  final prefix = (work.wo_prefix ?? '').toUpperCase();
  final ct = (work.createType ?? '').toLowerCase();

  if (prefix == 'REQ' || ct == 'request') {
    return (work.req_number ?? work.id ?? '').toString();
  } else if (prefix == 'PM' || ct == 'pm_generated') {
    return (work.wo_number ?? work.id ?? '').toString();
  } else if (prefix == 'PDM' || ct == 'pdm_generated') {
    return (work.wo_number ?? work.id ?? '').toString();
  } else if (prefix == 'INSP' || ct == 'ins_generated') {
    return (work.wo_number ?? work.id ?? '').toString();
  } else {
    return (work.wo_number ?? work.id ?? '').toString();
  }
}

class WorkScreen extends StatefulWidget {
  final String type; // "open", "request", "completed", "assigned"
  final bool? is_show_back;
  const WorkScreen({super.key, this.type = "open", this.is_show_back = true});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

double progress = 0.6;

class _WorkScreenState extends State<WorkScreen> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
    value: 1.0,
  );
  late final AnimationController _pinnedcController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
    value: 1.0,
  );

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  bool hasShownShowcase = false;
  String _lastWords = "";
  String searchword = "";

  bool isListening =
      false; // Flag to track if speech recognition is in progress
  bool dialogShown = false;
  bool _isSidebarOpen = false; // Track sidebar open/close state

  int? projectsId;
  int? totalCount = 0;
  String? fromDate;
  String? toDate;
  bool? isFirstTimeUSer;
  DateTime selectedDateStarts = DateTime.now();
  DateTime? selectedDateEnds = DateTime.now();
  TextEditingController startsController = TextEditingController();
  TextEditingController endController = TextEditingController();
  final TextEditingController _statusSearchController = TextEditingController();
  final TextEditingController _prioritySearchController =
      TextEditingController();
  final SlidableBarController sideBarController = SlidableBarController(
    initialStatus: false,
  );
  final TextEditingController _userSearchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isExpand = true;
  List<int> userSelectedId = [];
  List<int> userSelectedIdS = [];
  List<String> userSelectedname = [];

  List<int> clientSelectedIdS = [];
  List<String> clientSelectedname = [];
  String? currency;
  String? currencyPosition;

  List<int> prioritySelectedIdS = [];
  List<String> prioritySelectedname = [];

  List<int> tagsSelectedIdS = [];
  List<String> tagsSelectedname = [];
  bool? isLoading = true;
  bool? clientSelected = false;
  bool? clientDisSelected = false;
  bool? priorityDisSelected = false;
  bool? userDisSelected = false;
  bool? userSelected = false;
  bool? tagDisSelected = false;
  bool? statusDisSelected = false;
  bool? dateDisSelected = false;

  bool? statusSelected = false;
  bool? prioritySelected = false;
  bool? tagSelected = false;
  bool? dateSelected = false;

  List<int> statusSelectedIdS = [];
  List<String> statusSelectedname = [];

  // ✅ FIX: Don't initialize with hardcoded values
  late String WorksType; // Will be set in initState
  late String WorksTypeSelected; // Will be set in initState
  late String WorksTypeFilter; // Will be set in initState
  late String initialType; // Will be set in initState

  final ValueNotifier<String> filterNameNotifier = ValueNotifier<String>(
    'Priorities',
  ); // Initialize with default value

  final ValueNotifier<String> req_filterNameNotifier = ValueNotifier<String>(
    'Request',
  ); // Initialize with default value

  String filterName = 'Priorities';
  String req_filterName = 'Request';

  int? selectedIndex;

  void listenForPermissions() async {
    final status = await Permission.microphone.status;
    switch (status) {
      case PermissionStatus.denied:
        requestForPermission();
        break;
      case PermissionStatus.granted:
        break;
      case PermissionStatus.limited:
        break;
      case PermissionStatus.permanentlyDenied:
        break;
      case PermissionStatus.restricted:
        break;
      case PermissionStatus.provisional: // Handle the provisional case
        break;
    }
  }

  _getFirstTimeUser() async {
    var box = await Hive.openBox(authBox);
    isFirstTimeUSer = box.get(firstTimeUserKey) ?? true;
  }

  Future<void> requestForPermission() async {
    await Permission.microphone.request();
  }

  void _onDeleteWork(id) {
    final setting = context.read<WorkBloc>();
    BlocProvider.of<WorkBloc>(context).add(DeleteWork(id));
    setting.stream.listen((state) {
      if (state is WorkDeleteSuccess) {
        if (mounted) {
          flutterToastCustom(
            msg: AppLocalizations.of(context)!.deletedsuccessfully,
            color: AppColors.primary,
          );
          BlocProvider.of<WorkBloc>(context).add(
            WorkDashBoardList(workType: initialType, createType: initialType),
          );
        }
      }
      if (state is WorkDeleteError) {
        if (mounted) {
          flutterToastCustom(msg: state.errorMessage);
        }
        BlocProvider.of<WorkBloc>(context).add(
          WorkDashBoardList(workType: initialType, createType: initialType),
        );
      }
    });
  }

  TextEditingController searchController = TextEditingController();
  final GlobalKey _one = GlobalKey();

  int filterSelectedId = 0;
  String filterSelectedName = "";
  String searchWord = "";
  Object is_assigned = {};
  int filterCount = 0;

  bool? isFirst;
  late var filter = ['Users', 'Status', 'Priorities', 'Date'];

  late List<String> req_filter = ['Request', 'Open', 'Completed', 'Date'];

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  void _filterDialog(BuildContext context, isLightTheme) {
    // ✅ Load works for the selected filter type BEFORE showing dialog
    if (WorksTypeSelected == 'request') {
      // Load request works
      _loadRequestTypeWorks('request');
    }

    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.containerDark,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 10),
              CustomText(
                text: AppLocalizations.of(context)!.selectfilter,
                color: AppColors.primary,
                size: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 600.h,
                      child: ListView.builder(
                        itemCount: WorksTypeSelected == 'request'
                            ? req_filter.length
                            : filter.length,
                        itemBuilder: (BuildContext context, int index) {
                          final filterItem = WorksTypeSelected == 'request'
                              ? req_filter[index]
                              : filter[index];

                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (WorksTypeSelected == 'request') {
                                  req_filterNameNotifier.value = filterItem;

                                  // ✅ CRITICAL FIX: Update WorksTypeFilter when selecting Request/Open/Completed
                                  if (filterItem.toLowerCase() == 'request' ||
                                      filterItem.toLowerCase() == 'open' ||
                                      filterItem.toLowerCase() == 'completed') {
                                    WorksTypeFilter = filterItem
                                        .toLowerCase(); // ✅ Update WorksTypeFilter
                                  }

                                  // ✅ Load works immediately when filter changes
                                  if (filterItem.toLowerCase() != 'date') {
                                    _loadRequestTypeWorks(
                                      filterItem.toLowerCase(),
                                    );
                                  }
                                } else {
                                  filterNameNotifier.value = filterItem;
                                }
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              child: Container(
                                height: 50.h,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    isLightTheme
                                        ? MyThemesFilter.lightThemeShadow
                                        : MyThemesFilter.darkThemeShadow,
                                  ],
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.containerDark,
                                ),
                                child: Row(
                                  children: [
                                    ValueListenableBuilder<String>(
                                      valueListenable:
                                          WorksTypeSelected == 'request'
                                              ? req_filterNameNotifier
                                              : filterNameNotifier,
                                      builder: (context, currentFilter, child) {
                                        return currentFilter == filterItem
                                            ? Expanded(
                                                flex: 1,
                                                child: Container(
                                                  width: 2,
                                                  color: AppColors.primary,
                                                ),
                                              )
                                            : SizedBox.shrink();
                                      },
                                    ),
                                    Expanded(
                                      flex: 35,
                                      child: Center(
                                        child: Text(
                                          filterItem,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.textClrChange,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: ValueListenableBuilder<String>(
                      valueListenable: WorksTypeSelected == 'request'
                          ? req_filterNameNotifier
                          : filterNameNotifier,
                      builder: (context, filterName, child) {
                        return _getFilteredWidget(filterName, isLightTheme);
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h), // ✅ Spacing before buttons
              // ✅ Apply and Clear Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    // ✅ Apply Button - FIX
                    InkWell(
                      onTap: () {
                        // ✅ CRITICAL: Update WorksTypeSelected from WorksTypeFilter
                        // WorksTypeFilter нь user-ийн сонгосон type (request/open/completed)
                        // setState(() {
                        //   WorksTypeSelected = WorksTypeFilter;
                        //   WorksType = WorksTypeFilter;
                        // });

                        // Calculate and update filter count based on selections
                        if (userSelectedIdS.isNotEmpty) {
                          context.read<WorkFilterCountBloc>().add(
                                WorkUpdateFilterCount(
                                  filterType: 'users',
                                  isSelected: true,
                                ),
                              );
                        }
                        if (statusSelectedIdS.isNotEmpty) {
                          context.read<WorkFilterCountBloc>().add(
                                WorkUpdateFilterCount(
                                  filterType: 'status',
                                  isSelected: true,
                                ),
                              );
                        }
                        if (prioritySelectedIdS.isNotEmpty) {
                          context.read<WorkFilterCountBloc>().add(
                                WorkUpdateFilterCount(
                                  filterType: 'priorities',
                                  isSelected: true,
                                ),
                              );
                        }

                        if (fromDate != null || toDate != null) {
                          context.read<WorkFilterCountBloc>().add(
                                WorkUpdateFilterCount(
                                  filterType: 'date',
                                  isSelected: true,
                                ),
                              );
                        }

                        // ✅ NOW: Get work type filters based on WorksTypeSelected (NOT widget.type!)
                        String createType = _getCreateTypeFromFilter(
                          initialType,
                        );
                        Map<String, dynamic>? actionStatusFilter =
                            _getActionStatusFilterFromType(WorksTypeFilter);

                        // ✅ Get woStatusIds based on WorksTypeSelected (NOT widget.type!)
                        _getWoStatusIdsFromType(WorksTypeFilter).then((
                          woStatusIds,
                        ) {
                          // print('🔥 Apply filter - woStatusIds: $woStatusIds');

                          // ✅ Apply filters to work dashboard with UPDATED workType
                          BlocProvider.of<WorkBloc>(context).add(
                            WorkDashBoardList(
                              workType: initialType,
                              createType: initialType,
                              actionStatus: actionStatusFilter,
                              woStatus: woStatusIds,
                              tagId: tagsSelectedIdS,
                              clientId: clientSelectedIdS,
                              userId: userSelectedIdS,
                              statusId: statusSelectedIdS,
                              priorityId: prioritySelectedIdS,
                              fromDate: fromDate,
                              toDate: toDate,
                            ),
                          );
                        });

                        // Clear search controllers
                        _statusSearchController.clear();
                        _prioritySearchController.clear();
                        _userSearchController.clear();

                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 35.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15.w,
                            vertical: 0.h,
                          ),
                          child: Center(
                            child: CustomText(
                              text: AppLocalizations.of(context)!.apply,
                              size: 12.sp,
                              color: AppColors.pureWhiteColor,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 30.w), // ✅ Spacing between button
                    // ✅ Clear Button
                    InkWell(
                      onTap: () {
                        setState(() {
                          // Reset all filter selections
                          context.read<WorkFilterCountBloc>().add(
                                WorkResetFilterCount(),
                              );

                          // Clear all selected IDs
                          tagsSelectedIdS.clear();
                          clientSelectedIdS.clear();
                          userSelectedIdS.clear();
                          statusSelectedIdS.clear();
                          prioritySelectedIdS.clear();

                          // Reset date filters
                          fromDate = null;
                          toDate = null;
                          startsController.clear();
                          endController.clear();

                          // Clear search controllers
                          _statusSearchController.clear();
                          _prioritySearchController.clear();
                          _userSearchController.clear();
                          WorksTypeFilter = initialType;
                          WorksTypeSelected = initialType;
                          WorksType = initialType;

                          // Reset filter name
                          if (widget.type.toLowerCase() == 'request') {
                            req_filterNameNotifier.value = 'Request';
                          } else {
                            filterNameNotifier.value = 'Priorities';
                          }

                          // ✅ Get work type filters for reset
                          String createType = _getCreateType();
                          Map<String, dynamic>? actionStatusFilter =
                              _getActionStatusFilter();

                          // ✅ Get woStatusIds and reset
                          _getWoStatusIds().then((woStatusIds) {
                            // ✅ Reset work dashboard with original workType
                            BlocProvider.of<WorkBloc>(context).add(
                              WorkDashBoardList(
                                workType: initialType, // ✅ Reset to original
                                createType: initialType,
                                actionStatus: actionStatusFilter,
                                woStatus: woStatusIds,
                              ),
                            );
                          });
                        });

                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 35.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.w),
                          child: Center(
                            child: CustomText(
                              text: AppLocalizations.of(context)!.clear,
                              size: 12.sp,
                              color: AppColors.pureWhiteColor,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ NEW: Get createType based on any type string (not just widget.type)
  String _getCreateTypeFromFilter(String type) {
    switch (type.toLowerCase()) {
      case "open":
        return "open";
      case "request":
        return 'request';
      case "completed":
        return 'request';
      case "assigned":
        return '';
      default:
        return "open";
    }
  }

  Map<String, dynamic>? _getActionStatusFilterFromType(String type) {
    switch (type.toLowerCase()) {
      case "open":
        return {
          "_in": [2],
        };
      case "request":
        return {
          "_in": [1, 6],
        };
      case "completed":
        return null;
      case "assigned":
        return {
          "_in": [4],
        };
      default:
        return {
          "_in": [2],
        };
    }
  }

  // ✅ NEW: Get woStatusIds based on any type string
  Future<List<int>> _getWoStatusIdsFromType(String type) async {
    switch (type.toLowerCase()) {
      case "open":
        return await HiveStorage.getOpenStatusIds();
      case "completed":
        return await HiveStorage.getClosedStatusIds();
      case "request":
        return [1];
      case "assigned":
        return await HiveStorage.getOpenStatusIds();
      default:
        return await HiveStorage.getOpenStatusIds();
    }
  }

  // ✅ Helper function to load request type works
  Future<void> _loadRequestTypeWorks(String type) async {
    String createType = _getCreateTypeForFilter(
      type,
    ); // ✅ This will now work correctly
    Map<String, dynamic>? actionStatusFilter = _getActionStatusFilterForType(
      type,
    );
    List<int> woStatusIds = await _getWoStatusIdsForType(type);

    String screenType = widget.type.toLowerCase();

    BlocProvider.of<WorkBloc>(context).add(
      WorkDashBoardList(
        workType: initialType,
        createType: initialType,
        actionStatus: actionStatusFilter,
        woStatus: woStatusIds,
      ),
    );
  }

  // ✅ Helper functions for filter type
  String _getCreateTypeForFilter(String type) {
    switch (type.toLowerCase()) {
      // ✅ Changed from widget.type to type
      case "open":
        return "open";
      case "request":
        return 'request';
      case "completed":
        return 'request';
      default:
        return "open";
    }
  }

  Map<String, dynamic>? _getActionStatusFilterForType(String type) {
    switch (type.toLowerCase()) {
      case "open":
        return {
          "_in": [2],
        };
      case "request":
        return {
          "_in": [1, 6],
        };
      case "completed":
        return {
          "_in": [3],
        };
      default:
        return {
          "_in": [2],
        };
    }
  }

  Future<List<int>> _getWoStatusIdsForType(String type) async {
    switch (type.toLowerCase()) {
      case "open":
        return await HiveStorage.getOpenStatusIds();
      case "completed":
        return await HiveStorage.getClosedStatusIds();
      case "request":
        return [1];
      case "assigned":
        return [9];
      default:
        return await HiveStorage.getOpenStatusIds();
    }
  }

  @override
  void initState() {
    super.initState();

    context.read<WorkFilterCountBloc>().add(WorkResetFilterCount());
    context.read<TaskFilterCountBloc>().add(TaskResetFilterCount());

    currency = context.read<SettingsBloc>().currencySymbol;
    currencyPosition = context.read<SettingsBloc>().currencyPosition;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ShowCaseWidget.of(context).startShowCase([_one]),
    );

    listenForPermissions();
    BlocProvider.of<PermissionsBloc>(context).add(GetPermissions());

    // ✅ CRITICAL FIX: Ensure lowercase conversion
    initialType = widget.type.toLowerCase();

    WorksTypeSelected = initialType;
    WorksTypeFilter = initialType;
    WorksType = initialType;

    // ✅ Set correct filter notifier based on type
    if (WorksTypeSelected == 'request') {
      req_filterNameNotifier.value = 'Request';
    } else {
      filterNameNotifier.value = 'Priorities';
    }

    // Type-аасаа хамааруулан Work-уудыг дуудах
    _loadWorksByType();

    if (!_speechEnabled) {
      _initSpeech();
    }
    _getFirstTimeUser();
  }

  // Type-аасаа хамааруулан Work-уудыг дуудах функц
  Future<void> _loadWorksByType() async {
    String createType = _getCreateType();
    List<int> woStatusIds = await _getWoStatusIds();
    Map<String, dynamic>? actionStatusFilter = _getActionStatusFilter();

    // ✅ Fetch work order IDs where user is assigned (from Work_order_task_users)
    List<int>? assignedWorkOrderIds;
    try {
      assignedWorkOrderIds = await WorkRepo().getMyAssignedWorkOrderIds();
      if (assignedWorkOrderIds.isEmpty) {
        assignedWorkOrderIds = null; // Don't filter if no assignments
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('⚠️ Error fetching assigned work order IDs: $e');
      }
      assignedWorkOrderIds = null;
    }

    BlocProvider.of<WorkBloc>(context).add(
      WorkDashBoardList(
        workType: initialType,
        createType: initialType,
        woStatus: woStatusIds,
        actionStatus: actionStatusFilter,
        workOrderIds: assignedWorkOrderIds, // ✅ Pass work order IDs filter
      ),
    );
  }

  // Type-аас хамааруулан priority ID-г буцаах
  List<int> _getpriorityIdByType() {
    switch (widget.type.toLowerCase()) {
      case "open":
        return [3]; // Open priority ID
      case "request":
        return [2]; // Requested priority ID
      case "completed":
        return [1]; // Completed priority ID
      case "assigned":
        return [4];
      default:
        return []; // Бүх priority
    }
  }

  // Type-аас хамааран priority ID-г буцаах
  // ✅ Keep existing functions but use widget.type (for initial load only)
  String _getCreateType() {
    return _getCreateTypeFromFilter(widget.type);
  }

  Map<String, dynamic>? _getActionStatusFilter() {
    return _getActionStatusFilterFromType(WorksTypeSelected);
  }

  Future<List<int>> _getWoStatusIds() async {
    return _getWoStatusIdsFromType(widget.type);
  }

  // Title-г type-аас хамааруулан өөрчлөх
  String _getTitle() {
    switch (WorksTypeSelected.toLowerCase()) {
      case "request":
        return AppLocalizations.of(context)!.requestWorks + ' ($totalCount)';
      case "open":
        return AppLocalizations.of(context)!.openWorks + ' ($totalCount)';
      case "completed":
        return AppLocalizations.of(context)!.completedWorks + ' ($totalCount)';
      case "assigned":
        return AppLocalizations.of(context)!.myAssign + ' ($totalCount)';
      default:
        return AppLocalizations.of(context)!.openWorks + ' ($totalCount)';
    }
  }

  _setIsFirst(value) async {
    isFirst = value;
    var box = await Hive.openBox(authBox);
    box.put("isFirstCase", value);
  }

  void onShowCaseCompleted() {
    _setIsFirst(false);
  }

  Future<void> _onRefresh() async {
    // print("Refreshing work list");
    setState(() {
      isLoading = true;
    });
    filterCount = 0;

    // Get the proper filters based on current type
    String createType = _getCreateType();
    List<int> woStatusIds = await _getWoStatusIds();
    Map<String, dynamic>? actionStatusFilter = _getActionStatusFilter();

    BlocProvider.of<WorkBloc>(context).add(
      WorkDashBoardList(
        workType: initialType,
        createType: initialType,
        woStatus: woStatusIds,
        actionStatus: actionStatusFilter,
      ),
    );
    BlocProvider.of<PermissionsBloc>(context).add(GetPermissions());

    setState(() {
      isLoading = false;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      isListening = false;
      if (_lastWords.isEmpty) {
        // If no words were recognized, allow reopening the dialog
        dialogShown = false;
      }
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
  }

  bool shouldDisableEdit = true;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  static final bool _onDevice = false;

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // _logEvent('sound level $level: $minSoundLevel - $maxSoundLevel ');
    setState(() {
      this.level = level;
    });
  }

  double level = 0.0;

  void _onDialogDismissed() {
    setState(() {
      dialogShown = false; // Reset flag when the dialog is dismissed
    });
  }

  void _startListening() async {
    if (!_speechToText.isListening && !dialogShown) {
      setState(() {
        dialogShown = true; // Set the flag to prevent showing multiple dialogs
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SearchPopUp(); // Call the SearchPopUp widget here
        },
      ).then((_) {
        // This will be called when the dialog is dismissed.
        _onDialogDismissed();
      });
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        localeId: "en_En",
        pauseFor: Duration(seconds: 3),
        onSoundLevelChange: soundLevelListener,
        listenOptions: options,
      );
      setState(() {});
    }
  }

  final options = SpeechListenOptions(
    onDevice: _onDevice,
    listenMode: ListenMode.confirmation,
    cancelOnError: true,
    partialResults: true,
    autoPunctuation: true,
    enableHapticFeedback: true,
  );

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      // Reset the last words on each new result to avoid appending repeatedly
      _lastWords = result.recognizedWords;
      searchController.text = _lastWords;
      if (_lastWords.isNotEmpty && dialogShown) {
        Navigator.pop(context); // Close the dialog once the speech is detected
        dialogShown = false; // Reset the dialog flag
      }
    });

    // Trigger search with the current recognized words
    context.read<WorkBloc>().add(SearchWork(_lastWords, [], []));
  }

  bool isLoadingMore = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;

    bool isLightTheme = currentTheme is LightThemeState;

    return Scaffold(
      // floatingActionButton: (context.read<PermissionsBloc>().iscreateWork ==
      //         true)
      //     ? Padding(
      //         padding: EdgeInsets.only(bottom: 60.h),
      //         child: FloatingActionButton(
      //           isExtended: true,
      //           onPressed: () {
      //             String create_path = '/createworkrequest';
      //             if (initialType.toLowerCase() == 'request') {
      //               create_path = '/createworkrequest';
      //             } else {
      //               create_path = '/creatework';
      //             }
      //             context.read<PermissionsBloc>().iscreateWork == true
      //                 ? router.push(
      //                     create_path,
      //                     extra: {
      //                       "id": 0,
      //                       "isCreate": true,
      //                       "fromDetail": false,
      //                       "title": "",
      //                       "desc": "",
      //                       'note': "",
      //                       // "user":task.users,
      //                       'priority': '1', // ✅ Changed from "" to 1
      //                       'priorityId': 1, // ✅ Changed from 0 to 1
      //                       'statusId': 1, // ✅ Changed from 0 to 1
      //                       'status': '1', // ✅ Changed from "" to 1
      //                       'woStatus': 1, // ✅ Add default work order status
      //                       'createdType':
      //                           initialType.toLowerCase(), // ✅ Add created type
      //                     },
      //                   )
      //                 : null;
      //           }, // Icon inside the FAB
      //           backgroundColor: AppColors.primary,
      //           child: isFirstTimeUSer == true
      //               ? Showcase(
      //                   onTargetClick: () {
      //                     ShowCaseWidget.of(
      //                       context,
      //                     ).completed(_one); // Manually complete the step
      //                     if (ShowCaseWidget.of(context).activeWidgetId == 1) {
      //                       onShowCaseCompleted(); // Trigger this after the last showcase step
      //                     }
      //                   },
      //                   key: _one,
      //                   disposeOnTap:
      //                       true, // ✅ Required when using onTargetClick

      //                   titleAlignment: Alignment.center,
      //                   title: 'Add Work',
      //                   titleTextStyle: const TextStyle(
      //                     fontSize: 14,
      //                     color: Colors.grey,
      //                   ),
      //                   descTextStyle: const TextStyle(
      //                     fontSize: 12,
      //                     color: AppColors.textsub2Color,
      //                   ),
      //                   description:
      //                       'Add new Work data by clicking this button.',
      //                   child: const Icon(
      //                     Icons.add,
      //                     color: AppColors.whiteColor,
      //                   ),
      //                 )
      //               : const Icon(
      //                   Icons.add,
      //                   color: AppColors.whiteColor,
      //                 ), // Background color of the FAB
      //         ),
      //       )
      //     : SizedBox.shrink(),
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
            underWidget: Container(
              color: Theme.of(context).colorScheme.backGroundColor,
              child: Column(
                children: [
                  BlocBuilder<WorkBloc, WorkState>(
                    builder: (context, state) {
                      // ✅ Update totalCount when state changes
                      if (state is WorkPaginated) {
                        // Use filter_count from meta if available, otherwise use work.length
                        totalCount = state.work.length;
                      }
                      return CustomAppBar(
                        title: _getTitle(),
                        onMenuPressed: () {
                          setState(() {
                            isExpand = false;
                          });
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      );
                    },
                  ),
                  SizedBox(height: 10.h),
                  CustomSearchField(
                    isLightTheme: isLightTheme,
                    controller: searchController,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (searchController.text.isNotEmpty)
                          SizedBox(
                            width: 20.w,
                            // color: AppColors.red,
                            child: IconButton(
                              highlightColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.clear,
                                size: 20.sp,
                                color: Theme.of(
                                  context,
                                ).colorScheme.textFieldColor,
                              ),
                              onPressed: () {
                                searchController.clear();
                                context.read<WorkBloc>().add(
                                      SearchWork('', [], []),
                                    );
                              },
                            ),
                          ),
                        SizedBox(
                          width: 30.w,
                          child: IconButton(
                            icon: Icon(
                              _speechToText.isNotListening
                                  ? Icons.mic_off
                                  : Icons.mic,
                              size: 20.sp,
                              color: Theme.of(
                                context,
                              ).colorScheme.textFieldColor,
                            ),
                            onPressed: () {
                              if (_speechToText.isNotListening) {
                                _startListening();
                              } else {
                                _stopListening();
                              }
                            },
                          ),
                        ),
                        BlocBuilder<WorkFilterCountBloc, FilterCountState>(
                          builder: (context, state) {
                            return SizedBox(
                              width: 35.w,
                              child: Stack(
                                children: [
                                  IconButton(
                                    icon: HeroIcon(
                                      HeroIcons.adjustmentsHorizontal,
                                      style: HeroIconStyle.solid,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.textFieldColor,
                                      size: 30.sp,
                                    ),
                                    onPressed: () {
                                      BlocProvider.of<UserBloc>(
                                        context,
                                      ).add(UserList());
                                      BlocProvider.of<StatusMultiBloc>(
                                        context,
                                      ).add(StatusMultiList());
                                      BlocProvider.of<PriorityMultiBloc>(
                                        context,
                                      ).add(PriorityMultiList());

                                      // Your existing filter dialog logic
                                      _filterDialog(context, isLightTheme);
                                    },
                                  ),
                                  if (state.count > 0)
                                    Positioned(
                                      right: 5.w,
                                      top: 7.h,
                                      child: Container(
                                        padding: EdgeInsets.zero,
                                        alignment: Alignment.center,
                                        height: 12.h,
                                        width: 10.w,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: CustomText(
                                          text: state.count.toString(),
                                          color: Colors.white,
                                          size: 6,
                                          textAlign: TextAlign.center,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onChanged: (value) {
                      searchword = value;
                      context.read<WorkBloc>().add(SearchWork(value, [], []));
                    },
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary, // Spinner color
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.backGroundColor,
                      onRefresh: _onRefresh,
                      child: context.read<PermissionsBloc>().isManageWork ==
                              true
                          ? BlocConsumer<WorkBloc, WorkState>(
                              listener: (context, state) {
                                if (state is WorkPaginated) {
                                  isLoadingMore = false;
                                  setState(() {
                                    totalCount = state.work.length;
                                  });
                                  setState(() {});
                                }
                              },
                              builder: (context, state) {
                                // print("sfdjnxcvdzxcvgfn  $state");
                                if (state is WorkLoading) {
                                  return const NotesShimmer();
                                } else if (state is WorkPaginated) {
                                  // print("WorkPaginated state  ${state.work.length}");
                                  // for (var element in state.work) {
                                  //   print(element.toJson());
                                  // }
                                  // Show notes list with pagination
                                  return NotificationListener<
                                      ScrollNotification>(
                                    onNotification: (scrollInfo) {
                                      if (scrollInfo
                                          is ScrollStartNotification) {
                                        FocusScope.of(
                                          context,
                                        ).unfocus(); // Dismiss keyboard
                                      }
                                      // Check if the user has scrolled to the end and load more notes if needed
                                      if (!state.hasReachedMax &&
                                          scrollInfo.metrics.pixels ==
                                              scrollInfo
                                                  .metrics.maxScrollExtent &&
                                          isLoadingMore == false) {
                                        isLoadingMore = true;
                                        setState(() {});
                                        context.read<WorkBloc>().add(
                                              WorkLoadMore(searchWord, [], []),
                                            );
                                      }
                                      return false;
                                    },
                                    child:
                                        // ✅ Show data if permission granted OR if data exists
                                        (context
                                                        .read<PermissionsBloc>()
                                                        .isManageWork ==
                                                    true ||
                                                state.work.isNotEmpty)
                                            ? state.work.isNotEmpty
                                                ? ListView.builder(
                                                    padding: EdgeInsets.only(
                                                      left: 18.w,
                                                      right: 18.w,
                                                      bottom: 70.h,
                                                      top: 0,
                                                    ),
                                                    // physics: NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                    itemCount: state
                                                            .hasReachedMax
                                                        ? state.work.length
                                                        : state.work.length + 1,
                                                    itemBuilder:
                                                        (context, index) {
                                                      if (index <
                                                          state.work.length) {
                                                        WorkModel work =
                                                            state.work[index];
                                                        String? date;

                                                        if (work.startDate !=
                                                            null) {
                                                          date =
                                                              parseDateTimeFormat(
                                                            work.startDate!,
                                                          );
                                                        }
                                                        return (index == 0 ||
                                                                isFirstTimeUSer ==
                                                                    true)
                                                            ? ShakeWidget(
                                                                child: (index ==
                                                                            0 &&
                                                                        isFirstTimeUSer ==
                                                                            true)
                                                                    ? Showcase(
                                                                        onTargetClick:
                                                                            () {
                                                                          ShowCaseWidget
                                                                              .of(
                                                                            context,
                                                                          ).completed(
                                                                            _one,
                                                                          );
                                                                          if (ShowCaseWidget.of(
                                                                                context,
                                                                              ).activeWidgetId ==
                                                                              1) {
                                                                            onShowCaseCompleted();
                                                                          }
                                                                          _setIsFirst(
                                                                            false,
                                                                          );
                                                                        },
                                                                        disposeOnTap:
                                                                            true,
                                                                        key:
                                                                            _one,
                                                                        title: AppLocalizations.of(
                                                                          context,
                                                                        )!
                                                                            .swipe,
                                                                        titleAlignment:
                                                                            Alignment.center,
                                                                        descriptionAlignment:
                                                                            Alignment.center,
                                                                        description:
                                                                            "${AppLocalizations.of(context)!.swipelefttodelete} \n${AppLocalizations.of(context)!.swiperighttoedit}",
                                                                        tooltipBackgroundColor:
                                                                            AppColors.primary,
                                                                        textColor:
                                                                            Colors.white,
                                                                        child:
                                                                            workList(
                                                                          state
                                                                              .work,
                                                                          index,
                                                                          work,
                                                                          date,
                                                                          isLightTheme,
                                                                        ),
                                                                      )
                                                                    : workList(
                                                                        state
                                                                            .work,
                                                                        index,
                                                                        work,
                                                                        date,
                                                                        isLightTheme,
                                                                      ),
                                                              )
                                                            : workList(
                                                                state.work,
                                                                index,
                                                                work,
                                                                date,
                                                                isLightTheme,
                                                              );
                                                      } else {
                                                        // Show a loading indicator when more notes are being loaded
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            vertical: 0,
                                                          ),
                                                          child: Center(
                                                            child: state
                                                                    .hasReachedMax
                                                                ? const Text('')
                                                                : const SpinKitFadingCircle(
                                                                    color: AppColors
                                                                        .primary,
                                                                    size: 40.0,
                                                                  ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  )
                                                : NoData(isImage: true)
                                            : NoPermission(),
                                  );
                                } else if (state is WorkError) {
                                  // Show error message
                                  return const NotesShimmer();
                                } else if (state is WorkSuccess) {
                                  logger.d(
                                    "work success state: ${state.work.length}",
                                  );
                                }
                                // Handle other states
                                return Container();
                              },
                            )
                          : const NoPermission(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.is_show_back ??
              true) // ✅ Only show BackBar when is_show_back is true
            BackBar(isSidebarOpen: _isSidebarOpen),
        ],
      ),
    );
  }

  void _onFilterSelected(String selectedFilter) {
    setState(() {
      filterName = selectedFilter; // Update the filterName and rebuild UI
    });
  }

  Widget _getFilteredWidget(filterName, isLightTheme) {
    switch (filterName.toLowerCase()) {
      case 'users':
        return userLists(); // Show UserList if filterName is "user"
      case 'status':
        return statusLists();
      case 'priorities':
        return priorityLists();
      case 'open':
        return requestLists('open');
      case 'request':
        return requestLists('request');
      case 'completed':
        return requestLists('completed');
      case 'date':
        return dateList(isLightTheme); // Show TagsList if filterName is "tags"
      default:
        return userLists(); // Default view
    }
  }

  Widget dateList(isLightTheme) {
    return SizedBox(
      width: 200.w,
      height: 400.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: DateRangePickerWidget(
              dateController: startsController,
              selectedDateEnds: selectedDateEnds,
              selectedDateStarts: selectedDateStarts,
              title: AppLocalizations.of(context)!.starts,
              onTap: (start, end) {
                setState(() {
                  // if (start.isBefore(DateTime.now())) {
                  //   start = DateTime
                  //       .now(); // Reset the start date to today if earlier
                  // }

                  // If the end date is not selected or is null, set it to the start date
                  if (end!.isBefore(start!) || selectedDateEnds == null) {
                    end =
                        start; // Set the end date to the start date if not selected
                  }
                  selectedDateEnds = end;
                  selectedDateStarts = start;
                  startsController.text = DateFormat(
                    'MMMM dd, yyyy',
                  ).format(selectedDateStarts);
                  endController.text = DateFormat(
                    'MMMM dd, yyyy',
                  ).format(selectedDateEnds!);
                  fromDate = DateFormat('yyyy-MM-dd').format(start);
                  toDate = DateFormat('yyyy-MM-dd').format(end!);
                });
              },

              // showCustomDateRangePicker(
              //   context,
              //   dismissible: true,
              //   minimumDate: DateTime(1900, 1, 1), // Very early date
              //   maximumDate: DateTime(2100, 12, 31),
              //   endDate: selectedDateEnds,
              //   startDate: selectedDateStarts,
              //   backgroundColor: Theme.of(context).colorScheme.containerDark,
              //   primaryColor: AppColors.primary,
              //   onApplyClick: (start, end) {
              //     setState(() {
              //       // if (start.isBefore(DateTime.now())) {
              //       //   start = DateTime
              //       //       .now(); // Reset the start date to today if earlier
              //       // }
              //
              //       // If the end date is not selected or is null, set it to the start date
              //       if (end.isBefore(start) || selectedDateEnds == null) {
              //         end =
              //             start; // Set the end date to the start date if not selected
              //       }
              //       selectedDateEnds = end;
              //       selectedDateStarts = start;
              //       startsController.text = DateFormat('MMMM dd, yyyy')
              //           .format(selectedDateStarts);
              //       endController.text =
              //           DateFormat('MMMM dd, yyyy').format(selectedDateEnds!);
              //       fromDate = DateFormat('yyyy-MM-dd').format(start);
              //       toDate = DateFormat('yyyy-MM-dd').format(end);
              //     });
              //   },
              //   onCancelClick: () {
              //     setState(() {
              //       // Handle cancellation if necessary
              //     });
              //   },
              // );
              isLightTheme: isLightTheme,
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: DateRangePickerWidget(
              dateController: endController,
              title: AppLocalizations.of(context)!.ends,
              isLightTheme: isLightTheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget statusLists() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 35.h,
            child: TextField(
              cursorColor: AppColors.greyForgetColor,
              cursorWidth: 1,
              controller: _statusSearchController,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: (35.h - 20.sp) / 2,
                  horizontal: 10.w,
                ),
                hintText: 'Search...',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.greyForgetColor,
                    // Set your desired color here
                    width: 1.0, // Set the border width if needed
                  ),
                  borderRadius: BorderRadius.circular(
                    20.0,
                  ), // Optional: adjust the border radius
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(
                    color: AppColors.purple,
                    // Border color when TextField is focused
                    width: 1.0,
                  ),
                ),
              ),
              onChanged: (value) {
                context.read<StatusMultiBloc>().add(SearchStatusMultis(value));
              },
            ),
          ),
        ),
        SizedBox(height: 10.h),
        BlocBuilder<StatusMultiBloc, StatusMultiState>(
          builder: (context, state) {
            if (state is StatusMultiLoading || state is StatusMultiInitial) {
              return SpinKitFadingCircle(size: 40, color: AppColors.primary);
            }
            if (state is StatusMultiPaginated) {
              ScrollController scrollController = ScrollController();
              scrollController.addListener(() {
                if (scrollController.position.atEdge) {
                  if (scrollController.position.pixels != 0 &&
                      !state.hasReachedMax) {
                    // We're at the bottom
                    BlocProvider.of<StatusMultiBloc>(
                      context,
                    ).add(StatusMultiLoadMore());
                  }
                }
              });

              return StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setState) {
                  return Container(
                    constraints: BoxConstraints(maxHeight: 900.h),
                    width: 200.w,
                    height: 530,
                    child: state.statusMulti.isNotEmpty
                        ? ListView.builder(
                            controller: scrollController,
                            // physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: state.statusMulti.length + 1,
                            itemBuilder: (BuildContext context, int index) {
                              if (index < state.statusMulti.length) {
                                final isSelected = statusSelectedIdS.contains(
                                  state.statusMulti[index].id!,
                                );
                                // final isSelected = widget.userId?.contains(state.user[index].id);

                                return InkWell(
                                  splashColor: Colors.transparent,
                                  onTap: () {
                                    // userSelectedname.clear();
                                    // userSelectedIdS.clear();
                                    setState(() {
                                      if (isSelected) {
                                        statusDisSelected = true;
                                        statusSelectedIdS.remove(
                                          state.statusMulti[index].id!,
                                        );
                                        statusSelectedname.remove(
                                          state.statusMulti[index].title!,
                                        );
                                        // If no clients are selected anymore, update filter count
                                        if (statusSelectedIdS.isEmpty) {
                                          context
                                              .read<WorkFilterCountBloc>()
                                              .add(
                                                WorkUpdateFilterCount(
                                                  filterType: 'status',
                                                  isSelected: false,
                                                ),
                                              );
                                        }
                                      } else {
                                        if (!statusSelectedIdS.contains(
                                          state.statusMulti[index].id!,
                                        )) {
                                          statusSelectedIdS.add(
                                            state.statusMulti[index].id!,
                                          );
                                          statusSelectedname.add(
                                            state.statusMulti[index].title!,
                                          );
                                          // Update filter count when first client is selected
                                          if (statusSelectedIdS.length == 1) {
                                            context
                                                .read<WorkFilterCountBloc>()
                                                .add(
                                                  WorkUpdateFilterCount(
                                                    filterType: 'status',
                                                    isSelected: true,
                                                  ),
                                                );
                                          }
                                        }
                                      }

                                      _onFilterSelected('status');
                                    });
                                    BlocProvider.of<StatusMultiBloc>(
                                      context,
                                    ).add(
                                      SelectedStatusMulti(
                                        index,
                                        state.statusMulti[index].title!,
                                      ),
                                    );
                                    BlocProvider.of<StatusMultiBloc>(
                                      context,
                                    ).add(
                                      ToggleStatusMultiSelection(
                                        state.statusMulti[index].id!,
                                        state.statusMulti[index].title!,
                                      ),
                                    );
                                    // context.read<WorkBloc>().add(SearchWork("", filterSelectedId, filterSelectedNmae));
                                    // Future.delayed(Duration(seconds: 1), () {
                                    //   Navigator.pop(context);
                                    // });

                                    // userSelectedIdS.clear();
                                    // userSelectedname.clear();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 2.h,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.purpleShade
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                        ),
                                      ),
                                      width: double.infinity,
                                      height: 35.h,
                                      child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 110.w,
                                                child: CustomText(
                                                  text: state.statusMulti[index]
                                                      .title!,
                                                  fontWeight: FontWeight.w500,
                                                  size: 18.sp,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .textClrChange,
                                                ),
                                              ),
                                              isSelected
                                                  ? const HeroIcon(
                                                      HeroIcons.checkCircle,
                                                      style:
                                                          HeroIconStyle.solid,
                                                      color: AppColors.primary,
                                                    )
                                                  : const SizedBox.shrink(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                // Show a loading indicator when more notes are being loaded
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                  ),
                                  child: Center(
                                    child: state.hasReachedMax
                                        ? const Text('')
                                        : const SpinKitFadingCircle(
                                            color: AppColors.primary,
                                            size: 40.0,
                                          ),
                                  ),
                                );
                              }
                            },
                          )
                        : NoData(isImage: true),
                  );
                },
              );
            }
            return SizedBox();
          },
        ),
      ],
    );
  }

  Widget priorityLists() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 35.h,
            child: TextField(
              cursorColor: AppColors.greyForgetColor,
              cursorWidth: 1,
              controller: _prioritySearchController,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: (35.h - 20.sp) / 2,
                  horizontal: 10.w,
                ),
                hintText: 'Search...',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.greyForgetColor,
                    // Set your desired color here
                    width: 1.0, // Set the border width if needed
                  ),
                  borderRadius: BorderRadius.circular(
                    20.0,
                  ), // Optional: adjust the border radius
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(
                    color: AppColors.purple,
                    // Border color when TextField is focused
                    width: 1.0,
                  ),
                ),
              ),
              onChanged: (value) {
                context.read<PriorityMultiBloc>().add(
                      SearchPriorityMultis(value),
                    );
              },
            ),
          ),
        ),
        SizedBox(height: 10.h),
        BlocBuilder<PriorityMultiBloc, PriorityMultiState>(
          builder: (context, state) {
            if (state is PriorityLoading || state is PriorityInitial) {
              return SpinKitFadingCircle(size: 40, color: AppColors.primary);
            }
            if (state is PriorityMultiPaginated) {
              ScrollController scrollController = ScrollController();
              scrollController.addListener(() {
                if (scrollController.position.atEdge) {
                  if (scrollController.position.pixels != 0 &&
                      !state.hasReachedMax) {
                    // We're at the bottom
                  }
                }
              });

              return StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setState) {
                  return Container(
                    constraints: BoxConstraints(maxHeight: 900.h),
                    width: 200.w,
                    height: 530.h,
                    child: state.priorityMulti.isNotEmpty
                        ? ListView.builder(
                            controller: scrollController,
                            // physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: state.priorityMulti.length + 1,
                            itemBuilder: (BuildContext context, int index) {
                              if (index < state.priorityMulti.length) {
                                final isSelected = prioritySelectedIdS.contains(
                                  state.priorityMulti[index].id!,
                                );
                                // final isSelected = widget.userId?.contains(state.user[index].id);

                                return InkWell(
                                  splashColor: Colors.transparent,
                                  onTap: () {
                                    // userSelectedname.clear();
                                    // userSelectedIdS.clear();
                                    setState(() {
                                      if (isSelected) {
                                        priorityDisSelected = true;
                                        prioritySelectedIdS.remove(
                                          state.priorityMulti[index].id!,
                                        );
                                        prioritySelectedname.remove(
                                          state.priorityMulti[index].title!,
                                        );
                                        userSelected = false;

                                        // If no users are selected anymore, update filter count
                                        if (prioritySelectedIdS.isEmpty) {
                                          context
                                              .read<WorkFilterCountBloc>()
                                              .add(
                                                WorkUpdateFilterCount(
                                                  filterType: 'priorities',
                                                  isSelected: false,
                                                ),
                                              );
                                        }
                                      } else {
                                        priorityDisSelected = false;
                                        if (!prioritySelectedIdS.contains(
                                          state.priorityMulti[index].id!,
                                        )) {
                                          prioritySelectedIdS.add(
                                            state.priorityMulti[index].id!,
                                          );
                                          prioritySelectedname.add(
                                            state.priorityMulti[index].title!,
                                          );

                                          // Update filter count when first user is selected
                                          if (prioritySelectedIdS.length == 1) {
                                            context
                                                .read<WorkFilterCountBloc>()
                                                .add(
                                                  WorkUpdateFilterCount(
                                                    filterType: 'priorities',
                                                    isSelected: true,
                                                  ),
                                                );
                                          }
                                        }
                                        filterSelectedId =
                                            state.priorityMulti[index].id!;
                                        filterSelectedName = "priorities";
                                      }
                                      // if (isSelected) {
                                      //   priorityDisSelected = true;
                                      //   prioritySelectedIdS.remove(state.priorityMulti[index].id!);
                                      //   prioritySelectedname.remove(state.priorityMulti[index].title!);
                                      //   prioritySelected=false;
                                      // }
                                      // else {
                                      //   priorityDisSelected = false;
                                      //   if (!prioritySelectedIdS
                                      //       .contains(state.priorityMulti[index].id!)) {
                                      //     prioritySelectedIdS
                                      //         .add(state.priorityMulti[index].id!);
                                      //     prioritySelectedname
                                      //         .add(state.priorityMulti[index].title!);
                                      //   }
                                      //   filterSelectedId = state.priorityMulti[index].id!;
                                      //   filterSelectedName = "priority";
                                      // }
                                      _onFilterSelected('priority');
                                    });
                                    BlocProvider.of<StatusMultiBloc>(
                                      context,
                                    ).add(
                                      SelectedStatusMulti(
                                        index,
                                        state.priorityMulti[index].title!,
                                      ),
                                    );
                                    BlocProvider.of<StatusMultiBloc>(
                                      context,
                                    ).add(
                                      ToggleStatusMultiSelection(
                                        state.priorityMulti[index].id!,
                                        state.priorityMulti[index].title!,
                                      ),
                                    );
                                    // context.read<WorkBloc>().add(SearchWork("", filterSelectedId, filterSelectedNmae));
                                    // Future.delayed(Duration(seconds: 1), () {
                                    //   Navigator.pop(context);
                                    // });

                                    // userSelectedIdS.clear();
                                    // userSelectedname.clear();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 2.h,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.purpleShade
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                        ),
                                      ),
                                      width: double.infinity,
                                      height: 35.h,
                                      child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 110.w,
                                                child: CustomText(
                                                  text: state
                                                      .priorityMulti[index]
                                                      .title!,
                                                  fontWeight: FontWeight.w500,
                                                  size: 18.sp,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .textClrChange,
                                                ),
                                              ),
                                              isSelected
                                                  ? const HeroIcon(
                                                      HeroIcons.checkCircle,
                                                      style:
                                                          HeroIconStyle.solid,
                                                      color: AppColors.primary,
                                                    )
                                                  : const SizedBox.shrink(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                // Show a loading indicator when more notes are being loaded
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                  ),
                                  child: Center(
                                    child: state.hasReachedMax
                                        ? const Text('')
                                        : const SpinKitFadingCircle(
                                            color: AppColors.primary,
                                            size: 40.0,
                                          ),
                                  ),
                                );
                              }
                            },
                          )
                        : NoData(),
                  );
                },
              );
            }
            return SizedBox();
          },
        ),
      ],
    );
  }

  Widget workList(stateWork, index, project, date, isLightTheme) {
    return Padding(
      padding: isFirstTimeUSer == true && index == 0
          ? EdgeInsets.zero
          : EdgeInsets.only(bottom: 20.h),
      child: InkWell(
        onTap: () {
          router.push(
            '/workdetails',
            extra: {
              "id": stateWork[index].id,
              "autoNumber": getWorkOrderNumber(stateWork[index]),
              "from": "dashboard",
              "type": initialType,
              "team_id": (stateWork[index].userId?.isNotEmpty == true)
                  ? stateWork[index].userId!.first as int
                  : 0,
              "workModel": stateWork[index],
            },
          );
        },
        child: DismissibleCard(
          direction: DismissDirection.none, // ✅ Disabled swipe actions
          title: stateWork[index].id.toString(),
          confirmDismiss: (DismissDirection direction) async {
            if (direction == DismissDirection.startToEnd) {
              if (context.read<PermissionsBloc>().iseditWork == true) {
                // Navigate to the edit page
                List<String>? userList = [];
                List<String>? clientList = [];
                List<String>? tagList = [];

                if (project.users != null) {
                  for (var user in project.users!) {
                    userList.add(user.firstName!);
                  }
                }

                router.push(
                  '/creatework',
                  extra: {
                    "id": project.id,
                    "fromDetail": false,
                    "isCreate": false,
                    "title": project.title,
                    "desc": project.description,
                    "start": project.startDate ?? "",
                    "end": project.endDate ?? "",
                    "budget": project.budget,
                    'priority': project.priority,
                    'priorityId': project.priorityId,
                    'statusId': project.statusId,
                    'note': project.note,
                    "clientNames": clientList,
                    "userNames": userList,
                    "tagNames": tagList,
                    "userId": project.userId,
                    "enable": project.enable,
                    "tagId": project.tagIds,
                    "clientId": project.clientId,
                    "access": project.taskAccessibility,
                    'status': project.status,
                    "canClientDiscuss": project.clientCanDiscuss,
                    'customFieldsModel': project,
                  },
                );

                // Prevent the widget from being dismissed
                return false;
              } else {
                // No edit permission, prevent swipe
                return false;
              }
            }

            // Handle deletion confirmation
            if (direction == DismissDirection.endToStart) {
              try {
                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible:
                      false, // Prevent dismissing by tapping outside
                  builder: (context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.alertBoxBackGroundColor,
                      title: Text(AppLocalizations.of(context)!.confirmDelete),
                      content: Text(AppLocalizations.of(context)!.areyousure),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true); // Confirm deletion
                          },
                          child: Text(AppLocalizations.of(context)!.ok),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false); // Cancel deletion
                          },
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                      ],
                    );
                  },
                );

                // If user confirmed deletion, handle it here instead of in onDismissed
                if (result == true) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      stateWork.removeAt(index);
                    });
                    _onDeleteWork(project.id);
                  });
                  // Return false to prevent the dismissible from animating
                  return false;
                }

                return false; // Always return false since we handle deletion manually
              } catch (e) {
                if (kDebugMode) {
                  logger.d("Error in dialog: $e");
                }
                return false;
              } // Default to false if dialog is dismissed without action
            }

            return false; // Default case for other directions
          },
          onDismissed: (DismissDirection direction) {
            if (direction == DismissDirection.endToStart &&
                context.read<PermissionsBloc>().isdeleteWork == true) {
              // setState(() {
              //   // project.removeAt(index);
              //   _onDeleteProject(stateWork[index].id);
              // });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  stateWork.removeAt(index);
                });
                _onDeleteWork(project.id);
              });
            } else if (direction == DismissDirection.startToEnd &&
                context.read<PermissionsBloc>().iseditWork == true) {}
          },
          dismissWidget: InkWell(
            onTap: () {
              router.push(
                '/workdetails',
                extra: {
                  "id": stateWork[index].id,
                  "autoNumber": getWorkOrderNumber(stateWork[index]),
                  "from": "dashboard",
                  "type": initialType,
                  "team_id": (stateWork[index].userId?.isNotEmpty == true)
                      ? stateWork[index].userId!.first as int
                      : 0,
                  "workModel": stateWork[index],
                },
              );
            },
            child: Container(
              // height: 250.h,
              decoration: BoxDecoration(
                boxShadow: [
                  isLightTheme
                      ? MyThemes.lightThemeShadow
                      : MyThemes.darkThemeShadow,
                ],
                color: Theme.of(context).colorScheme.containerDark,
                borderRadius: BorderRadius.circular(12),
              ),
              width: double.infinity,
              // color: Colors.yellow,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          text: '#${getWorkOrderNumber(project)}',
                          size: 14.sp,
                          color: Theme.of(context).colorScheme.textClrChange,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // ✅ FIXED: Proper conditional rendering with actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ✅ Conditional: Show action buttons for assigned type, otherwise show pin/favorite
                            initialType == "assigned"
                                ? Row(
                                    children: [
                                      // ✅ Decline Button
                                      InkWell(
                                        onTap: () async {
                                          final confirmed =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                              ),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .alertBoxBackGroundColor,
                                              title: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .confirmDecline,
                                              ),
                                              content: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .declineMessage,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                                  child: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!
                                                        .cancel,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                                  child: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!
                                                        .decline,
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed == true) {
                                            try {
                                              // ✅ 1. Update work order action_status to 6 (declined)
                                              await WorkRepo()
                                                  .updateWorkActionStatus(
                                                id: project.id,
                                                actionStatus:
                                                    6, // Declined status
                                              );

                                              // ✅ 2. Get current user ID
                                              int? myId =
                                                  await HiveStorage.getUserId();
                                              String? myIdString =
                                                  UserIdMapper().getUuid(myId);

                                              // ✅ 3. Insert Work_order_actions record
                                              await WorkRepo()
                                                  .createWorkOrderActions(
                                                woId: project.id,
                                                firstUser: myIdString ?? '',
                                                actionStatus: 6, // Declined
                                                type: 'decline',
                                              );

                                              flutterToastCustom(
                                                msg:
                                                    'Work declined successfully',
                                                color: Colors.red,
                                              );

                                              // Refresh work list
                                              context.read<WorkBloc>().add(
                                                    WorkDashBoardList(
                                                      workType: initialType,
                                                      createType: initialType,
                                                    ),
                                                  );
                                            } catch (e) {
                                              flutterToastCustom(
                                                msg:
                                                    'Failed to decline work: $e',
                                                color: Colors.red,
                                              );
                                            }
                                          }
                                        },
                                        child: Container(
                                          width: 35.w,
                                          height: 30.h,
                                          margin: EdgeInsets.only(right: 8.w),
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              isLightTheme
                                                  ? MyThemes.lightThemeShadow
                                                  : MyThemes.darkThemeShadow,
                                            ],
                                            color: Colors.red.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Center(
                                            child: HeroIcon(
                                              HeroIcons.xMark,
                                              style: HeroIconStyle.solid,
                                              size: 18.sp,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ✅ Assign Button
                                      InkWell(
                                        onTap: () async {
                                          // ✅ 1. Show user selection dialog
                                          final selectedUserData =
                                              await showDialog<
                                                  Map<String, dynamic>>(
                                            context: context,
                                            builder: (dialogContext) {
                                              BlocProvider.of<UserBloc>(
                                                context,
                                              ).add(UserList());
                                              return BlocBuilder<UserBloc,
                                                  UserState>(
                                                builder: (context, state) {
                                                  if (state is UserLoading) {
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  }
                                                  if (state is UserPaginated) {
                                                    return AlertDialog(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          10.r,
                                                        ),
                                                      ),
                                                      backgroundColor: Theme.of(
                                                              context)
                                                          .colorScheme
                                                          .alertBoxBackGroundColor,
                                                      title: Text(
                                                        'Select User to Assign',
                                                      ),
                                                      content: SizedBox(
                                                        width: double.maxFinite,
                                                        child: ListView.builder(
                                                          shrinkWrap: true,
                                                          itemCount:
                                                              state.user.length,
                                                          itemBuilder:
                                                              (context, index) {
                                                            final user = state
                                                                .user[index];
                                                            return ListTile(
                                                              leading:
                                                                  CircleAvatar(
                                                                backgroundImage:
                                                                    user.avatar !=
                                                                            null
                                                                        ? NetworkImage(
                                                                            user.avatar!,
                                                                          )
                                                                        : null,
                                                                child:
                                                                    user.avatar ==
                                                                            null
                                                                        ? Text(
                                                                            user.firstName?[0] ??
                                                                                'U',
                                                                          )
                                                                        : null,
                                                              ),
                                                              title: Text(
                                                                '${user.firstName ?? ''} ${user.lastName ?? ''}',
                                                                style:
                                                                    TextStyle(
                                                                  color: Theme
                                                                          .of(
                                                                    context,
                                                                  )
                                                                      .colorScheme
                                                                      .textClrChange,
                                                                ),
                                                              ),
                                                              onTap: () {
                                                                // Convert user ID to UUID
                                                                String?
                                                                    userUuid =
                                                                    UserIdMapper()
                                                                        .getUuid(
                                                                  user.id!,
                                                                );
                                                                Navigator.of(
                                                                  dialogContext,
                                                                ).pop({
                                                                  'id': user.id,
                                                                  'uuid':
                                                                      userUuid,
                                                                  'name':
                                                                      '${user.firstName ?? ''} ${user.lastName ?? ''}',
                                                                });
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                            dialogContext,
                                                          ).pop(),
                                                          child: Text(
                                                            AppLocalizations.of(
                                                              context,
                                                            )!
                                                                .cancel,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }
                                                  return AlertDialog(
                                                    content: Text(
                                                      'Failed to load users',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                          dialogContext,
                                                        ).pop(),
                                                        child: Text('Close'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );

                                          if (selectedUserData != null) {
                                            // ✅ 2. Show confirmation dialog
                                            final confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    10.r,
                                                  ),
                                                ),
                                                backgroundColor: Theme.of(
                                                        context)
                                                    .colorScheme
                                                    .alertBoxBackGroundColor,
                                                title: Text(
                                                  'Confirm Assignment',
                                                ),
                                                content: Text(
                                                  'Assign this work to ${selectedUserData['name']}?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                      context,
                                                    ).pop(false),
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .cancel,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                      context,
                                                    ).pop(true),
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .assign,
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmed == true) {
                                              try {
                                                // ✅ 3. Get current user ID
                                                int? myId = await HiveStorage
                                                    .getUserId();
                                                String? myIdString =
                                                    UserIdMapper().getUuid(
                                                  myId,
                                                );

                                                // ✅ 4. PATCH: Update work order with action_status AND assigned_to
                                                await WorkRepo()
                                                    .updateWorkAssignment(
                                                  id: project.id,
                                                  actionStatus: 4,
                                                  assignedTo:
                                                      selectedUserData['uuid'],
                                                );

                                                // ✅ 5. INSERT: Create Work_order_actions with next_user
                                                await WorkRepo()
                                                    .createWorkOrderActions(
                                                  woId: project.id,
                                                  firstUser: myIdString ?? '',
                                                  actionStatus: 4,
                                                  type: 'assign',
                                                  nextUser:
                                                      selectedUserData['uuid'],
                                                );

                                                flutterToastCustom(
                                                  msg:
                                                      'Work assigned to ${selectedUserData['name']} successfully',
                                                  color: Colors.blue,
                                                );

                                                // Refresh work list
                                                context.read<WorkBloc>().add(
                                                      WorkDashBoardList(
                                                        workType: initialType,
                                                        createType: initialType,
                                                      ),
                                                    );
                                              } catch (e) {
                                                flutterToastCustom(
                                                  msg:
                                                      'Failed to assign work: $e',
                                                  color: Colors.red,
                                                );
                                              }
                                            }
                                          }
                                        },
                                        child: Container(
                                          width: 35.w,
                                          height: 30.h,
                                          margin: EdgeInsets.only(right: 8.w),
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              isLightTheme
                                                  ? MyThemes.lightThemeShadow
                                                  : MyThemes.darkThemeShadow,
                                            ],
                                            color: Colors.blue.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Center(
                                            child: HeroIcon(
                                              HeroIcons.userGroup,
                                              style: HeroIconStyle.solid,
                                              size: 18.sp,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ✅ Approve Button
                                      InkWell(
                                        onTap: () async {
                                          final confirmed =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                              ),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .alertBoxBackGroundColor,
                                              title: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .confirmApprove,
                                              ),
                                              content: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .approveMessage,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                                  child: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!
                                                        .cancel,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                                  child: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!
                                                        .approve,
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed == true) {
                                            try {
                                              // ✅ 1. Update work order action_status to 2 (approved)
                                              await WorkRepo()
                                                  .updateWorkActionStatus(
                                                id: project.id,
                                                actionStatus:
                                                    2, // Approved status
                                              );

                                              // ✅ 2. Get current user ID
                                              int? myId =
                                                  await HiveStorage.getUserId();
                                              String? myIdString =
                                                  UserIdMapper().getUuid(myId);

                                              // ✅ 3. Insert Work_order_actions record
                                              await WorkRepo()
                                                  .createWorkOrderActions(
                                                woId: project.id,
                                                firstUser: myIdString ?? '',
                                                actionStatus: 2, // Approved
                                                type: 'approve',
                                              );

                                              flutterToastCustom(
                                                msg:
                                                    'Work approved successfully',
                                                color: Colors.green,
                                              );

                                              // Refresh work list
                                              context.read<WorkBloc>().add(
                                                    WorkDashBoardList(
                                                      workType: initialType,
                                                      createType: initialType,
                                                    ),
                                                  );
                                            } catch (e) {
                                              flutterToastCustom(
                                                msg:
                                                    'Failed to approve work: $e',
                                                color: Colors.red,
                                              );
                                            }
                                          }
                                        },
                                        child: Container(
                                          width: 35.w,
                                          height: 30.h,
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              isLightTheme
                                                  ? MyThemes.lightThemeShadow
                                                  : MyThemes.darkThemeShadow,
                                            ],
                                            color: Colors.green.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Center(
                                            child: HeroIcon(
                                              HeroIcons.check,
                                              style: HeroIconStyle.solid,
                                              size: 18.sp,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      SizedBox(width: 5.w),
                                      CustomText(
                                        text: project.createdAt != null
                                            ? parseDateTimeFormat(
                                                project.createdAt!,
                                              )
                                            : date,
                                        size: 12.26,
                                        fontWeight: FontWeight.w300,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.textClrChange,
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            HeroIcon(
                              HeroIcons.clipboardDocumentList,
                              style: HeroIconStyle.outline,
                              color: AppColors.primary,
                            ),
                            CustomText(
                              text: " ${project.budget.toString()} %",
                              size: 14.sp,
                              color: Theme.of(
                                context,
                              ).colorScheme.textClrChange,
                              fontWeight: FontWeight.w700,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildStatus(
                              project.action_status == null
                                  ? 0
                                  : project.action_status!,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 0.h),
                      child: SizedBox(
                        width: 300.w,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              // color: Colors.teal,
                              width: 200.w,
                              height: 40.h,
                              child: CustomText(
                                text: project.title!,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.textClrChange,
                                fontWeight: FontWeight.w700,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    project.description == null || project.description == ""
                        ? const SizedBox.shrink()
                        : SizedBox(height: 5.h),
                    project.description == null || project.description == ""
                        ? SizedBox()
                        : htmlWidget(
                            project.description!,
                            context,
                            height: 38.h,
                          ),
                    SizedBox(height: 5.h),
                    //  statusRow_and_priorityRow
                    SizedBox(
                      // color: Colors.red,
                      width: 300.w,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 0.h),
                        child: statusClientRow(
                          project.status,
                          project.priority,
                          context,
                          false,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.h),
                      child: SizedBox(
                        // color: Colors.tealAccent,
                        height: 60.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  userClientDialog(
                                    context: context,
                                    from: "user",
                                    isFrom: "homescreen",
                                    title: AppLocalizations.of(
                                      context,
                                    )!
                                        .workspace,
                                    list: project.users.isEmpty
                                        ? []
                                        : project.users,
                                  );
                                },
                                child: RowDashboard(
                                  list: project.users!,
                                  title: "user",
                                ),
                              ),
                            ),
                            project.users!.isEmpty
                                ? const SizedBox.shrink()
                                : SizedBox(width: 40.w),
                          ],
                        ),
                      ),
                    ),
                    date != null
                        ? Padding(
                            padding: EdgeInsets.only(top: 5.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 15.w,
                                      // color: Colors.yellow,
                                      child: const HeroIcon(
                                        HeroIcons.calendar,
                                        style: HeroIconStyle.outline,
                                        // color: colors.blueColor,
                                      ),
                                    ),
                                    SizedBox(width: 5.w),
                                    CustomText(
                                      text: date ?? '',
                                      size: 12.26,
                                      fontWeight: FontWeight.w300,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.textClrChange,
                                    ),
                                    SizedBox(width: 10.w),
                                    SizedBox(
                                      width: 15.w,
                                      child: const HeroIcon(
                                        HeroIcons.calendar,
                                        style: HeroIconStyle.outline,
                                      ),
                                    ),
                                    SizedBox(width: 5.w),
                                    CustomText(
                                      text: project.endDate != null
                                          ? parseDateTimeFormat(
                                              project.endDate!,
                                            )
                                          : date,
                                      size: 12.26,
                                      fontWeight: FontWeight.w300,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.textClrChange,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(int status) {
    HeroIcons icon;
    Color color;
    String action_status = 'created';

    switch (status) {
      case 1:
        icon = HeroIcons.checkCircle;
        action_status = 'created';
        color = Colors.orange;

        break;
      case 5:
        icon = HeroIcons.clock;
        action_status = 'accepted';
        color = Colors.blue;

        break;
      case 6:
        icon = HeroIcons.xCircle;
        action_status = 'declined';
        color = Colors.red;

        break;
      case 2:
        icon = HeroIcons.lockClosed;
        action_status = 'approved';
        color = Colors.green;

        break;
      case 4:
        // icon = HeroIcons.arrowUturnLeft;
        icon = HeroIcons.userGroup;
        action_status = 'assigned';
        color = Colors.purple;
        break;
      case 3:
        icon = HeroIcons.xCircle;
        action_status = 'returned';
        color = Colors.red;
        break;
      default:
        icon = HeroIcons.questionMarkCircle;
        action_status = 'waiting';
        color = Colors.grey;
    }

    return Row(
      children: [
        HeroIcon(icon, style: HeroIconStyle.solid, color: color, size: 20),
        SizedBox(width: 6.w),
        CustomText(
          text: action_status.isNotEmpty
              ? '${action_status[0].toUpperCase()}${action_status.substring(1)}'
              : action_status,
          size: 14,
          color: Theme.of(context).colorScheme.textClrChange,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }

  Widget userLists() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 35.h,
            child: TextField(
              cursorColor: AppColors.greyForgetColor,
              cursorWidth: 1,
              controller: _userSearchController,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: (35.h - 20.sp) / 2,
                  horizontal: 10.w,
                ),
                hintText: 'Search...',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors
                        .greyForgetColor, // Set your desired color here
                    width: 1.0, // Set the border width if needed
                  ),
                  borderRadius: BorderRadius.circular(
                    20.0,
                  ), // Optional: adjust the border radius
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(
                    color: AppColors
                        .purple, // Border color when TextField is focused
                    width: 1.0,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchWord = value;
                });
                context.read<UserBloc>().add(SearchUsers(value));
              },
            ),
          ),
        ),
        SizedBox(height: 10.h),
        BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserLoading || state is UserInitial) {
              return SpinKitFadingCircle(size: 40, color: AppColors.primary);
            }
            if (state is UserPaginated) {
              ScrollController scrollController = ScrollController();
              scrollController.addListener(() {
                if (scrollController.position.atEdge) {
                  if (scrollController.position.pixels != 0 &&
                      !state.hasReachedMax) {
                    // We're at the bottom
                    BlocProvider.of<UserBloc>(
                      context,
                    ).add(UserLoadMore(searchWord));
                  }
                }
              });

              return StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setState) {
                  return Container(
                    constraints: BoxConstraints(maxHeight: 900.h),
                    width: 200.w,
                    height: 530,
                    child: state.user.isNotEmpty
                        ? ListView.builder(
                            controller: scrollController,
                            // physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: state.user.length + 1,
                            itemBuilder: (BuildContext context, int index) {
                              if (index < state.user.length) {
                                final isSelected = userSelectedIdS.contains(
                                  state.user[index].id!,
                                );
                                // final isSelected = widget.userId?.contains(state.user[index].id);

                                return InkWell(
                                  splashColor: Colors.transparent,
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        userDisSelected = true;
                                        userSelectedIdS.remove(
                                          state.user[index].id!,
                                        );
                                        userSelectedname.remove(
                                          state.user[index].firstName!,
                                        );
                                        userSelected = false;

                                        // If no users are selected anymore, update filter count
                                        if (userSelectedIdS.isEmpty) {
                                          context
                                              .read<WorkFilterCountBloc>()
                                              .add(
                                                WorkUpdateFilterCount(
                                                  filterType: 'users',
                                                  isSelected: false,
                                                ),
                                              );
                                        }
                                      } else {
                                        userDisSelected = false;
                                        if (!userSelectedIdS.contains(
                                          state.user[index].id!,
                                        )) {
                                          userSelectedIdS.add(
                                            state.user[index].id!,
                                          );
                                          userSelectedname.add(
                                            state.user[index].firstName!,
                                          );

                                          // Update filter count when first user is selected
                                          if (userSelectedIdS.length == 1) {
                                            context
                                                .read<WorkFilterCountBloc>()
                                                .add(
                                                  WorkUpdateFilterCount(
                                                    filterType: 'users',
                                                    isSelected: true,
                                                  ),
                                                );
                                          }
                                        }
                                        filterSelectedId =
                                            state.user[index].id!;
                                        filterSelectedName = "users";
                                      }

                                      _onFilterSelected('users');
                                    });

                                    BlocProvider.of<UserBloc>(context).add(
                                      SelectedUser(
                                        index,
                                        state.user[index].firstName!,
                                      ),
                                    );

                                    BlocProvider.of<UserBloc>(context).add(
                                      ToggleUserSelection(
                                        state.user[index].id!,
                                        state.user[index].firstName!,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 2.h,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.purpleShade
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                        ),
                                      ),
                                      width: double.infinity,
                                      height: 55.h,
                                      child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 0.w,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Column takes up maximum available space
                                              Expanded(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 0.w,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      SafeAvatar(
                                                        imageUrl: state
                                                            .user[index]
                                                            .profile,
                                                        radius: 20,
                                                      ),

                                                      SizedBox(
                                                        width: 5.w,
                                                      ), // Column takes up maximum available space
                                                      Expanded(
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            horizontal: 0.w,
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Flexible(
                                                                    child:
                                                                        CustomText(
                                                                      text: state
                                                                          .user[
                                                                              index]
                                                                          .firstName!,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      size:
                                                                          18.sp,
                                                                      color: isSelected
                                                                          ? AppColors.primary
                                                                          : Theme.of(
                                                                              context,
                                                                            ).colorScheme.textClrChange,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 5.w,
                                                                  ),
                                                                  Flexible(
                                                                    child:
                                                                        CustomText(
                                                                      text: state
                                                                          .user[
                                                                              index]
                                                                          .lastName!,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      size:
                                                                          18.sp,
                                                                      color: isSelected
                                                                          ? AppColors.primary
                                                                          : Theme.of(
                                                                              context,
                                                                            ).colorScheme.textClrChange,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Flexible(
                                                                    child:
                                                                        CustomText(
                                                                      text: state
                                                                          .user[
                                                                              index]
                                                                          .email!,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      size:
                                                                          14.sp,
                                                                      color: isSelected
                                                                          ? AppColors.primary
                                                                          : Theme.of(
                                                                              context,
                                                                            ).colorScheme.textClrChange,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      // Spacer to push the icon to the far right
                                                      // if (isSelected) ...[
                                                      //   SizedBox(
                                                      //       width: 8
                                                      //           .w), // Optional spacing between text and icon
                                                      //   HeroIcon(
                                                      //     HeroIcons.checkCircle,
                                                      //     style: HeroIconStyle.solid,
                                                      //     color: AppColors.purple,
                                                      //   ),
                                                      // ]
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Spacer to push the icon to the far right
                                              if (isSelected) ...[
                                                SizedBox(
                                                  width: 8.w,
                                                ), // Optional spacing between text and icon
                                                HeroIcon(
                                                  HeroIcons.checkCircle,
                                                  style: HeroIconStyle.solid,
                                                  color: AppColors.purple,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                // Show a loading indicator when more notes are being loaded
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                  ),
                                  child: Center(
                                    child: state.hasReachedMax
                                        ? const Text('')
                                        : const SpinKitFadingCircle(
                                            color: AppColors.primary,
                                            size: 40.0,
                                          ),
                                  ),
                                );
                              }
                            },
                          )
                        : NoData(isImage: true),
                  );
                },
              );
            }
            return SizedBox();
          },
        ),
      ],
    );
  }

  Widget requestLists(String type) {
    return Column(
      children: [
        // ✅ Header with type name
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: type.toUpperCase(),
                size: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ],
          ),
        ),

        // ✅ BlocBuilder with fixed height
        SizedBox(
          height: 500.h,
          child: BlocBuilder<WorkBloc, WorkState>(
            builder: (context, state) {
              if (state is WorkLoading || state is WorkInitial) {
                return Center(
                  child: SpinKitFadingCircle(
                    size: 40,
                    color: AppColors.primary,
                  ),
                );
              }

              if (state is WorkPaginated) {
                return state.work.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.work.length,
                        itemBuilder: (BuildContext context, int index) {
                          final work = state.work[index];

                          // ✅ Check if this type is currently selected
                          final isCurrentType = WorksTypeFilter.toLowerCase() ==
                              type.toLowerCase();

                          return InkWell(
                            splashColor: Colors.transparent,
                            onTap: () {
                              // ✅ Navigate to work details instead of filtering
                              router.push(
                                '/workdetails',
                                extra: {
                                  "id": work.id,
                                  "autoNumber": getWorkOrderNumber(work),
                                  "from": "dashboard",
                                  "type": type,
                                  "workModel": work,
                                },
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 4.h,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  // ✅ Highlight if this is the currently previewed type
                                  color: isCurrentType
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.containerDark,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCurrentType
                                        ? AppColors.primary
                                        : AppColors.greyColor.withValues(
                                            alpha: 0.2,
                                          ),
                                  ),
                                ),
                                padding: EdgeInsets.all(12.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomText(
                                            text: work.title ?? 'No title',
                                            fontWeight: FontWeight.w600,
                                            size: 14.sp,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.textClrChange,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              work.action_status ?? 0,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: CustomText(
                                            text: _getStatusText(
                                              work.action_status ?? 0,
                                            ),
                                            size: 10.sp,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(
                                              work.action_status ?? 0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        CustomText(
                                          text: '#${getWorkOrderNumber(work)}',
                                          size: 11.sp,
                                          color: AppColors.greyColor,
                                        ),
                                        if (work.startDate != null) ...[
                                          SizedBox(width: 8.w),
                                          HeroIcon(
                                            HeroIcons.calendar,
                                            style: HeroIconStyle.outline,
                                            size: 12.sp,
                                            color: AppColors.greyColor,
                                          ),
                                          SizedBox(width: 4.w),
                                          CustomText(
                                            text: parseDateTimeFormat(
                                              work.startDate!,
                                            ),
                                            size: 11.sp,
                                            color: AppColors.greyColor,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Center(child: NoData(isImage: true));
              }

              if (state is WorkError) {
                return Center(
                  child: CustomText(
                    text: 'Error: ${state.errorMessage}',
                    color: Colors.red,
                    size: 12.sp,
                  ),
                );
              }

              return Center(child: NoData(isImage: true));
            },
          ),
        ),
      ],
    );
  }

  // ✅ Helper methods
  Color _getStatusColor(int status) {
    switch (status) {
      case 1: // Created
        return Colors.orange;
      case 5: // Accepted
        return Colors.blue;
      case 6: // Declined
        return Colors.red;
      case 2: // Approved/Completed
        return Colors.green;
      case 4: // Assigned
        return Colors.purple;
      case 3: // Returned
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Created';
      case 5:
        return 'Accepted';
      case 6:
        return 'Declined';
      case 2:
        return 'Approved';
      case 4:
        return 'Assigned';
      case 3:
        return 'Returned';
      default:
        return 'Unknown';
    }
  }
}
