import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:ibex/data/localStorage/hive.dart';
import 'package:ibex/utils/widgets/safe_avatar.dart';
import 'package:slidable_bar/slidable_bar.dart';
import 'package:ibex/bloc/permissions/permissions_bloc.dart';
import 'package:ibex/bloc/permissions/permissions_event.dart';
import 'package:ibex/bloc/setting/settings_bloc.dart';
import 'package:ibex/data/model/inspection/inspection.dart';
import 'package:ibex/utils/widgets/custom_dimissible.dart';

import 'package:ibex/utils/widgets/shake_widget.dart';

import '../../bloc/priority/priority_state.dart';

import '../../bloc/inspection_filter/inspection_filter_bloc.dart';
import '../../bloc/inspection_filter/inspection_filter_event.dart';
import '../../bloc/inspection_filter/inspection_filter_state.dart';

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
import '../../bloc/inspection/inspection_bloc.dart';
import '../../bloc/inspection/inspection_event.dart';
import '../../bloc/inspection/inspection_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';
import '../../config/colors.dart';

import '../../routes/routes.dart';
import '../../utils/widgets/my_theme.dart';
import '../../utils/widgets/status_priority_row.dart';

import '../../utils/widgets/back_arrow.dart';
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
import '../home_screen/home_widgets/drawer_widgets.dart';

import '../../../src/generated/i18n/app_localizations.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionScreen extends StatefulWidget {
  final String type; // "open", "request", "completed", "assigned"
  const InspectionScreen({super.key, this.type = "open"});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

double progress = 0.6;

class _InspectionScreenState extends State<InspectionScreen>
    with TickerProviderStateMixin {
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
  bool isExpand = true;

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _userSearchController = TextEditingController();

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
  bool _isSidebarOpen = false; // Track sidebar open/close state

  // ✅ FIX: Don't initialize with hardcoded values
  late String InspectionsType; // Will be set in initState
  late String InspectionsTypeSelected; // Will be set in initState
  late String InspectionsTypeFilter; // Will be set in initState
  late String initialType; // Will be set in initState

  final ValueNotifier<String> filterNameNotifier = ValueNotifier<String>(
    'Priorities',
  ); // Initialize with default value

  final ValueNotifier<String> req_filterNameNotifier = ValueNotifier<String>(
    'Request',
  ); // Initialize with default value

  String filterName = 'Open';
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
    if (kDebugMode) {
      logger.d("fr;hesfreskf $isFirstTimeUSer");
    }
  }

  Future<void> requestForPermission() async {
    await Permission.microphone.request();
  }

  TextEditingController searchController = TextEditingController();
  final GlobalKey _one = GlobalKey();

  int filterSelectedId = 0;
  String filterSelectedName = "";
  String searchWord = "";
  Object is_assigned = {};
  int filterCount = 0;

  bool? isFirst;
  late var filter = [
    'Open',
    'Completed',
    'Date',
  ];

  late List<String> req_filter = [
    'Users',
    'Status',
    'Priorities',
    'Date',
  ];

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  void _filterDialog(BuildContext context, isLightTheme) {
    // ✅ Load works for the selected filter type BEFORE showing dialog
    if (InspectionsTypeSelected == 'request') {
      // Load request works
      _loadRequestTypeInspections('request');
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
                        itemCount: filter.length,
                        itemBuilder: (BuildContext context, int index) {
                          final filterItem = filter[index];

                          return InkWell(
                            onTap: () {
                              setState(() {
                                InspectionsTypeFilter = filterItem;
                                filterNameNotifier.value = filterItem;

                                // ✅ Load works immediately when filter changes
                                if (filterItem.toLowerCase() != 'date') {
                                  _loadRequestTypeInspections(
                                      filterItem.toLowerCase());
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .containerDark,
                                ),
                                child: Row(
                                  children: [
                                    ValueListenableBuilder<String>(
                                      valueListenable:
                                          InspectionsTypeSelected == 'request'
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .textClrChange,
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
                      valueListenable: InspectionsTypeSelected == 'request'
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
                    InkWell(
                      onTap: () {
                        // ✅ CRITICAL: Update InspectionsTypeSelected from InspectionsTypeFilter
                        // InspectionsTypeFilter нь user-ийн сонгосон type (request/open/completed)
                        setState(() {
                          InspectionsTypeSelected = InspectionsTypeFilter;
                          InspectionsType = InspectionsTypeFilter;
                        });

                        // ✅ NOW: Get work type filters based on InspectionsTypeSelected (NOT widget.type!)
                        // String createType =
                        //     _getCreateTypeFromFilter(initialType);
                        // Map<String, dynamic>? actionStatusFilter =
                        //     _getActionStatusFilterFromType(
                        //         InspectionsTypeFilter);

                        // print(
                        //     '🔥 Apply filter - InspectionsTypeSelected: $InspectionsTypeSelected');
                        // print('🔥 Apply filter - wo_status: $InspectionsTypeFilter');
                        // print('🔥 Apply filter - createType: $createType');
                        // print('🔥 Apply filter - initialType: $initialType');
                        // print(
                        //     '🔥 Apply filter - actionStatusFilter: $actionStatusFilter');
                        // print(
                        //     '🔥 Apply filter - userSelectedIdS: $userSelectedIdS');
                        // print(
                        //     '🔥 Apply filter - statusSelectedIdS: $statusSelectedIdS');
                        // print(
                        //     '🔥 Apply filter - prioritySelectedIdS: $prioritySelectedIdS');

                        logger.d(
                            '🔥 Apply filter_initialType: $InspectionsTypeFilter');

                        _getWoStatusIdsFromType(InspectionsTypeFilter)
                            .then((woStatusIds) {
                          logger.d(
                              '🔥 Apply filter - initialType: $InspectionsTypeFilter');

                          // ✅ Apply filters to work dashboard with UPDATED workType
                          BlocProvider.of<InspectionBloc>(context).add(
                            InspectionDashBoardList(
                              workType: InspectionsTypeFilter,
                              createType: InspectionsTypeFilter,
                              // actionStatus: actionStatusFilter,
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
                          context.read<InspectionFilterCountBloc>().add(
                                InspectionResetFilterCount(),
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
                          InspectionsTypeFilter = initialType;
                          InspectionsTypeSelected = initialType;
                          InspectionsType = initialType;

                          // Reset filter name
                          filterNameNotifier.value = 'Open';

                          logger.d(
                              '🔥 Clear filter - Resetting to original workType: ${widget.type}');

                          // ✅ Get woStatusIds and reset
                          _getWoStatusIds().then((woStatusIds) {
                            // ✅ Reset work dashboard with original workType
                            BlocProvider.of<InspectionBloc>(context).add(
                              InspectionDashBoardList(
                                workType: initialType, // ✅ Reset to original
                                createType: initialType,
                                actionStatus: {
                                  "_nin": [1, 6]
                                },
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
          "_nin": [1, 6]
        };
      case "request":
        return {
          "_in": [1, 6]
        };
      case "completed":
        return null;
      case "assigned":
        return {
          "_in": [4]
        };
      default:
        return null;
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
  Future<void> _loadRequestTypeInspections(String type) async {
    String createType =
        _getCreateTypeForFilter(type); // ✅ This will now work correctly
    Map<String, dynamic>? actionStatusFilter =
        _getActionStatusFilterForType(type);
    List<int> woStatusIds = await _getWoStatusIdsForType(type);

    String screenType = widget.type.toLowerCase();
    if (kDebugMode) {
      logger.d('🔥 _loadRequest screenType for filter type: $screenType');
    }
    if (kDebugMode) {
      logger.d('🔥 _loadRequest works for filter type: $type');
    }
    if (kDebugMode) {
      logger.d('🔥 _loadRequest createType: $createType');
    }
    if (kDebugMode) {
      logger.d('🔥 _loadRequest actionStatusFilter: $actionStatusFilter');
    }
    if (kDebugMode) {
      logger.d('🔥 _loadRequest woStatusIds: $woStatusIds');
    }

    BlocProvider.of<InspectionBloc>(context).add(
      InspectionDashBoardList(
        workType: type,
        createType: type,
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
          "_nin": [1, 6]
        };
      case "request":
        return {
          "_in": [1, 6]
        };
      case "completed":
        return null;
      default:
        return null;
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

    // context.read<InspectionFilterCountBloc>().add(InspectionResetFilterCount());
    context.read<TaskFilterCountBloc>().add(TaskResetFilterCount());

    currency = context.read<SettingsBloc>().currencySymbol;
    currencyPosition = context.read<SettingsBloc>().currencyPosition;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ShowCaseWidget.of(context).startShowCase([_one]),
    );

    listenForPermissions();
    BlocProvider.of<PermissionsBloc>(context).add(GetPermissions());

    initialType = widget.type.toLowerCase();

    InspectionsTypeSelected = initialType;
    InspectionsTypeFilter = initialType;
    InspectionsType = initialType;

    if (kDebugMode) {
      logger.d('🔥🔥🔥 [initState] initialType: "$initialType"');
    }
    if (kDebugMode) {
      logger.d('🔥🔥🔥 [initState]: "$InspectionsTypeSelected"');
    }

    // ✅ Set correct filter notifier based on type
    if (InspectionsTypeSelected == 'request') {
      req_filterNameNotifier.value = 'Request';
    } else {
      filterNameNotifier.value = 'open';
    }

    // Type-аасаа хамааруулан Inspection-уудыг дуудах
    _loadInspectionsByType();

    if (!_speechEnabled) {
      _initSpeech();
    }
    _getFirstTimeUser();
  }

  // Type-аасаа хамааруулан Inspection-уудыг дуудах функц
  Future<void> _loadInspectionsByType() async {
    String createType = _getCreateType();
    List<int> woStatusIds = await _getWoStatusIds();

    if (kDebugMode) {
      logger.d('🔥🔥🔥 [_loadInspectionsByType] initialType: $initialType');
    }
    if (kDebugMode) {
      logger.d('🔥🔥🔥 [_loadInspectionsByType] createType: $createType');
    }
    if (kDebugMode) {
      logger.d('🔥🔥🔥 [_loadInspectionsByType] woStatusIds: $woStatusIds');
    }

    BlocProvider.of<InspectionBloc>(context).add(
      InspectionDashBoardList(
        workType: initialType,
        createType: initialType,
        woStatus: woStatusIds,
        actionStatus: null,
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

  Future<List<int>> _getWoStatusIds() async {
    return _getWoStatusIdsFromType(widget.type);
  }

  // Title-г type-аас хамааруулан өөрчлөх
  String _getTitle() {
    return '${AppLocalizations.of(context)!.myInspections} ($totalCount)';
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
    BlocProvider.of<InspectionBloc>(context).add(InspectionDashBoardList(
        workType: initialType, createType: initialType));
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
    context.read<InspectionBloc>().add(SearchInspection(_lastWords, [], []));
  }

  bool isLoadingMore = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      logger.d('InspectionsTypeSelected: "$InspectionsTypeSelected"');
    }
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;

    bool isLightTheme = currentTheme is LightThemeState;

    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerWidgets(
        isExpand: isExpand,
        toggleDrawer: (value) {
          setState(() {
            isExpand = value;
          });
        },
      ),
      floatingActionButton: (context
                  .read<PermissionsBloc>()
                  .iscreateInspection ==
              true)
          ? Padding(
              padding: EdgeInsets.only(bottom: 60.h),
              child: FloatingActionButton(
                isExtended: true,
                onPressed: () {
                  String create_path = '/createworkrequest';
                  if (initialType.toLowerCase() == 'request') {
                    create_path = '/createworkrequest';
                  } else {
                    create_path = '/creatework';
                  }
                  context.read<PermissionsBloc>().iscreateInspection == true
                      ? router.push(
                          create_path,
                          extra: {
                            "id": 0,
                            "isCreate": true,
                            "fromDetail": false,
                            "title": "",
                            "desc": "",
                            'note': "",
                            // "user":task.users,
                            'priority': '1', // ✅ Changed from "" to 1
                            'priorityId': 1, // ✅ Changed from 0 to 1
                            'statusId': 1, // ✅ Changed from 0 to 1
                            'status': '1', // ✅ Changed from "" to 1
                            'woStatus': 1, // ✅ Add default work order status
                            'createdType':
                                initialType.toLowerCase(), // ✅ Add created type
                          },
                        )
                      : null;
                }, // Icon inside the FAB
                backgroundColor: AppColors.primary,
                child: isFirstTimeUSer == true
                    ? Showcase(
                        onTargetClick: () {
                          ShowCaseWidget.of(
                            context,
                          ).completed(_one); // Manually complete the step
                          if (ShowCaseWidget.of(context).activeWidgetId == 1) {
                            onShowCaseCompleted(); // Trigger this after the last showcase step
                          }
                        },
                        key: _one,
                        disposeOnTap:
                            true, // ✅ Required when using onTargetClick

                        titleAlignment: Alignment.center,
                        title: 'Add Inspection',
                        titleTextStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        descTextStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textsub2Color,
                        ),
                        description:
                            'Add new Inspection data by clicking this button.',
                        child: const Icon(
                          Icons.add,
                          color: AppColors.whiteColor,
                        ),
                      )
                    : const Icon(
                        Icons.add,
                        color: AppColors.whiteColor,
                      ), // Background color of the FAB
              ),
            )
          : SizedBox.shrink(),
      backgroundColor: Theme.of(context).colorScheme.backGroundColor,
      body: Stack(
        children: [
          SideBar(
            context: context,
            controller: sideBarController,
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
            underWidget: Container(
              color: Theme.of(context).colorScheme.backGroundColor,
              child: Column(
                children: [
                  BlocBuilder<InspectionBloc, InspectionState>(
                    builder: (context, state) {
                      // ✅ Update totalCount when state changes
                      if (state is InspectionPaginated) {
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .textFieldColor,
                              ),
                              onPressed: () {
                                searchController.clear();
                                context
                                    .read<InspectionBloc>()
                                    .add(SearchInspection('', [], []));
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
                              color:
                                  Theme.of(context).colorScheme.textFieldColor,
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
                        BlocBuilder<InspectionFilterCountBloc,
                            FilterCountState>(
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
                      context
                          .read<InspectionBloc>()
                          .add(SearchInspection(value, [], []));
                    },
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary, // Spinner color
                      backgroundColor:
                          Theme.of(context).colorScheme.backGroundColor,
                      onRefresh: _onRefresh,
                      child:
                          context.read<PermissionsBloc>().isManageInspection ==
                                  true
                              ? BlocConsumer<InspectionBloc, InspectionState>(
                                  listener: (context, state) {
                                    if (state is InspectionPaginated) {
                                      isLoadingMore = false;
                                      setState(() {
                                        totalCount = state.work.length;
                                      });
                                      setState(() {});
                                    }
                                  },
                                  builder: (context, state) {
                                    // print("sfdjnxcvdzxcvgfn  $state");
                                    if (state is InspectionLoading) {
                                      return const NotesShimmer();
                                    } else if (state is InspectionPaginated) {
                                      // print("InspectionPaginated state  ${state.work.length}");
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
                                                  scrollInfo.metrics
                                                      .maxScrollExtent &&
                                              isLoadingMore == false) {
                                            isLoadingMore = true;
                                            setState(() {});
                                            context.read<InspectionBloc>().add(
                                                  InspectionLoadMore(
                                                      searchWord, [], []),
                                                );
                                          }
                                          return false;
                                        },
                                        child: context
                                                    .read<PermissionsBloc>()
                                                    .isManageInspection ==
                                                true
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
                                                        InspectionModel work =
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
                                    } else if (state is InspectionError) {
                                      // Show error message
                                      return const NotesShimmer();
                                    } else if (state is InspectionSuccess) {
                                      logger.d(
                                          "work success state: ${state.work.length}");
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
          BackBar(
            rightOffset: _isSidebarOpen ? 52.w : 0,
          ),
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
                                              .read<InspectionFilterCountBloc>()
                                              .add(
                                                InspectionUpdateFilterCount(
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
                                                .read<
                                                    InspectionFilterCountBloc>()
                                                .add(
                                                  InspectionUpdateFilterCount(
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
                                    // context.read<InspectionBloc>().add(SearchInspection("", filterSelectedId, filterSelectedNmae));
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
                                              .read<InspectionFilterCountBloc>()
                                              .add(
                                                InspectionUpdateFilterCount(
                                                  filterType: 'open',
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
                                                .read<
                                                    InspectionFilterCountBloc>()
                                                .add(
                                                  InspectionUpdateFilterCount(
                                                    filterType: 'priorities',
                                                    isSelected: true,
                                                  ),
                                                );
                                          }
                                        }
                                        filterSelectedId =
                                            state.priorityMulti[index].id!;
                                        filterSelectedName = "open";
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
                                      _onFilterSelected('open');
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
                                    // context.read<InspectionBloc>().add(SearchInspection("", filterSelectedId, filterSelectedNmae));
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

  Widget workList(stateInspection, index, project, date, isLightTheme) {
    // print(
    // 'Rendering inspection_List for index $index, project ID: ${project.toJson()}');
    return Padding(
      padding: isFirstTimeUSer == true && index == 0
          ? EdgeInsets.zero
          : EdgeInsets.only(bottom: 20.h),
      child: DismissibleCard(
        direction: DismissDirection.none, // ✅ Disabled swipe actions
        title: stateInspection[index].id.toString(),
        confirmDismiss: (DismissDirection direction) async {
          if (direction == DismissDirection.startToEnd) {
            if (context.read<PermissionsBloc>().iseditInspection == true) {
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
                          logger.d(
                            "User confirmed deletion - about to pop with true",
                          );
                          Navigator.of(context).pop(true); // Confirm deletion
                        },
                        child: Text(AppLocalizations.of(context)!.ok),
                      ),
                      TextButton(
                        onPressed: () {
                          logger.d(
                            "User cancelled deletion - about to pop with false",
                          );
                          Navigator.of(context).pop(false); // Cancel deletion
                        },
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                    ],
                  );
                },
              );

              // print("Dialog result received: $result");
              // print("About to return from confirmDismiss: ${result ?? false}");

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
          if (direction == DismissDirection.startToEnd &&
              context.read<PermissionsBloc>().iseditInspection == true) {}
        },
        dismissWidget: InkWell(
          onTap: () {
            router.push(
              '/inspectoindetails',
              extra: {
                "id": stateInspection[index].id,
                "from": "dashboard",
                "type": initialType,
                "inspectionModel": stateInspection[index],
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
                        text: "#${project.id.toString()}",
                        size: 14.sp,
                        color: Theme.of(context).colorScheme.textClrChange,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            _buildStatus(project.action_status == null
                                ? 0
                                : project.action_status!)
                          ]),
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
                            HeroIcons.arrowPathRoundedSquare,
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
                          )
                        ],
                      ),
                      // Row(children: [
                      //   _buildStatus(project.action_status == null
                      //       ? 0
                      //       : project.action_status!)
                      // ]),
                    ],
                  ),
                  // name_and_description
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
                            height: 30.h,
                            child: CustomText(
                              text: project.title!,
                              size: 16,
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
                      : htmlWidget(project.description!, context, height: 38.h),
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

                  // dates_and_times
                  // date != null
                  //     ? Padding(
                  //         padding: EdgeInsets.only(top: 5.h),
                  //         child: Row(
                  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //           children: [
                  //             Row(
                  //               children: [
                  //                 SizedBox(
                  //                   width: 15.w,
                  //                   // color: Colors.yellow,
                  //                   child: const HeroIcon(
                  //                     HeroIcons.calendar,
                  //                     style: HeroIconStyle.outline,
                  //                     // color: colors.blueColor,
                  //                   ),
                  //                 ),
                  //                 SizedBox(width: 5.w),
                  //                 CustomText(
                  //                   text: date ?? '',
                  //                   size: 12.26,
                  //                   fontWeight: FontWeight.w300,
                  //                   color: Theme.of(
                  //                     context,
                  //                   ).colorScheme.textClrChange,
                  //                 ),
                  //                 SizedBox(width: 10.w),
                  //                 SizedBox(
                  //                   width: 15.w,
                  //                   child: const HeroIcon(
                  //                     HeroIcons.calendar,
                  //                     style: HeroIconStyle.outline,
                  //                   ),
                  //                 ),
                  //                 SizedBox(width: 5.w),
                  //                 CustomText(
                  //                   text: project.endDate != null
                  //                       ? parseDateTimeFormat(
                  //                           project.endDate!,
                  //                         )
                  //                       : date,
                  //                   size: 12.26,
                  //                   fontWeight: FontWeight.w300,
                  //                   color: Theme.of(
                  //                     context,
                  //                   ).colorScheme.textClrChange,
                  //                 ),
                  //               ],
                  //             ),
                  //           ],
                  //         ),
                  //       )
                  //     : SizedBox.shrink(),

                  SizedBox(height: 20.h),
                  project.picture != null && project.picture!.isNotEmpty
                      ? _buildPicture(project)
                      : SizedBox.shrink(),
                ],
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

  Widget _buildPicture(InspectionModel project) {
    // Build image URL from picture data
    String? imageUrl;
    String? startDate;
    String? endDate;

    startDate = project.startDate != null
        ? parseDateTimeFormat(
            project.startDate!,
          )
        : null;

    endDate = project.endDate != null
        ? parseDateTimeFormat(
            project.endDate!,
          )
        : null;

    if (project.picture != null && project.picture!['id'] != null) {
      imageUrl =
          '$activePictureUrl/${project.picture!['id']}/${project.picture!['id']}';

      // print("🔹 Inspection Picture URL: $imageUrl");
    }

    return Row(
      children: [
        // Picture thumbnail
        if (project.picture != null)
          Container(
            width: 60.w,
            height: 60.h,
            margin: EdgeInsets.only(right: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: imageUrl != null
                  ? Image.network(
                      '$imageUrl',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.broken_image,
                        color: AppColors.primary,
                        size: 30.sp,
                      ),
                    )
                  : Icon(
                      Icons.image,
                      color: AppColors.primary,
                      size: 30.sp,
                    ),
            ),
          ),

        //dates
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 15.w,
                      child: const HeroIcon(
                        HeroIcons.calendar,
                        style: HeroIconStyle.outline,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    CustomText(
                      text: startDate ?? '',
                      size: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(
                        context,
                      ).colorScheme.textClrChange,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    SizedBox(
                      width: 15.w,
                      child: const HeroIcon(
                        HeroIcons.calendar,
                        style: HeroIconStyle.outline,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: CustomText(
                        text: endDate ?? '?',
                        size: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(
                          context,
                        ).colorScheme.textClrChange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                                                .read<
                                                    InspectionFilterCountBloc>()
                                                .add(
                                                  InspectionUpdateFilterCount(
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
                                                  .read<
                                                      InspectionFilterCountBloc>()
                                                  .add(
                                                    InspectionUpdateFilterCount(
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
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // Column takes up maximum available space
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
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
                                                                            .user[index]
                                                                            .firstName!,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        size: 18
                                                                            .sp,
                                                                        color: isSelected
                                                                            ? AppColors.primary
                                                                            : Theme.of(
                                                                                context,
                                                                              ).colorScheme.textClrChange,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width:
                                                                          5.w,
                                                                    ),
                                                                    Flexible(
                                                                      child:
                                                                          CustomText(
                                                                        text: state
                                                                            .user[index]
                                                                            .lastName!,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        size: 18
                                                                            .sp,
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
                                                                            .user[index]
                                                                            .email!,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        size: 14
                                                                            .sp,
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
                                    ));
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
          child: BlocBuilder<InspectionBloc, InspectionState>(
            builder: (context, state) {
              if (state is InspectionLoading || state is InspectionInitial) {
                return Center(
                  child:
                      SpinKitFadingCircle(size: 40, color: AppColors.primary),
                );
              }

              if (state is InspectionPaginated) {
                if (kDebugMode) {
                  logger
                      .d("✅ Loaded ${state.work.length} works for type: $type");
                }

                return state.work.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.work.length,
                        itemBuilder: (BuildContext context, int index) {
                          final work = state.work[index];

                          // ✅ Check if this type is currently selected
                          final isCurrentType =
                              InspectionsTypeFilter.toLowerCase() ==
                                  type.toLowerCase();

                          return InkWell(
                            splashColor: Colors.transparent,
                            onTap: () {
                              // print('🔥🔥🔥 [Inspection Item Tap] type: $type');
                              // print(
                              //     '🔥🔥🔥 [Inspection Item Tap] BEFORE - InspectionsTypeFilter: $InspectionsTypeFilter');
                              // print(
                              //     '🔥🔥🔥 [Inspection Item Tap] BEFORE - InspectionsTypeSelected: $InspectionsTypeSelected');

                              // ✅ Navigate to work details instead of filtering
                              router.push(
                                '/inspectoindetails',
                                extra: {
                                  "id": work.id,
                                  "from": "dashboard",
                                  "type": type,
                                  "inspectionModel": work,
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
                                      : Theme.of(context)
                                          .colorScheme
                                          .containerDark,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCurrentType
                                        ? AppColors.primary
                                        : AppColors.greyColor
                                            .withValues(alpha: 0.2),
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .textClrChange,
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
                                            borderRadius:
                                                BorderRadius.circular(4),
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
                                          text: '#${work.id}',
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
                                                work.startDate!),
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

              if (state is InspectionError) {
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
