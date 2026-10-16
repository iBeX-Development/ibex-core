import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ibex/bloc/permissions/permissions_bloc.dart';
import 'package:ibex/routes/routes.dart';
// import 'package:ibex/main.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../bloc/dashboard_stats/dash_board_stats_bloc.dart';
import '../../../bloc/dashboard_stats/dash_board_stats_state.dart';
import '../../../config/colors.dart';
import '../../../../src/generated/i18n/app_localizations.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/my_theme.dart';
import '../../dash_board/dashboard.dart';
import '../../notes/widgets/notes_shimmer_widget.dart';
import '../../../data/localStorage/hive.dart';
import '../work_lists.dart';

class TotalStats extends StatefulWidget {
  final bool isLightTheme;

  const TotalStats({super.key, required this.isLightTheme});

  @override
  State<TotalStats> createState() => _TotalStatsState();
}

class _TotalStatsState extends State<TotalStats> {
  final GlobalKey _one = GlobalKey();
  bool isFirstTimeUSer = false;

  bool get isLightTheme => widget.isLightTheme;

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
  }

  Future<void> _checkFirstTimeUser() async {
    // Check if user is first time
    final firstTime = await HiveStorage.getIsFirstTime();
    setState(() {
      isFirstTimeUSer = firstTime;
    });
  }

  void onShowCaseCompleted() async {
    await HiveStorage.setIsFirstTime(false);
    setState(() {
      isFirstTimeUSer = false;
    });
  }

  // async функцээ ингэж тодорхойлно
  Future<String> _loadRole() async {
    final role = await HiveStorage.getRole();
    return role;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
      child: BlocConsumer<DashBoardStatsBloc, DashBoardStatsState>(
        listener: (context, state) {
          if (state is DashBoardStatsSuccess) {
            // These values are now passed through constructor
          }
        },
        builder: (context, state) {
          if (state is DashBoardStatsLoading) {
            return const DashBoardStatsShimmer();
          } else if (state is DashBoardStatsSuccess) {
            return FutureBuilder<String>(
              future: _loadRole(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading role: ${snapshot.error}'),
                  );
                }

                final role = snapshot.data ?? 'unknown';

                var totalRequestedWorks = state.totalrequestedworks;
                var totalOpenWorks = state.totalopenworks;
                var totalCompletedWorks = state.totalcompletedworks;
                var totalTask = state.totaltask;

                return Column(
                  children: [
                    // ✅ Main grid content
                    MasonryGridView.builder(
                      padding: EdgeInsets.only(bottom: 10.h),
                      gridDelegate:
                          SliverSimpleGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                          ),
                      mainAxisSpacing: 10.h,
                      crossAxisSpacing: 10.w,
                      itemCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        var items = [
                          {
                            "title": AppLocalizations.of(
                              context,
                            )!.totalRequestedWorks,
                            "total": totalRequestedWorks.toString(),
                            "icon": const HeroIcon(
                              HeroIcons.wallet,
                              style: HeroIconStyle.outline,
                              color: AppColors.orangeYellowishColor,
                            ),
                            "onPress": () => Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const WorkScreen(type: "request"),
                              ),
                            ),
                            "colors": AppColors.orangeYellowishColor,
                          },
                          {
                            "title": AppLocalizations.of(
                              context,
                            )!.totalOpenWorks,
                            "total": totalOpenWorks.toString(),
                            "icon": const HeroIcon(
                              HeroIcons.wallet,
                              style: HeroIconStyle.outline,
                              color: AppColors.blueColor,
                            ),
                            "onPress": () => Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const WorkScreen(type: "open"),
                              ),
                            ),
                            "colors": AppColors.blueColor,
                          },
                          {
                            "title": AppLocalizations.of(
                              context,
                            )!.totalCompletedWorks,
                            "total": totalCompletedWorks.toString(),
                            "icon": const HeroIcon(
                              HeroIcons.wallet,
                              style: HeroIconStyle.outline,
                              color: AppColors.greenColor,
                            ),
                            "onPress": () => Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const WorkScreen(type: "completed"),
                              ),
                            ),
                            "colors": AppColors.greenColor,
                          },
                          {
                            "title": AppLocalizations.of(context)!.totalTask,
                            "total": totalTask.toString(),
                            "icon": const HeroIcon(
                              HeroIcons.documentCheck,
                              style: HeroIconStyle.outline,
                              color: AppColors.primary,
                            ),
                            "onPress": () => Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const DashBoard(initialIndex: 2),
                              ),
                            ),
                            "colors": AppColors.primary,
                          },
                        ];

                        return _getTotal(
                          context: context,
                          index: index + 1,
                          title: items[index]["title"] as String,
                          isLightTheme: isLightTheme,
                          total: items[index]["total"] as String,
                          icon: items[index]["icon"] as HeroIcon,
                          onPress: items[index]["onPress"] as VoidCallback,
                          backroundcolor: Theme.of(
                            context,
                          ).colorScheme.containerDark,
                          colors: items[index]["colors"] as Color,
                        );
                      },
                    ),

                    // ✅ Spacing between grid and FAB
                    SizedBox(height: 20.h),

                    // ✅ FAB at bottom with proper alignment createworkrequest
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: isFirstTimeUSer == true
                    //       ? Showcase(
                    //           onTargetClick: () {
                    //             ShowCaseWidget.of(context).completed(_one);
                    //             if (ShowCaseWidget.of(context).activeWidgetId ==
                    //                 1) {
                    //               onShowCaseCompleted();
                    //             }
                    //           },
                    //           key: _one,
                    //           disposeOnTap: true,
                    //           titleAlignment: Alignment.center,
                    //           title: 'Add Work',
                    //           titleTextStyle: const TextStyle(
                    //             fontSize: 14,
                    //             color: Colors.grey,
                    //           ),
                    //           descTextStyle: const TextStyle(
                    //             fontSize: 12,
                    //             color: AppColors.textsub2Color,
                    //           ),
                    //           description:
                    //               'Add new Work data by clicking this button.',
                    //           child: FloatingActionButton(
                    //             onPressed: () {
                    //               // ✅ FIX: Check permission first
                    //               if (context
                    //                       .read<PermissionsBloc>()
                    //                       .iscreateWork ==
                    //                   true) {
                    //                 print(
                    //                     "✅ Permission granted, navigating...");
                    //                 router.push('/createworkrequest', extra: {
                    //                   "id": 0,
                    //                   "isCreate": true,
                    //                   "fromDetail": false,
                    //                   "title": "",
                    //                   "desc": "",
                    //                   "start": "",
                    //                   "budget": "",
                    //                   "end": "",
                    //                   'priority': "",
                    //                   'priorityId': 0,
                    //                   'statusId': 0,
                    //                   'note': "",
                    //                   'status': "",
                    //                 });
                    //               } else {
                    //                 print("❌ Permission denied");
                    //                 // Optionally show a message to user
                    //                 ScaffoldMessenger.of(context).showSnackBar(
                    //                   const SnackBar(
                    //                     content: Text(
                    //                         'You do not have permission to create work'),
                    //                     duration: Duration(seconds: 2),
                    //                   ),
                    //                 );
                    //               }
                    //             },
                    //             backgroundColor: AppColors.primary,
                    //             heroTag: 'add_work_fab',
                    //             child: const Icon(
                    //               Icons.add,
                    //               color: AppColors.whiteColor,
                    //             ),
                    //           ),
                    //         )
                    //       : FloatingActionButton(
                    //           onPressed: () {
                    //             print("FAB Pressed (No Showcase)");
                    //             // ✅ FIX: Check permission first
                    //             if (context
                    //                     .read<PermissionsBloc>()
                    //                     .iscreateWork ==
                    //                 true) {
                    //               print("✅ Permission granted, navigating...");
                    //               router.push('/createworkrequest', extra: {
                    //                 "id": 0,
                    //                 "isCreate": true,
                    //                 "fromDetail": false,
                    //                 "title": "",
                    //                 "desc": "",
                    //                 "start": "",
                    //                 "budget": "",
                    //                 "end": "",
                    //                 'priority': "",
                    //                 'priorityId': 0,
                    //                 'statusId': 0,
                    //                 'note': "",
                    //                 'status': "",
                    //               });
                    //             } else {
                    //               print("❌ Permission denied");
                    //               // Optionally show a message to user
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 const SnackBar(
                    //                   content: Text(
                    //                       'You do not have permission to create work'),
                    //                   duration: Duration(seconds: 2),
                    //                 ),
                    //               );
                    //             }
                    //           },
                    //           backgroundColor: AppColors.primary,
                    //           heroTag: 'add_work_fab',
                    //           child: const Icon(
                    //             Icons.add,
                    //             color: AppColors.whiteColor,
                    //           ),
                    //         ),
                    // ),
                  ],
                );
              },
            );
          } else if (state is DashBoardStatsError) {
            return Center(
              child: Text(
                state.errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }

  Widget _getTotal({
    required String title,
    required bool isLightTheme,
    required String total,
    required Widget icon,
    required VoidCallback? onPress,
    required Color backroundcolor,
    required int index,
    required Color colors,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: onPress,
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          boxShadow: [
            isLightTheme ? MyThemes.lightThemeShadow : MyThemes.darkThemeShadow,
          ],
          borderRadius: BorderRadius.circular(10),
          color: backroundcolor,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                CustomText(
                  textAlign: TextAlign.center,
                  text: title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: Theme.of(context).colorScheme.textClrChange,
                  size: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
                // CustomText(
                //   text: total,
                //   color: Theme.of(context).colorScheme.textClrChange,
                //   size: 20.sp,
                //   fontWeight: FontWeight.bold,
                // ),
                // CustomText(
                //   text: AppLocalizations.of(context)!.viewmore,
                //   color: colors,
                //   size: 12.sp,
                //   fontWeight: FontWeight.w500,
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
