import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ibex/bloc/comments/comments_bloc.dart';

import '../../../src/generated/i18n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ibex/bloc/allowance_single/single_allowance_event.dart';
import 'package:ibex/bloc/contracts/contracts_event.dart';
import 'package:ibex/bloc/contracts_type/contracts_type_event.dart';
import 'package:ibex/bloc/expense/expense_bloc.dart';
import 'package:ibex/bloc/expense_filter/expense_filter_bloc.dart';
import 'package:ibex/bloc/expense_type/expense_type_event.dart';
import 'package:ibex/bloc/interviews/interviews_event.dart';
import 'package:ibex/bloc/items/item_event.dart';
import 'package:ibex/bloc/notes/notes_bloc.dart';
import 'package:ibex/bloc/news/news_bloc.dart';
import 'package:ibex/bloc/payment/payment_event.dart';
import 'package:ibex/bloc/payment_method/payment_method_event.dart';
import 'package:ibex/bloc/payslip/payslip/payslip/payslip_bloc.dart';
import 'package:ibex/bloc/payslip/payslip/payslip/payslip_event.dart';
import 'package:ibex/bloc/permissions/permissions_bloc.dart';
import 'package:ibex/bloc/permissions/permissions_event.dart';
import 'package:ibex/bloc/auth/auth_bloc.dart';
import 'package:ibex/bloc/task/task_event.dart';
import 'package:ibex/bloc/worktask/task_event.dart';
import 'package:ibex/bloc/inspectiontask/task_event.dart';
import 'package:ibex/bloc/taxes/tax_event.dart';
import 'package:ibex/bloc/theme/theme_event.dart';
import 'package:ibex/bloc/user/user_bloc.dart';
import 'package:ibex/routes/routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ibex/screens/widgets/firebase_services.dart';
import '../bloc/allowance_single/single_allowance_bloc.dart';
import '../bloc/candidate/candidates_bloc.dart';
import '../bloc/candidate/candidates_event.dart';
import '../bloc/candidate_attachment/candidate_attachment_bloc.dart';
import '../bloc/candidate_interviews/candidate_interviews_bloc.dart';
import '../bloc/candidate_status/candidates_status_bloc.dart';
import '../bloc/candidate_status/candidates_status_event.dart';
import '../bloc/contracts/contracts_bloc.dart';
import '../bloc/contracts_type/contracts_type_bloc.dart';
import '../bloc/custom_fields/custom_field_bloc.dart';
import '../bloc/custom_fields/custom_field_event.dart';
import '../bloc/deduction_single/single_deduction_bloc.dart';
import '../bloc/deduction_single/single_deduction_event.dart';
import '../bloc/estimate_invoice/estimateInvoice_bloc.dart';
import '../bloc/estimate_invoice/estimateInvoice_event.dart';
import '../bloc/estimate_invoice_filter/estimate_invoice_filter_bloc.dart';
import '../bloc/estimate_invoice_item_list/estimateInvoice_list_bloc.dart';
import '../bloc/interviews/interviews_bloc.dart';
import '../bloc/lead_id/leadid_bloc.dart';
import '../bloc/leads/leads_bloc.dart';
import '../bloc/leads_source/lead_source_bloc.dart';
import '../bloc/leads_stage/lead_stage_bloc.dart';
import '../bloc/leads_stage/lead_stage_event.dart';
import '../bloc/payment/payment_bloc.dart';
import '../bloc/payment_method/payment_method_bloc.dart';
import '../bloc/payslip/allowances/allowance_bloc.dart';
import '../bloc/payslip/deductions/deduction_bloc.dart';
import '../bloc/status/status_bloc.dart';
import '../bloc/taxes/tax_bloc.dart';
import '../bloc/units/unit_bloc.dart';
import '../bloc/units/unit_event.dart';
import '../bloc/expense/expense_event.dart';
import '../bloc/client_id/clientid_bloc.dart';
import '../bloc/clients/client_event.dart';
import '../bloc/expense_type/expense_type_bloc.dart';
import '../bloc/income_expense/income_expense_bloc.dart';
import '../bloc/income_expense/income_expense_event.dart';
import '../bloc/items/item_bloc.dart';
import '../bloc/leave_req_dashboard/leave_req_dashboard_bloc.dart';
import '../bloc/leave_req_dashboard/leave_req_dashboard_event.dart';
import '../bloc/clients/client_bloc.dart';
import '../bloc/notifications/push_notification/notification_push_bloc.dart';
import '../bloc/notifications/system_notification/notification_bloc.dart';
import '../bloc/priority/priority_bloc.dart';
import '../bloc/priority/priority_event.dart';
import '../bloc/privacy_aboutus_termscond/privacy_aboutus_termscond_bloc.dart';
import '../bloc/single_client/single_client_bloc.dart';

//project
import '../bloc/project/project_bloc.dart';
import '../bloc/project_discussion/project_media/project_media_bloc.dart';
import '../bloc/project_discussion/project_milestone/project_milestone_bloc.dart';
import '../bloc/project_discussion/project_milestone/project_milestone_event.dart';
import '../bloc/project_discussion/project_milestone_filter/project_milestone_filter_bloc.dart';
import '../bloc/project_discussion/project_timeline/status_timeline_bloc.dart';
import '../bloc/project_filter/project_filter_bloc.dart';
import '../bloc/project_id/projectid_bloc.dart';
import '../bloc/project_multi/project_multi_bloc.dart';
import '../bloc/single_select_project/single_select_project_bloc.dart';
import '../bloc/single_select_project/single_select_project_event.dart';

import '../bloc/roles/role_bloc.dart';
import '../bloc/roles_multi/role_multi_bloc.dart';
import '../bloc/setting/settings_bloc.dart';
import '../bloc/tags/tags_bloc.dart';
import '../bloc/tags/tags_event.dart';
import '../bloc/task_discussion/task_media/task_media_bloc.dart';
import '../bloc/task_discussion/task_timeline/task_status_timeline_bloc.dart';
import '../bloc/task_filter/task_filter_bloc.dart';
import '../bloc/task_id/taskid_bloc.dart';

import '../bloc/worktask_discussion/task_media/task_media_bloc.dart';
import '../bloc/worktask_discussion/task_timeline/task_status_timeline_bloc.dart';
import '../bloc/worktask_filter/task_filter_bloc.dart';

// inspectiontask
import '../bloc/inspectiontask_discussion/task_media/task_media_bloc.dart';
import '../bloc/inspectiontask_discussion/task_timeline/task_status_timeline_bloc.dart';
import '../bloc/inspectiontask_filter/task_filter_bloc.dart';
import '../bloc/inspectiontask_id/taskid_bloc.dart';

import '../bloc/todos/todos_bloc.dart';
import '../bloc/user/user_event.dart';
import '../bloc/user_id/userid_bloc.dart';
import '../bloc/workspace/workspace_bloc.dart';
import '../bloc/location/location_bloc.dart';
import '../bloc/activity_log/activity_log_bloc.dart';
import '../bloc/dashboard_stats/dash_board_stats_bloc.dart';
import '../bloc/languages/language_switcher_bloc.dart';
import '../bloc/languages/language_switcher_state.dart';
import '../bloc/multi_tag/tag_multi_bloc.dart';
import '../bloc/priority_multi/priority_multi_bloc.dart';
import '../bloc/profile_picture/profile_pic_bloc.dart';

import '../bloc/single_user/single_user_bloc.dart';
import '../bloc/status/status_event.dart';
import '../bloc/status_multi/status_multi_bloc.dart';
import '../bloc/task/task_bloc.dart';
import '../bloc/worktask/task_bloc.dart';
import '../bloc/inspectiontask/task_bloc.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_state.dart';
import '../bloc/user_profile/user_profile_bloc.dart';
import '../bloc/workspace/workspace_event.dart';
import '../bloc/location/location_event.dart';
import 'dart:async';
import '../data/localStorage/hive.dart';
import '../data/repositories/comments/comment_repo.dart';

// works
import '../bloc/work/work_bloc.dart';
import '../bloc/work_discussion/work_media/work_media_bloc.dart';
import '../bloc/work_discussion/work_milestone/work_milestone_bloc.dart';
import '../bloc/work_discussion/work_milestone/work_milestone_event.dart';
import '../bloc/work_discussion/work_milestone_filter/work_milestone_filter_bloc.dart';
import '../bloc/work_discussion/work_timeline/status_timeline_bloc.dart';
import '../bloc/work_filter/work_filter_bloc.dart';
import '../bloc/work_id/workid_bloc.dart';
import '../bloc/work_multi/work_multi_bloc.dart';
import '../bloc/single_select_work/single_select_work_bloc.dart';
import '../bloc/single_select_work/single_select_work_event.dart';

// inspection
import '../bloc/inspection/inspection_bloc.dart';
import '../bloc/inspection_discussion/inspection_media/inspection_media_bloc.dart';
import '../bloc/inspection_discussion/inspection_timeline/status_timeline_bloc.dart';
import '../bloc/inspection_filter/inspection_filter_bloc.dart';
import '../bloc/inspection_id/inspectionid_bloc.dart';
import '../bloc/inspection_multi/inspection_multi_bloc.dart';
import '../bloc/inspection_discussion/inspection_part/inspection_part_bloc.dart';
import '../bloc/inspection_discussion/inspection_part/inspection_part_event.dart';
import '../bloc/inspection_discussion/inspection_trade/inspection_trade_bloc.dart';
import '../bloc/inspection_discussion/inspection_trade/inspection_trade_event.dart';

// asset
import '../bloc/asset/asset_bloc.dart';
import '../bloc/asset/asset_event.dart';

//workparts
import '../bloc/work_discussion/work_part/work_part_bloc.dart';
import '../bloc/work_discussion/work_part/work_part_event.dart';
import '../bloc/work_discussion/work_part_filter/work_part_filter_bloc.dart';

//worktrade
import '../bloc/work_discussion/work_trade/work_trade_bloc.dart';
import '../bloc/work_discussion/work_trade/work_trade_event.dart';
import '../bloc/work_discussion/work_trade_filter/work_trade_filter_bloc.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// import '../bloc/work_discussion/work_part_filter/work_part_filter_event.dart';
class MyApp extends StatefulWidget {
  final bool isDarkTheme;

  const MyApp({super.key, required this.isDarkTheme});

  @override
  State<MyApp> createState() => _MyAppState();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  AppLifecycleState? _lastLifecycleState;
  bool _showLockScreen = false;
  bool defaultBiometric = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    getBiometric();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginAndSecure();
    _initializeNotification();
  }

  Future<String?> _IsLoggedIn() async {
    final String? token = await HiveStorage.getToken();
    return token;
  }

  Future<void> _checkLoginAndSecure() async {
    final String? token = await _IsLoggedIn();

    if (token == null || token.isEmpty) {
      navigatorKey.currentState?.pushReplacementNamed('/login');
      return;
    }

    // ✅ Check if app was closed for too long (when app is reopened after being killed)
    final lastActiveTime = await HiveStorage.getLastActiveTime();
    if (lastActiveTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTime - lastActiveTime;
      const inactivityThreshold = 5 * 60 * 1000; // 5 minutes in milliseconds

      if (timeDifference > inactivityThreshold) {
        await HiveStorage.clearToken();
        navigatorKey.currentState?.pushReplacementNamed('/login');
        return;
      } else {}
    }

    defaultBiometric = await HiveStorage.getBiometricAuth();
  }

  @override
  void dispose() {
    // ✅ Save timestamp when widget is being disposed
    HiveStorage.saveLastActiveTime(
      DateTime.now().millisecondsSinceEpoch,
    ).catchError((e) {
      if (kDebugMode) {
        logger.d('❌ Error saving time on dispose: $e');
      }
    });
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> getBiometric() async {
    defaultBiometric = await HiveStorage.getBiometricAuth();
    return defaultBiometric;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    try {
      await getBiometric();
      _lastLifecycleState = state;

      if (state == AppLifecycleState.inactive) {
        // ✅ Save timestamp as early as possible when app becomes inactive
        try {
          await HiveStorage.saveLastActiveTime(
            DateTime.now().millisecondsSinceEpoch,
          );
        } catch (e) {
          if (kDebugMode) {
            logger.d('❌ Error saving last active time on inactive: $e');
          }
        }
      }

      if (state == AppLifecycleState.paused) {
        // ✅ Save timestamp when app goes to background (double save for safety)
        try {
          await HiveStorage.saveLastActiveTime(
            DateTime.now().millisecondsSinceEpoch,
          );
        } catch (e) {
          if (kDebugMode) {
            logger.d('❌ Error saving last active time: $e');
          }
        }
        if (mounted) {
          setState(() {
            _showLockScreen = true;
          });
        }
      }

      if (state == AppLifecycleState.detached ||
          state == AppLifecycleState.hidden) {
        // ✅ App is being terminated, save timestamp one last time
        try {
          await HiveStorage.saveLastActiveTime(
            DateTime.now().millisecondsSinceEpoch,
          );
        } catch (e) {
          if (kDebugMode) {
            logger.d('❌ Error saving last active time on detached: $e');
          }
        }
      }

      if (state == AppLifecycleState.resumed) {
        // ✅ Check if app was closed for too long FIRST
        try {
          final lastActiveTime = await HiveStorage.getLastActiveTime();
          if (lastActiveTime != null) {
            final currentTime = DateTime.now().millisecondsSinceEpoch;
            final timeDifference = currentTime - lastActiveTime;
            const inactivityThreshold =
                5 * 60 * 1000; // 5 minutes in milliseconds

            if (timeDifference > inactivityThreshold) {
              if (mounted) {
                setState(() {
                  _showLockScreen = false;
                });
              }
              await HiveStorage.clearToken();
              // ✅ Use Future.delayed to ensure setState completes
              if (mounted) {
                Future.delayed(Duration.zero, () {
                  if (mounted && navigatorKey.currentState?.mounted == true) {
                    navigatorKey.currentState?.pushReplacementNamed('/login');
                  }
                });
              }
              return;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            logger.d('❌ Error checking timeout: $e');
          }
        }

        // ✅ Reload permissions when app resumes
        try {
          if (mounted && context.mounted) {
            context.read<PermissionsBloc>().add(GetPermissions());
          }
        } catch (e) {
          if (kDebugMode) {
            logger.d('❌ Error reloading permissions: $e');
          }
        }

        // ✅ Then check biometric if enabled
        if (_showLockScreen && defaultBiometric) {
          final auth = LocalAuthentication();
          try {
            final canCheck = await auth.canCheckBiometrics;
            final supported = await auth.isDeviceSupported();

            if (canCheck && supported) {
              _authenticateUser();
            } else {
              if (mounted) {
                setState(() {
                  _showLockScreen = false;
                });
              }
            }
          } catch (e) {
            if (kDebugMode) {
              logger.d('❌ Error checking biometrics: $e');
            }
            if (mounted) {
              setState(() {
                _showLockScreen = false;
              });
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('❌ Error in didChangeAppLifecycleState: $e');
      }
    }
  }

  Future<void> _authenticateUser() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool isAuthenticated = false;

    try {
      final canCheckBiometrics = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();

      if (defaultBiometric && canCheckBiometrics && isSupported) {
        isAuthenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to continue',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
      } else {
        isAuthenticated = true;
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('Authentication error: $e');
      }
      isAuthenticated = false;
    }

    setState(() {
      _showLockScreen = !isAuthenticated;
    });

    if (!isAuthenticated) {
      navigatorKey.currentState?.pushReplacementNamed('/login');
    }
  }

  Future<void> _initializeNotification() async {
    await NotificationService().initFirebaseMessaging(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ThemeBloc.loadTheme(),
      builder: (context, snapshot) {
        final isDarkTheme = snapshot.data ?? false;
        return MultiProvider(
          providers: [
            BlocProvider(
              create: (context) {
                final themeBloc = ThemeBloc();
                themeBloc.add(InitialThemeEvent(isDarkTheme));
                return themeBloc;
              },
            ),
            BlocProvider(create: (_) => LanguageBloc.instance),
            BlocProvider(create: (_) => AuthBloc()),
            BlocProvider(create: (_) => ProfilePicBloc()),
            BlocProvider(create: (_) => TaskBloc()..add(AllTaskListOnTask())),
            BlocProvider(
              create: (_) => WorkTaskBloc()..add(AllWorkTaskListOnTask()),
            ),
            BlocProvider(
              create: (_) =>
                  InspectionTaskBloc()..add(AllInspectionTaskListOnTask()),
            ),
            BlocProvider(create: (_) => UserBloc()..add(UserList())),
            BlocProvider(create: (_) => AssetBloc()..add(AssetList())),
            BlocProvider(
              create: (_) =>
                  EstinateInvoiceBloc()
                    ..add(EstinateInvoiceLists([], [], [], [], "", "")),
            ),
            BlocProvider(create: (_) => NotesBloc()),
            BlocProvider(create: (_) => TodosBloc()),
            BlocProvider(create: (_) => ProjectBloc()),
            BlocProvider(create: (_) => WorkBloc()),
            BlocProvider(create: (_) => InspectionBloc()),
            BlocProvider(create: (_) => SingleClientBloc()),
            BlocProvider(create: (_) => ActivityLogBloc()),
            // BlocProvider(create: (_) => WorkAnniversaryBloc()),
            // BlocProvider(create: (_) => LeaveRequestBloc()),
            BlocProvider(create: (_) => ClientidBloc()),
            BlocProvider(
              create: (_) =>
                  CandidatesStatusBloc()..add(CandidatesStatusList()),
            ),
            BlocProvider(create: (_) => TaskFilterCountBloc()),
            BlocProvider(create: (_) => TaskidBloc()),
            BlocProvider(create: (_) => WorkTaskFilterCountBloc()),
            BlocProvider(create: (_) => InspectionTaskFilterCountBloc()),
            BlocProvider(create: (_) => InspectionTaskidBloc()),
            BlocProvider(
              create: (_) => CandidatesBloc()..add(CandidatesList()),
            ),
            BlocProvider(
              create: (context) =>
                  ChartBloc()..add(FetchChartData(startDate: "", endDate: "")),
            ),
            BlocProvider(create: (_) => WorkspaceBloc()..add(WorkspaceList())),
            BlocProvider(create: (_) => LocationBloc()..add(LocationList())),
            BlocProvider(create: (_) => NewsBloc()),
            // BlocProvider(create: (_) => MeetingBloc()),
            BlocProvider(create: (_) => NotificationBloc()),
            BlocProvider(create: (_) => NotificationPushBloc()),
            BlocProvider(create: (_) => TaskMediaBloc()),
            BlocProvider(create: (_) => WorkTaskMediaBloc()),
            BlocProvider(create: (_) => InspectionTaskMediaBloc()),
            BlocProvider(create: (_) => ItemInvoiceBloc()),
            BlocProvider(create: (_) => TaskStatusTimelineBloc()),
            BlocProvider(create: (_) => WorkTaskStatusTimelineBloc()),
            BlocProvider(create: (_) => InspectionTaskStatusTimelineBloc()),
            BlocProvider(create: (_) => UserProfileBloc()),
            BlocProvider(create: (_) => UseridBloc()),
            BlocProvider(create: (_) => EstimateInvoiceFilterCountBloc()),
            BlocProvider(
              create: (_) => PaymentMethodBloc()..add(PaymentMethdLists()),
            ),
            BlocProvider(create: (_) => TaxBloc()..add(TaxesList())),
            BlocProvider(
              create: (_) => ExpenseBloc()..add(ExpenseLists([], [], "", "")),
            ),
            BlocProvider(
              create: (_) => PaymentBloc()
                ..add(
                  PaymentLists(
                    userIds: [],
                    invoiceIds: [],
                    paymentMethodIds: [],
                    fromDate: '',
                    toDate: '',
                  ),
                ),
            ),
            BlocProvider(
              create: (_) => ExpenseTypeBloc()..add(ExpenseTypeLists()),
            ),
            BlocProvider(create: (_) => ProjectidBloc()),
            BlocProvider(create: (_) => WorkidBloc()),
            BlocProvider(create: (_) => InspectionidBloc()),

            BlocProvider<FilterCountBloc>(
              create: (context) => FilterCountBloc(),
            ),
            BlocProvider<WorkFilterCountBloc>(
              create: (context) => WorkFilterCountBloc(),
            ),
            BlocProvider<InspectionFilterCountBloc>(
              create: (context) => InspectionFilterCountBloc(),
            ),

            BlocProvider(
              create: (_) =>
                  LeaveReqDashboardBloc()
                    ..add(WeekLeaveReqListDashboard([], 7, [])),
            ),
            BlocProvider(create: (_) => RoleBloc()),
            BlocProvider(create: (_) => ExpenseFilterCountBloc()),
            BlocProvider(create: (_) => RoleMultiBloc()),
            BlocProvider(create: (_) => TagsBloc()..add(TagsList())),
            BlocProvider(create: (_) => PermissionsBloc()),
            BlocProvider(create: (_) => SingleUserBloc()),
            BlocProvider(create: (_) => ClientBloc()..add(ClientList())),
            BlocProvider(create: (_) => FilterCountOfMilestoneBloc()),

            BlocProvider(create: (_) => WorkFilterCountOfMilestoneBloc()),
            BlocProvider(create: (_) => WorkFilterCountOfPartBloc()),
            BlocProvider(create: (_) => WorkFilterCountOfTradeBloc()),

            // BlocProvider(create: (_) => BirthdayBloc()),
            // BlocProvider(create: (_) => PaymentFilterCountBloc()),
            BlocProvider(create: (_) => DashBoardStatsBloc()),
            BlocProvider(create: (_) => SingleSelectProjectBloc()),
            BlocProvider(create: (_) => SingleSelectWorkBloc()),
            BlocProvider(create: (_) => SettingsBloc()),
            BlocProvider(create: (_) => ItemsBloc()..add(ItemsList())),
            BlocProvider(create: (_) => UnitBloc()..add(UnitsList())),
            BlocProvider(
              create: (_) => ProjectMilestoneBloc()..add(MileStoneList()),
            ),
            BlocProvider(
              create: (_) => WorkMilestoneBloc()..add(WorkMileStoneList()),
            ),
            BlocProvider(create: (_) => WorkPartBloc()..add(WorkPartList())),
            BlocProvider(create: (_) => WorkTradeBloc()..add(WorkTradeList())),
            BlocProvider(
              create: (_) => InspectionPartBloc()..add(InspectionPartList()),
            ),
            BlocProvider(
              create: (_) => InspectionTradeBloc()..add(InspectionTradeList()),
            ),
            BlocProvider(create: (_) => StatusMultiBloc()),
            BlocProvider(create: (_) => PriorityMultiBloc()),
            BlocProvider(create: (_) => TagMultiBloc()),
            BlocProvider(create: (_) => ProjectMultiBloc()),
            BlocProvider(create: (_) => ProjectMediaBloc()),
            BlocProvider(create: (_) => WorkMultiBloc()),
            BlocProvider(create: (_) => WorkMediaBloc()),

            BlocProvider(create: (_) => InspectionMultiBloc()),
            BlocProvider(create: (_) => InspectionMediaBloc()),

            BlocProvider(create: (_) => StatusTimelineBloc()),
            BlocProvider(create: (_) => WorkStatusTimelineBloc()),
            BlocProvider(create: (_) => InspectionStatusTimelineBloc()),

            BlocProvider(create: (_) => PrivacyAboutusTermsCondBloc()),
            BlocProvider(create: (_) => CandidateAttachmentBloc()),
            BlocProvider(create: (_) => StatusBloc()..add(StatusList())),
            BlocProvider(
              create: (_) => InterviewsBloc()..add(InterviewsList()),
            ),
            BlocProvider(create: (_) => CandidateInterviewssBloc()),
            BlocProvider(create: (_) => LeadSourceBloc()),
            BlocProvider(create: (_) => LeadBloc()),
            BlocProvider(create: (_) => ContractBloc()..add(ContractList())),
            BlocProvider(
              create: (_) => ContractTypeBloc()..add(ContractTypeList()),
            ),
            BlocProvider(create: (_) => LeadStageBloc()..add(LeadStageLists())),
            BlocProvider(
              create: (_) => CustomFieldBloc()..add(CustomFieldLists()),
            ),
            BlocProvider(create: (_) => PriorityBloc()..add(PriorityLists())),
            BlocProvider(create: (_) => LeadIdBloc()),
            BlocProvider(create: (_) => AllowanceBloc()),
            BlocProvider(create: (_) => DeductionBloc()),
            BlocProvider(
              create: (_) => SingleAllowanceBloc()..add(SingleAllowanceList()),
            ),
            BlocProvider(
              create: (_) => SingleDeductionBloc()..add(SingleDeductionList()),
            ),
            BlocProvider(create: (_) => PayslipBloc()..add(AllPayslipList())),
            BlocProvider(
              create: (_) =>
                  SingleSelectProjectBloc()..add(SingleProjectList()),
            ),
            BlocProvider(
              create: (_) => SingleSelectWorkBloc()..add(SingleWorkList()),
            ),
            BlocProvider(
              create: (_) => CommentsBloc(discussionRepo: DiscussionRepo()),
            ),
          ],
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (themeState is DarkThemeState) {
                  SystemChrome.setSystemUIOverlayStyle(
                    SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.light,
                      statusBarBrightness: Brightness.dark,
                    ),
                  );
                } else {
                  SystemChrome.setSystemUIOverlayStyle(
                    SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.dark,
                      statusBarBrightness: Brightness.light,
                    ),
                  );
                }
              });

              return BlocBuilder<LanguageBloc, LanguageState>(
                builder: (context, languageState) {
                  return ScreenUtilInit(
                    designSize: const Size(375, 812),
                    minTextAdapt: true,
                    builder: (context, child) {
                      return GestureDetector(
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        child: MaterialApp.router(
                          routerConfig: router,
                          locale: languageState.locale,
                          supportedLocales: AppLocalizations.supportedLocales,
                          localizationsDelegates:
                              AppLocalizations.localizationsDelegates,

                          // localizationsDelegates: [
                          //   AppLocalizations.delegate,
                          //   CountryLocalizations.delegate,
                          //   GlobalMaterialLocalizations.delegate,
                          //   GlobalWidgetsLocalizations.delegate,
                          //   GlobalCupertinoLocalizations.delegate,
                          // ],
                          debugShowCheckedModeBanner: false,
                          theme: themeState is LightThemeState
                              ? ThemeData.light()
                              : ThemeData.dark(),
                          builder: (context, child) {
                            return BlocBuilder<ThemeBloc, ThemeState>(
                              builder: (context, themeState) {
                                return Stack(
                                  children: [
                                    child!,
                                    if (_showLockScreen && defaultBiometric)
                                      Positioned.fill(
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 10.0,
                                            sigmaY: 10.0,
                                          ),
                                          child: Container(
                                            color:
                                                (themeState is LightThemeState
                                                        ? Colors.white
                                                        : Colors.black)
                                                    .withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
