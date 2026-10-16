import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ibex/utils/widgets/custom_text.dart';
import '../../bloc/birthday/birthday_bloc.dart';
import '../../bloc/birthday/birthday_event.dart';
import '../../bloc/clients/client_bloc.dart';
import '../../bloc/income_expense/income_expense_bloc.dart';
import '../../bloc/income_expense/income_expense_event.dart';
import '../../bloc/leave_req_dashboard/leave_req_dashboard_bloc.dart';
import '../../bloc/leave_req_dashboard/leave_req_dashboard_event.dart';

import '../../bloc/notifications/system_notification/notification_bloc.dart';
import '../../bloc/notifications/system_notification/notification_event.dart';
import '../../bloc/notifications/system_notification/notification_state.dart';
import '../../bloc/permissions/permissions_bloc.dart';
import '../../bloc/permissions/permissions_event.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/languages/language_switcher_bloc.dart';
import '../../bloc/languages/language_switcher_event.dart';
import '../../bloc/languages/language_switcher_state.dart';
import '../../bloc/status/status_bloc.dart';
import '../../bloc/status/status_event.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';
import '../../bloc/user_profile/user_profile_bloc.dart';
import '../../bloc/user_profile/user_profile_event.dart';
import '../../bloc/work_anniveresary/work_anniversary_bloc.dart';
import '../../bloc/work_anniveresary/work_anniversary_event.dart';
import '../../bloc/news/news_bloc.dart';
import '../../bloc/news/news_event.dart';
import '../../bloc/news/news_state.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../data/localStorage/hive.dart';
import '../../src/generated/i18n/app_localizations.dart';
import '../../routes/routes.dart';
import 'home_widgets/welcome_card.dart';
import 'home_widgets/drawer_widgets.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // final Connectivity _connectivity = Connectivity();
  // late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  int? totalProjects = 0;
  int? totalTask = 0;
  int? totalUser = 0;
  // int? totalClient = 0;
  // int? totalMeeting = 0;
  int? totalTodos = 0;
  String? usersname;
  int? usersId;
  List<int> userSelectedId = [];
  List<String> userSelectedname = [];
  List<int> clientSelectedId = [];
  List<String> clientSelectedname = [];

  List<int> userSelectedIdForAnni = [];
  List<String> userSelectednameForAnni = [];

  List<int> userSelectedIdForLeavereq = [];
  List<String> userSelectednameLeavereq = [];
  int upcomingDays = 7;
  int upcomingMonths = 30;
  int days = 0;
  String? weekMonth;

  String? hasGuard;
  String searchWord = "";

  String? languageCode;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _buyNowController;
  // Add ScrollController
  bool isExpand = false;

  void toggleDrawer(bool expanded) {
    setState(() {
      isExpand = expanded;
    });
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

  // Static data
  final Map<String, dynamic> welcomeData = {
    'greeting': 'Өглөөний мэнд!',
    'userName': 'Бат-Эрдэнэ',
    'userRole': 'Ажилтан',
    'workspaceName': 'Төв оффис',
  };

  final List<Map<String, dynamic>> quickAccessItems = [
    {'icon': Icons.description, 'label': 'Журам', 'color': Colors.red},
    {
      'icon': Icons.calendar_today,
      'label': 'Хуваарь',
      'color': Color(0xFF2E5BCD)
    },
    // {'icon': Icons.star, 'label': 'Э.Р чуулган', 'color': Colors.amber},
    {'icon': Icons.people, 'label': 'Утас', 'color': Colors.indigo},
    {'icon': Icons.language, 'label': 'Холбоос', 'color': Colors.blue},
  ];

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
          if (kDebugMode) {
            logger.d('Scroll position: ${_scrollController.position.pixels}');
          }
          if (kDebugMode) {
            logger.d('Has clients: ${_scrollController.hasClients}');
          }
          logger.d(
            'Has content dimensions: ${_scrollController.position.hasContentDimensions}',
          );
        }
      });
    });
    Future.microtask(() {
      if (mounted && _scrollController.hasClients) {
        setState(() {});
      }
    });

    // _getRole();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch news after dependencies are available
    if (mounted) {
      context.read<NewsBloc>().add(const FetchNewsList());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buyNowController.dispose();
    _scrollController.dispose();
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
    BlocProvider.of<ChartBloc>(
      context,
    ).add(FetchChartData(endDate: "", startDate: ""));

    BlocProvider.of<NotificationBloc>(context).add(UnreadNotificationCount());
    BlocProvider.of<NewsBloc>(context).add(const FetchNewsList());

    // _getRole();
    setState(() {
      isLoading = false;
    });
  }

  String? greetingMessage;
  String? greetingEmoji;
  String? getLanguage;

  void _greeting() {
    greetingMessage = getGreeting(context);
    greetingEmoji = getGreetingEmoji();
  }

  Future<void> _getRole() async {
    final fetchedRole = await HiveStorage.getRole();
    setState(() {
      role = fetchedRole; // Assign the fetched role
      if (kDebugMode) {
        logger.d('User role in HomeScreen: $role');
      }
      // Conditionally dispatch BLoC events based on role
      if (role != 'client' && role != 'Client') {
        BlocProvider.of<WorkAnniversaryBloc>(
          context,
        ).add(WeekWorkAnniversaryList([], [], 7, [], []));
        BlocProvider.of<BirthdayBloc>(
          context,
        ).add(WeekBirthdayList(7, [], [], [], []));
        BlocProvider.of<LeaveReqDashboardBloc>(
          context,
        ).add(WeekLeaveReqListDashboard([], 7, []));
      }
    });
  }

  void _handleUsersNameForAnni(List<String> userName, List<int> userId) {
    setState(() {
      userSelectednameForAnni = userName;
      userSelectedIdForAnni = userId;
    });
  }

  void _handleUsersNameForLeaveReq(List<String> userName, List<int> userId) {
    setState(() {
      userSelectednameLeavereq = userName;
      userSelectedIdForLeavereq = userId;
    });
  }

  String? photoWidget;
  String? email;
  String? roleInUser;
  String? firstNameUser;
  String? lastNameUSer;
  String? workSpaceTitle;
  bool projectChart = false;
  bool taskChart = false;
  bool isExpanded = false;
  void handleIsProjectChart(bool status) {
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
    final currentTheme = context.watch<ThemeBloc>().state;
    bool isLightTheme = currentTheme is LightThemeState;

    _todayTask();
    // BlocProvider.of<StatusBloc>(context).add(StatusList());
    // BlocProvider.of<UserProfileBloc>(context).add(ProfileListGet());
    // BlocProvider.of<DashBoardStatsBloc>(context).add(StatsList());

    _greeting();
    hasGuard = context.read<AuthBloc>().guard;
    context.read<AuthBloc>().guard;
    context.read<AuthBloc>().hasAllDataAccess;
    context.read<AuthBloc>().userId;
    // _getRole();
    return BlocProvider(
      create: (context) => ClientBloc(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (!didPop) {
            // Check if drawer is open
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            } else {
              // Exit app or handle back navigation
              SystemNavigator.pop();
            }
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).colorScheme.backGroundColor,
          drawer: isExpand ? _drawerIn() : _expandedDrawer(),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(40.h), // Set your custom height here
            child: AppBar(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor:
                    isLightTheme ? Colors.transparent : Colors.black,
                statusBarIconBrightness:
                    isLightTheme ? Brightness.dark : Brightness.light,
                statusBarBrightness:
                    isLightTheme ? Brightness.light : Brightness.dark,
              ),
              backgroundColor: Colors.transparent,
              leadingWidth: 80.w,
              leading: Padding(
                padding: EdgeInsets.only(top: 15.h),
                // padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: SizedBox(
                    width: 80.w,
                    height: 80.h,
                    child: HeroIcon(
                      size: 25.sp,
                      HeroIcons.bars3BottomLeft,
                      style: HeroIconStyle.outline,
                      color: Theme.of(context).colorScheme.textClrChange,
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  // padding: EdgeInsets.symmetric(horizontal: 18.w),
                  padding: EdgeInsets.only(top: 5.h, left: 0.w, right: 15.h),

                  child: Row(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              router.push("/notification");
                            },
                            child: SizedBox(
                              // color: AppColors.red,
                              height: 50.h,
                              child: Padding(
                                padding:
                                    EdgeInsets.only(left: 5.w, right: 10.w),
                                child: HeroIcon(
                                  HeroIcons.bell,
                                  style: HeroIconStyle.outline,
                                  size: 20.sp,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.textClrChange,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 5.w,
                            top: 2.h,
                            child: BlocConsumer<NotificationBloc,
                                NotificationsState>(
                              listener: (context, state) {
                                if (state is NotificationPaginated) {}
                              },
                              builder: (context, state) {
                                if (state is UnreadNotification) {
                                  return state.total == 0
                                      ? SizedBox()
                                      : Container(
                                          height: 15.sp,
                                          width: 15.sp,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.yellow.shade800,
                                          ),
                                          child: Center(
                                            child: CustomText(
                                              size: 10,
                                              fontWeight: FontWeight.w600,
                                              text: state.total.toString(),
                                              color: AppColors.pureWhiteColor,
                                            ),
                                          ),
                                        );
                                }
                                return SizedBox();
                              },
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          _showLanguageDialog(context);
                        },
                        child: SizedBox(
                          // color: AppColors.red,
                          height: 50.h,
                          child: Padding(
                            padding: EdgeInsets.only(left: 1.w, right: 8.w),
                            child: BlocBuilder<LanguageBloc, LanguageState>(
                              builder: (context, state) {
                                final currentLang =
                                    (state.locale.languageCode ?? 'en')
                                        .toUpperCase();
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 2.w),
                                    Text(
                                      currentLang,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .textClrChange,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Theme.of(context).colorScheme.backGroundColor,
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
                          minHeight: MediaQuery.of(context).size.height,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10.h),
                            _welcomeCard(isLightTheme),
                            SizedBox(height: 15.h),
                            _buildQuickAccessSection(),
                            _buildNewsSection(),
                            SizedBox(height: 80.h),
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
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    String? selectedLanguage =
        context.read<LanguageBloc>().state.locale.languageCode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              10.r,
            ), // Set the desired radius here
          ),
          contentPadding: EdgeInsets.only(right: 10.w, bottom: 30.h),
          actionsPadding: EdgeInsets.only(right: 10.w, bottom: 30.h),
          title: Text(AppLocalizations.of(context)!.chooseLang),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: SizedBox(
                  width: 50.w,
                  // height: MediaQueryHelper.screenHeight(context) * 0.2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        visualDensity: VisualDensity(horizontal: -4),
                        activeColor: AppColors.primary,
                        title: Text(
                          'English (EN)',
                          style: TextStyle(
                            fontSize: 17,
                            fontFamily: "Poppins-Bold",
                          ),
                        ),
                        value: 'en',
                        groupValue: selectedLanguage,
                        onChanged: (String? value) {
                          setState(() {
                            selectedLanguage = value;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        visualDensity: VisualDensity(horizontal: -4),
                        activeColor: AppColors.primary,
                        title: Text(
                          'Mongolian (MN)',
                          style: TextStyle(
                            fontSize: 17,
                            fontFamily: "Poppins-Bold",
                          ),
                        ),
                        value: 'mn',
                        groupValue: selectedLanguage,
                        onChanged: (String? value) {
                          setState(() {
                            selectedLanguage = value;
                          });
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontFamily: "Poppins-Bold",
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.ok,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontFamily: "Poppins-Bold",
                ),
              ),
              onPressed: () {
                if (selectedLanguage != null) {
                  // HiveStorage().storeLanguage(selectedLanguage!);

                  context.read<LanguageBloc>().add(
                        ChangeLanguage(languageCode: selectedLanguage!),
                      );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _welcomeCard(isLightTheme) {
    return WelcomeCard(
      isLightTheme: isLightTheme,
      greetingMessage: greetingMessage,
      greetingEmoji: greetingEmoji,
      photo: photo,
    );
  }

  Widget _buildQuickAccessSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 0, // ✅ No bottom padding here
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Танд ойр',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.textClrChange,
            ),
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8, // ✅ Reduced from 12 to 8
              mainAxisSpacing: 8, // ✅ Reduced from 12 to 8
              childAspectRatio:
                  1.0, // ✅ Increased from 0.85 to 1.0 for more compact boxes
            ),
            itemCount: quickAccessItems.length,
            itemBuilder: (context, index) {
              final item = quickAccessItems[index];
              return _buildQuickAccessItem(
                icon: item['icon'],
                label: item['label'],
                color: item['color'],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.containerDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Theme.of(context).colorScheme.dividerClrChange
                : color.withValues(alpha: 0.3),
            width: 1.5, // Border width
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40, // ✅ Reduced from 48 to 40
              height: 40, // ✅ Reduced from 48 to 40
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark
                    ? Theme.of(context).colorScheme.textClrChange
                    : color,
                size: 20, // ✅ Reduced from 24 to 20
              ),
            ),
            const SizedBox(height: 6), // ✅ Reduced from 8 to 6,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10, // ✅ Reduced from 11 to 10
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.textClrChange,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    return Transform.translate(
      offset: const Offset(0, -50), // ✅ 20 pixels дээш шилжүүлнэ
      child: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Improved section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.newspaper_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Мэдээ мэдээлэл',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                    ),
                  ],
                ),
                // Optional: "See all" button
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all news page
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Бүгд',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            BlocBuilder<NewsBloc, NewsState>(
              builder: (context, state) {
                if (state is NewsLoading) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Мэдээ ачаалж байна...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.colorChange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is NewsSuccess) {
                  if (state.news.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.newspaper_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Мэдээ байхгүй байна',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.news.length,
                    itemBuilder: (context, index) {
                      final news = state.news[index];
                      // logger.d('News item: ${news.content}, index: $index');
                      return _buildNewsCard(
                        date: news.dateCreated ?? '',
                        title: news.title ?? '',
                        id: news.id ?? 0,
                        likes: news.likes ?? 0,
                        image: news.image,
                        content: news.content ?? '',
                      );
                    },
                  );
                } else if (state is NewsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Алдаа гарлаа',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateToUB(String dateStr) {
    try {
      if (dateStr.isEmpty) return '';

      // Parse UTC date
      DateTime utcDate = DateTime.parse(dateStr);

      // Convert to UB timezone (UTC+8)
      DateTime ubDate = utcDate.add(const Duration(hours: 8));

      // Format as YYYY/MM/DD
      return DateFormat('yyyy/MM/dd').format(ubDate);
    } catch (e) {
      if (kDebugMode) {
        logger.d('Error formatting date: $e');
      }
      return dateStr;
    }
  }

  Widget _buildNewsCard({
    required String date,
    required String title,
    required int likes,
    String? image,
    int? id,
    String? content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final truncatedContent = (content != null && content.length > 150)
        ? '${content.substring(0, 150)}...'
        : content ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.containerDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Image on top with gradient overlay
          if (image != null)
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  child: Image.network(
                    '$activePictureUrl/$image',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey,
                            size: 48,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Gradient overlay for better text readability
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Title and category icon overlay on image
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[500],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          // ✅ Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and category when no image
                if (image == null)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[500],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.textClrChange,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (image == null) const SizedBox(height: 12),
                // Date row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.colorChange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateToUB(date),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.colorChange,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Content text
                Text(
                  truncatedContent,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.textClrChange,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Bottom row with likes and read more
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Likes
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 18,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$likes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).colorScheme.textClrChange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Read more button
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Navigate to news detail page
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text(
                        'Дэлгэрэнгүй',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      iconAlignment: IconAlignment.end,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerIn() {
    return DrawerWidgets(
      isExpand: isExpand,
      toggleDrawer: toggleDrawer,
      statusPending: statusPending,
      firstNameUser: firstNameUser,
      lastNameUSer: lastNameUSer,
      email: email,
      roleInUser: roleInUser,
      photoWidget: photoWidget,
      role: role,
    );
  }

  Widget _expandedDrawer() {
    return DrawerWidgets(
      isExpand: isExpand,
      toggleDrawer: toggleDrawer,
      statusPending: statusPending,
      firstNameUser: firstNameUser,
      lastNameUSer: lastNameUSer,
      email: email,
      roleInUser: roleInUser,
      photoWidget: photoWidget,
      role: role,
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
