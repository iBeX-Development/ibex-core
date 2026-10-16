import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../bloc/clients/client_bloc.dart';
import '../../bloc/clients/client_event.dart';

import '../../bloc/permissions/permissions_bloc.dart';
import '../../bloc/permissions/permissions_event.dart';
import '../../bloc/work/work_bloc.dart';
import '../../bloc/work/work_event.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/dashboard_stats/dash_board_stats_bloc.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';
import '../../bloc/user_profile/user_profile_bloc.dart';
import '../../bloc/user_profile/user_profile_event.dart';
import '../../config/colors.dart';
import '../../config/strings.dart';
import '../../src/generated/i18n/app_localizations.dart';

import 'package:slidable_bar/slidable_bar.dart';
import '../../utils/widgets/custom_text.dart';
import '../widgets/back_bar.dart';
import '../widgets/side_bar.dart';

import '../../screens/home_screen/home_widgets/pie_chart.dart';
import '../home_screen/home_widgets/drawer_widgets.dart';

class WorksDiagrams extends StatefulWidget {
  final bool? is_show_back;
  const WorksDiagrams({super.key, this.is_show_back = true});

  @override
  State<WorksDiagrams> createState() => _WorksDiagrams();
}

class _WorksDiagrams extends State<WorksDiagrams>
    with SingleTickerProviderStateMixin {
  // final Connectivity _connectivity = Connectivity();
  // late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  int? totalProjects = 0;
  bool _isSidebarOpen = false; // Track sidebar open/close state
  String? usersname;
  int? usersId;
  List<int> userSelectedId = [];
  List<String> userSelectedname = [];

  int upcomingDays = 7;
  int upcomingMonths = 30;
  int days = 0;
  String? weekMonth;

  String? hasGuard;
  String searchWord = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _buyNowController;
  final SlidableBarController sideBarController = SlidableBarController(
    initialStatus: false,
  );
  // Add ScrollController
  bool isExpand = false;

  void toggleDrawer(bool expanded) {
    setState(() {
      isExpand = expanded;
    });
  }

  void getWorkSpace() async {
    var box = await Hive.openBox(userBox);
    workSpaceTitle = box.get('workspace_title');
  }

  String? fromDate;
  int? statusPending;
  String? toDate;
  bool? isLoading = true;
  String? role;
  bool? isConnectedToInternet;
  StreamSubscription? _internetConnectionStreamSubscription;
  String? photo;
  Timer? _debounce;

  @override
  void initState() {
    _todayTask();
    _buyNowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scrollController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 100), () {});
    });
    Future.microtask(() {
      if (mounted && _scrollController.hasClients) {
        setState(() {});
      }
    });
    BlocProvider.of<PermissionsBloc>(context).add(GetPermissions());
    context.read<DashBoardStatsBloc>().totalProject.toString();

    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buyNowController.dispose();
    _scrollController.dispose(); // Dispose of the controller
    _internetConnectionStreamSubscription?.cancel();
    super.dispose();
  }

  _todayTask() {
    DateTime now = DateTime.now();
    fromDate = DateFormat('yyyy-MM-dd').format(now);

    DateTime oneWeekFromNow = now.add(const Duration(days: 7));
    toDate = DateFormat('yyyy-MM-dd').format(oneWeekFromNow);
  }

  Future<void> _onRefresh() async {
    _todayTask();

    setState(() {
      isLoading = true;
    });
    BlocProvider.of<PermissionsBloc>(context).add(GetPermissions());
    context.read<DashBoardStatsBloc>().totalProject.toString();
    BlocProvider.of<WorkBloc>(context).add(WorkDashBoardList());

    setState(() {
      isLoading = false;
    });
  }

  String? photoWidget;
  String? email;
  String? roleInUser;
  String? firstNameUser;
  String? lastNameUSer;
  String? workSpaceTitle;
  bool isExpanded = false;
  bool projectChart = false;
  bool taskChart = false;
  void handleIsWorkChart(bool status) {
    setState(() {
      // userId = id;
      projectChart = status;
    });
  }

  void handleIsTaskChart(bool status) {
    setState(() {
      // userId = id;
      taskChart = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;
    bool isLightTheme = currentTheme is LightThemeState;

    _todayTask();
    // BlocProvider.of<UserProfileBloc>(context).add(ProfileListGet());
    hasGuard = context.read<AuthBloc>().guard;
    context.read<AuthBloc>().guard;
    context.read<AuthBloc>().hasAllDataAccess;
    context.read<AuthBloc>().userId;
    // _getRole();
    return BlocProvider(
      create: (context) => ClientBloc()..add(ClientList()),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: DrawerWidgets(isExpand: isExpand, toggleDrawer: toggleDrawer),
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

              underWidget: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(overscroll: false),
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.backGroundColor,
                  onRefresh: _onRefresh,
                  child: Builder(
                    builder: (context) {
                      bool hasScrollPosition = _scrollController.hasClients &&
                          _scrollController.position.hasContentDimensions;
                      return Scrollbar(
                        controller: _scrollController,
                        thickness: hasScrollPosition ? 4.0 : 0.0,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics:
                              const ClampingScrollPhysics(), // Prevent overscroll
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              // maxHeight: 200.h,
                              minHeight: MediaQuery.of(context).size.height,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 90.h),
                                Row(
                                  children: [
                                    SizedBox(width: 9.w),
                                    Expanded(
                                      child: DoughnutChart(
                                        type: "project",
                                        title: AppLocalizations.of(
                                          context,
                                        )!
                                            .workstats,
                                        isReverse: false,
                                        onChangeForProject: handleIsWorkChart,
                                        onChangeForTask: (bool _) {},
                                      ),
                                    ),
                                    Expanded(
                                      child: DoughnutChart(
                                        type: "task",
                                        title: AppLocalizations.of(
                                          context,
                                        )!
                                            .taskectstats,
                                        isReverse: false,
                                        onChangeForTask: handleIsTaskChart,
                                        onChangeForProject: (bool _) {},
                                      ),
                                    ),
                                    SizedBox(width: 9.w),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                  ),
                                  child: DoughnutChart(
                                    title: AppLocalizations.of(
                                      context,
                                    )!
                                        .todosoverview,
                                    isReverse: true,
                                    onChangeForProject: (bool _) {},
                                    onChangeForTask: (bool _) {},
                                  ),
                                ),
                                SizedBox(height: 120.h),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: -10.h,
              left: 0,
              right: 0,
              // bottom: 0.h,
              child: SafeArea(child: _appBar(isLightTheme)),
            ),
            if (widget.is_show_back ??
                true) // ✅ Only show BackBar when is_show_back is true
              BackBar(isSidebarOpen: _isSidebarOpen),
          ],
        ),
      ),
    );
  }

  Widget _appBar(isLightTheme) {
    return Padding(
      padding: EdgeInsets.only(top: 0.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                InkWell(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () {
                    setState(() {
                      isExpand = false;
                    });
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: Container(
                    height: 80.h,
                    width: 80.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: HeroIcon(
                      size: 25.sp,
                      HeroIcons.bars3BottomLeft,
                      style: HeroIconStyle.outline,
                      color: Theme.of(context).colorScheme.textClrChange,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                CustomText(
                  text: AppLocalizations.of(context)!.statistics,
                  fontWeight: FontWeight.w700,
                  size: 18,
                  color: Theme.of(context).colorScheme.textClrChange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
