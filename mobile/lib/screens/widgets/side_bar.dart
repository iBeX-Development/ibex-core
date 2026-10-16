import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:slidable_bar/slidable_bar.dart';
import 'package:ibex/config/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../bloc/activity_log/activity_log_bloc.dart';
import '../../bloc/activity_log/activity_log_event.dart';
import '../../bloc/clients/client_bloc.dart';
import '../../bloc/clients/client_event.dart';
import '../../bloc/meeting/meeting_bloc.dart';
import '../../bloc/meeting/meeting_event.dart';
import '../../bloc/notes/notes_bloc.dart';
import '../../bloc/notes/notes_event.dart';

import '../../bloc/notifications/system_notification/notification_bloc.dart';
import '../../bloc/notifications/system_notification/notification_event.dart';
import '../../bloc/permissions/permissions_bloc.dart';
import '../../bloc/permissions/permissions_state.dart';
import '../../bloc/setting/settings_bloc.dart';
import '../../bloc/setting/settings_event.dart';
import '../../bloc/todos/todos_bloc.dart';
import '../../bloc/todos/todos_event.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_event.dart';
import '../../data/localStorage/hive.dart';
import '../../routes/routes.dart';
import '../Work/work_lists.dart';
import '../dash_board/dashboard.dart';

class SideBar extends StatefulWidget {
  final SlidableBarController? controller;
  final Widget? underWidget;
  final String? hasGuard;
  final BuildContext context;
  final GlobalKey<ScaffoldState>? scaffoldKey; // Шинээр нэмэх
  final Function(bool)? toggleDrawer; // Шинээр нэмэх
  final bool? isExpand; // Байгаа эсэх шалга
  final Function(bool)? onSideBarToggle; // SideBar нээх/хаах callback

  const SideBar({
    super.key,
    this.underWidget,
    this.hasGuard,
    this.controller,
    required this.context,
    this.scaffoldKey, // Шинээр нэмэх
    this.toggleDrawer, // Шинээр нэмэх
    this.isExpand,
    this.onSideBarToggle, // SideBar нээх/хаах callback
  });
  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  String? userRole;
  bool _isSidebarVisible = false; // Track the visibility state
  bool isExpand = true;

  void toggleDrawer(bool expanded) {
    setState(() {
      isExpand = expanded;
    });
  }

  @override
  void initState() {
    _getUserRole();
    super.initState();
  }

  Future<void> _getUserRole() async {
    final role = await HiveStorage.getRole();
    setState(() {
      userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlidableBar(
      backgroundColor: Theme.of(context).colorScheme.backGroundColor,
      duration: Duration(milliseconds: 50),
      clicker: Container(
        width: 40.w,
        height: 60.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.backGroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(70),
            bottomLeft: Radius.circular(70),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(-2, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 0.w),
          child: Tooltip(
            message: _isSidebarVisible ? "Hide Sidebar" : "Show Sidebar",
            child: IconButton(
              splashColor: Colors.transparent, // Disable the splash color
              highlightColor: Colors.transparent,
              icon: Icon(
                _isSidebarVisible
                    ? Icons.arrow_forward_ios
                    : Icons.arrow_back_ios,
                color: AppColors.primary, // Set the icon color
              ),
              onPressed: () {
                setState(() {
                  _isSidebarVisible =
                      !_isSidebarVisible; // Toggle visibility state
                });
                if (_isSidebarVisible) {
                  widget.controller!.show(); // Show the sidebar
                  widget.onSideBarToggle?.call(true); // Notify parent
                } else {
                  widget.controller!.hide(); // Hide the sidebar
                  widget.onSideBarToggle?.call(false); // Notify parent
                }
              },
            ),
          ),
        ),
      ),
      frontColor: Colors.red,
      size: 60,
      slidableController: widget.controller,
      side: Side.right,
      clickerSize: 50.w,
      barChildren: [
        SizedBox(
          height:
              MediaQuery.of(context).size.height -
              60.h, // Reduced by 30.h from top and bottomAdd padding to create space from top and bottom
          child: SingleChildScrollView(
            child: BlocConsumer<PermissionsBloc, PermissionsState>(
              listener: (context, state) {
                if (state is PermissionsSuccess) {}
              },
              builder: (context, state) {
                return Column(
                  children: [
                    SizedBox(height: 20.h),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const DashBoard(),
                          ),
                        );
                      },
                      child: Tooltip(
                        message: "Home",
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: const HeroIcon(
                            HeroIcons.home,
                            style: HeroIconStyle.outline,
                            color: AppColors.blackColor,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        router.push(
                          '/createworkrequest',
                          extra: {
                            "id": 0,
                            "isCreate": true,
                            "fromDetail": false,
                            'priority': '1',
                            'priorityId': 1,
                            'statusId': 1,
                            'status': '1',
                            'woStatus': 1,
                            'createdType': 'request',
                          },
                        );
                      },
                      child: Tooltip(
                        message: "Create Request",
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: const HeroIcon(
                            HeroIcons.plusCircle,
                            style: HeroIconStyle.outline,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) =>
                                const WorkScreen(type: "request"),
                          ),
                        );
                      },
                      child: Tooltip(
                        message: "Request",
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: const HeroIcon(
                            HeroIcons.documentDuplicate,
                            style: HeroIconStyle.outline,
                            color: AppColors.orangeYellowishColor,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) =>
                                const WorkScreen(type: "open"),
                          ),
                        );
                      },
                      child: Tooltip(
                        message: "Open Works",
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: const HeroIcon(
                            HeroIcons.documentArrowUp,
                            style: HeroIconStyle.outline,
                            color: AppColors.blueColor,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) =>
                                const WorkScreen(type: "completed"),
                          ),
                        );
                      },
                      child: Tooltip(
                        message: "Completed Works",
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: const HeroIcon(
                            HeroIcons.documentCheck,
                            style: HeroIconStyle.outline,
                            color: AppColors.greenColor,
                          ),
                        ),
                      ),
                    ),

                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) =>
                                const WorkScreen(type: "assigned"),
                          ),
                        );
                      },
                      child: Tooltip(
                        message: "My Assignments",
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: const HeroIcon(
                            HeroIcons.userCircle,
                            style: HeroIconStyle.outline,
                            color: AppColors.purple,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        router.push('/inspection');
                      },
                      child: Tooltip(
                        message: "Inspection",
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: const HeroIcon(
                            HeroIcons.clipboardDocumentCheck,
                            style: HeroIconStyle.outline,
                            color: AppColors.redColor,
                          ),
                        ),
                      ),
                    ),

                    // InkWell(
                    //   splashColor: Colors.transparent,
                    //   onTap: () {
                    //     Navigator.of(context).push(
                    //       CupertinoPageRoute(
                    //         builder: (context) =>
                    //             const DashBoard(initialIndex: 2),
                    //       ),
                    //     );
                    //   },
                    //   child: Tooltip(
                    //     message: "Tasks",
                    //     child: Padding(
                    //       padding: EdgeInsets.symmetric(vertical: 10.h),
                    //       child: const HeroIcon(
                    //         size: 26,
                    //         HeroIcons.documentCheck,
                    //         style: HeroIconStyle.outline,
                    //         color: AppColors.greyColor,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        router.push('/workspaces', extra: {"fromNoti": false});
                        // router.pop();
                      },
                      child: Tooltip(
                        message: "Workspaces",
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: const HeroIcon(
                            HeroIcons.swatch,
                            style: HeroIconStyle.outline,
                            color: AppColors.black54,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        router.push("/notification");
                        context.read<NotificationBloc>().add(
                          NotificationList(),
                        );
                        // router.pop();
                      },
                      child: Tooltip(
                        message: "Notifications",
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: const HeroIcon(
                            HeroIcons.bellAlert,
                            style: HeroIconStyle.outline,
                            color: AppColors.darkBlue,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        context.read<TodosBloc>().add(const TodosList());
                        router.push("/todos");
                        // router.pop();
                      },
                      child: Tooltip(
                        message: "To-Do List",
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: const HeroIcon(
                            HeroIcons.newspaper,
                            style: HeroIconStyle.outline,
                            color: AppColors.redColor,
                          ),
                        ),
                      ),
                    ),
                    context.read<PermissionsBloc>().isManageUser == true
                        ? InkWell(
                            splashColor: Colors.transparent,
                            onTap: () {
                              router.push('/user');
                              BlocProvider.of<UserBloc>(
                                context,
                              ).add(UserList());
                              // router.pop();
                            },
                            child: Tooltip(
                              message: "Users",
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                child: const HeroIcon(
                                  HeroIcons.users,
                                  style: HeroIconStyle.outline,
                                  color: AppColors.greenColor,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),

                    // InkWell(
                    //   splashColor: Colors.transparent,
                    //   onTap: () {
                    //     context.read<NotesBloc>().add(const NotesList());
                    //     router.push('/notes');
                    //     router.pop();
                    //   },
                    //   child: Tooltip(
                    //     message: "Notes",
                    //     child: Padding(
                    //       padding: EdgeInsets.symmetric(vertical: 10.h),
                    //       child: const HeroIcon(
                    //         HeroIcons.newspaper,
                    //         style: HeroIconStyle.outline,
                    //         color: AppColors.greyColor,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // InkWell(
                    //   splashColor: Colors.transparent,
                    //   onTap: () {
                    //     if (widget.scaffoldKey != null &&
                    //         widget.controller != null) {
                    //       // Sidebar хаа
                    //       setState(() {
                    //         _isSidebarVisible = false;
                    //       });
                    //       widget.controller!.hide();

                    //       // isExpand true болгоо
                    //       if (widget.toggleDrawer != null) {
                    //         widget.toggleDrawer!(true);
                    //       }

                    //       // Drawer нээх - 500ms-ийн дараа
                    //       Future.delayed(Duration(milliseconds: 500), () {
                    //         widget.scaffoldKey?.currentState?.openDrawer();
                    //       });
                    //     }
                    //   },
                    //   child: Tooltip(
                    //     message: "Menu Management",
                    //     child: Padding(
                    //       padding: EdgeInsets.symmetric(vertical: 10.h),
                    //       child: const HeroIcon(
                    //         HeroIcons.barsArrowUp,
                    //         style: HeroIconStyle.outline,
                    //         color: AppColors.greyColor,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    userRole == "admin"
                        ? InkWell(
                            splashColor: Colors.transparent,
                            onTap: () {
                              router.push("/settings");
                              BlocProvider.of<SettingsBloc>(
                                context,
                              ).add(SettingsList('general_settings'));
                              Navigator.pop(context);
                            },
                            child: Tooltip(
                              message: "Settings",
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                child: const HeroIcon(
                                  HeroIcons.cog6Tooth,
                                  style: HeroIconStyle.outline,
                                  color: AppColors.greyColor,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    SizedBox(height: 70.h),
                  ],
                );
              },
            ),
          ),
        ),
      ],
      child: widget.underWidget!,
    );
  }
}
