import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ibex/utils/widgets/custom_text.dart';
import '../../bloc/clients/client_bloc.dart';
import '../../bloc/dashboard_stats/dash_board_stats_event.dart';

import '../../bloc/permissions/permissions_bloc.dart';
import '../../bloc/permissions/permissions_event.dart';
import '../../bloc/work/work_bloc.dart';
import '../../bloc/work/work_event.dart';
import '../../bloc/setting/settings_bloc.dart';
import '../../bloc/setting/settings_event.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/dashboard_stats/dash_board_stats_bloc.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';
import '../../config/colors.dart';
import '../../config/strings.dart';
import '../../data/localStorage/hive.dart';
import '../../src/generated/i18n/app_localizations.dart';
import '../widgets/back_bar.dart';
import 'widgets/total_stats.dart';
import 'package:ibex/utils/widgets/back_arrow.dart';
import 'package:slidable_bar/slidable_bar.dart';
import '../widgets/side_bar.dart';
import '../home_screen/home_widgets/drawer_widgets.dart';

class WorksScreen extends StatefulWidget {
  const WorksScreen({super.key});

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen>
    with SingleTickerProviderStateMixin {
  // final Connectivity _connectivity = Connectivity();
  // late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  int? totalProjects = 0;

  String? usersname;
  int? usersId;
  List<int> userSelectedId = [];
  List<String> userSelectedname = [];
  bool _isSidebarOpen = false; // Track sidebar open/close state

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
      _debounce = Timer(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          // print('Scroll position: ${_scrollController.position.pixels}');
          // print('Has clients: ${_scrollController.hasClients}');
          // print(
          //   'Has content dimensions: ${_scrollController.position.hasContentDimensions}',
          // );
        }
      });
    });
    Future.microtask(() {
      if (mounted && _scrollController.hasClients) {
        setState(() {});
      }
    });
    BlocProvider.of<PermissionsBloc>(context).add(GetPermissions());
    BlocProvider.of<DashBoardStatsBloc>(context).add(StatsList());
    context.read<DashBoardStatsBloc>().totalProject.toString();

    // BlocProvider.of<WorkBloc>(context).add(WorkDashBoardList());
    // BlocProvider.of<SettingsBloc>(
    //   context,
    // ).add(SettingsList("general_settings"));

    _getRole();
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
    BlocProvider.of<DashBoardStatsBloc>(context).add(StatsList());
    context.read<DashBoardStatsBloc>().totalProject.toString();
    BlocProvider.of<WorkBloc>(context).add(WorkDashBoardList());

    _getRole();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getRole() async {
    final fetchedRole = await HiveStorage.getRole();
    setState(() {
      role = fetchedRole; // Assign the fetched role
      // Conditionally dispatch BLoC events based on role
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

    hasGuard = context.read<AuthBloc>().guard;

    return BlocProvider(
      create: (context) => ClientBloc(),
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
        body: Stack(
          children: [
            SideBar(
              context: context,
              controller: sideBarController,
              scaffoldKey: _scaffoldKey,
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
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 90.h),
                                _totalstats(isLightTheme),
                                SizedBox(height: 20.h),
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
              child: SafeArea(child: _appBar(isLightTheme)),
            ),
            BackBar(
              // bottom: MediaQuery.of(context).size.height / 2 - 180.h,
              rightOffset: _isSidebarOpen ? 52.w : 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalstats(isLightTheme) {
    return TotalStats(isLightTheme: isLightTheme);
  }

  Widget _appBar(isLightTheme) {
    return Padding(
      padding: EdgeInsets.only(top: 0.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
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
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: HeroIcon(
              size: 25.sp,
              HeroIcons.bars3BottomLeft,
              style: HeroIconStyle.outline,
              color: Theme.of(context).colorScheme.textClrChange,
            ),
          ),
        ),
      ),
    );
  }
}

Widget titleTask(context, title) {
  return SizedBox(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: CustomText(
        text: title,
        // text: getTranslated(context, 'myweeklyTask'),
        color: Theme.of(context).colorScheme.textClrChange,
        size: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
