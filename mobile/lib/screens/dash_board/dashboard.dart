import 'package:flutter/services.dart'; // Import for SystemNavigator
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../src/generated/i18n/app_localizations.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:ibex/screens/settings/setting_screen.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import 'package:ibex/bloc/theme/theme_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../config/internet_connectivity.dart';
import '../../config/strings.dart';
import '../../utils/widgets/no_internet_screen.dart';
import '../../utils/widgets/bottom_nav_bar.dart';

import 'package:ibex/config/colors.dart';
import '../home_screen/home_screen.dart';
import '../task/all_task_from_dash_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../Work/work_lists.dart';
import '../work/works_diagrams.dart';

class DashBoard extends StatefulWidget {
  final int initialIndex;
  const DashBoard({super.key, this.initialIndex = 0});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late TabController _tabController;
  String? workSpaceTitle;

  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  Future<void> getWorkspace() async {
    var box = await Hive.openBox(userBox);
    workSpaceTitle = box.get('workspace_title');
    if (mounted) {
      BlocProvider.of<AuthBloc>(
        context,
      ).add(WorkspaceUpdate(workspaceTitle: workSpaceTitle));
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _selectedIndex = widget.initialIndex;
    // getWorkspace();
    _initializeTabController();
  }

  void _initializeConnectivity() {
    CheckInternet.initConnectivity().then((List<ConnectivityResult> results) {
      if (mounted && results.isNotEmpty) {
        setState(() {
          _connectionStatus = results;
        });
      }
    });

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (mounted) {
        CheckInternet.updateConnectionStatus(results).then((value) {
          setState(() {
            _connectionStatus = value;
          });
        });
      }
    });
  }

  void _initializeTabController() {
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: _selectedIndex,
    );

    _tabController.addListener(() {
      Future.delayed(const Duration(microseconds: 10)).then((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = _tabController.index;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToIndex(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  final List<Widget> _widgetOptions = [
    const HomeScreen(),
    // const ProjectScreen(),
    const WorksDiagrams(
        is_show_back: false), // ✅ Hide back button on dashboard tab
    const WorkScreen(type: "request", is_show_back: false),
    const Settingscreen(),
    const AllTaskScreen(),
  ];

  Future<bool?> _onWillPop() async {
    if (_selectedIndex == 0) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.alertBoxBackGroundColor,
          title: Text(AppLocalizations.of(context)!.exitApp),
          content: Text(AppLocalizations.of(context)!.doyouwanttoexitApp),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        ),
      );

      if (shouldExit ?? false) {
        SystemNavigator.pop();
        return true;
      }
      return false;
    } else {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;
    final isLightTheme = currentTheme is LightThemeState;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop() ?? false;
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        backgroundColor: Theme.of(context).colorScheme.backGroundColor,
        body: _connectionStatus.contains(ConnectivityResult.none)
            ? const NoInternetScreen()
            : Center(child: _widgetOptions.elementAt(_selectedIndex)),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _selectedIndex,
          isLightTheme: isLightTheme,
          onTap: _navigateToIndex,
        ),
      ),
    );
  }
}
