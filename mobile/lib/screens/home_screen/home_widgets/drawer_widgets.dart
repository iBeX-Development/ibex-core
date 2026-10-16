import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:heroicons/heroicons.dart';

import '../../../bloc/notifications/system_notification/notification_bloc.dart';
import '../../../bloc/notifications/system_notification/notification_event.dart';
import '../../../bloc/notifications/system_notification/notification_state.dart';
import '../../../bloc/workspace/workspace_bloc.dart';
import '../../../bloc/workspace/workspace_state.dart';
import '../../../bloc/user_profile/user_profile_bloc.dart';
import '../../../bloc/user_profile/user_profile_state.dart';
import '../../../bloc/permissions/permissions_bloc.dart';
import '../../../bloc/permissions/permissions_state.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/todos/todos_bloc.dart';
import '../../../bloc/todos/todos_event.dart';
import '../../../bloc/user/user_bloc.dart';
import '../../../bloc/user/user_event.dart';
import '../../../bloc/setting/settings_bloc.dart';
import '../../../bloc/setting/settings_event.dart';
import '../../../config/colors.dart';
import '../../../data/localStorage/hive.dart';
import '../../../../src/generated/i18n/app_localizations.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../routes/routes.dart';
import '../../dash_board/dashboard.dart';
import '../widgets/workspace_dialog.dart';
import '../../work/work_lists.dart';
import '../../inspection/inspection_from_drawer.dart';
import 'package:ibex/config/constants.dart';

class DrawerWidgets extends StatefulWidget {
  final bool isExpand;
  final Function(bool) toggleDrawer;
  final int? statusPending;
  final String? firstNameUser;
  final String? lastNameUSer;
  final String? email;
  final String? roleInUser;
  final String? photoWidget;
  final String? role;

  DrawerWidgets({
    super.key,
    required this.isExpand,
    required this.toggleDrawer,
    this.statusPending,
    this.firstNameUser,
    this.lastNameUSer,
    this.email,
    this.roleInUser,
    this.photoWidget,
    this.role,
  });

  @override
  State<DrawerWidgets> createState() => _DrawerWidgetsState();
}

class _DrawerWidgetsState extends State<DrawerWidgets> {
  bool isExpanded = false;
  bool isExpandedContract = false;
  bool isExpandedPayslip = false;
  bool isExpandedHrms = false;
  bool isExpandedLeads = false;
  String? firstNameUser;
  String? lastNameUSer;
  String? email;
  String? roleInUser;
  String? photoWidget;
  String? role;

  // Helper method to validate UUID format
  bool _isValidUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    // UUID format: 8-4-4-4-12 hex characters
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  @override
  void initState() {
    super.initState();
    // Initialize state with initial data from widget if any
    firstNameUser = widget.firstNameUser ?? "First Name";
    lastNameUSer = widget.lastNameUSer ?? "Last Name";
    email = widget.email ?? "Email";
    roleInUser = widget.roleInUser;
    photoWidget = widget.photoWidget;

    // _loadRole();
    role = widget.role;
  }

  Future<void> _loadRole() async {
    final roleName = await HiveStorage.getRoleName();
    if (mounted) {
      setState(() {
        role = roleName.isNotEmpty ? roleName : widget.role;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isExpand ? _drawerIn(context) : _expandedDrawer(context);
  }

  Widget _drawerIn(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20.0),
        bottomRight: Radius.circular(20.0),
      ),
      child: Container(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        height: 680.h,
        child: Drawer(
          elevation: 0,
          width: 62.w,
          backgroundColor: Theme.of(context).colorScheme.bgColorChange,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BlocConsumer<WorkspaceBloc, WorkspaceState>(
                  listener: (context, state) {
                    if (state is WorkspacePaginated) {}
                  },
                  builder: (context, state) {
                    if (state is WorkspacePaginated) {
                      return InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return WorkSpaceDialog(
                                work: state.workspace,
                                isDashboard: true,
                              );
                            },
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.only(top: 20.h),
                          child: HeroIcon(
                            HeroIcons.square3Stack3d,
                            style: HeroIconStyle.outline,
                            color: AppColors.greyColor,
                            size: 20.sp,
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: EdgeInsets.only(top: 30.h),
                      child: SizedBox(
                        child: HeroIcon(
                          HeroIcons.square3Stack3d,
                          style: HeroIconStyle.outline,
                          color: AppColors.greyColor,
                          size: 20.sp,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                SizedBox(
                  height: 0.h,
                ),
                BlocConsumer<UserProfileBloc, UserProfileState>(
                  listener: (context, state) {
                    if (state is UserProfileSuccess) {
                      for (var data in state.profile) {
                        firstNameUser = data.firstName ?? "First Name";
                        lastNameUSer = data.lastName ?? "LastName";
                        email = data.email ?? "Email";
                        roleInUser = data.roleId.toString();
                        photoWidget = data.profile ?? "Photo";
                        role = data.role ?? "Role";
                      }
                    } else if (state is UserProfileError) {}
                  },
                  builder: (context, state) {
                    if (state is UserProfileSuccess) {
                      firstNameUser =
                          context.read<UserProfileBloc>().firstname ??
                              "First Name";
                      lastNameUSer = context.read<UserProfileBloc>().lastName ??
                          "LastName";
                      email = context.read<UserProfileBloc>().email ?? "Email";
                      roleInUser =
                          context.read<UserProfileBloc>().roleId.toString();
                      photoWidget =
                          context.read<UserProfileBloc>().profilePic ?? "Photo";
                      role = context.read<UserProfileBloc>().role ?? "Role";

                      return widget.photoWidget == null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 68),
                              child: SizedBox(
                                width: 30.w,
                                child: CircleAvatar(
                                  radius: 21.r,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .textClrChange,
                                  child: CircleAvatar(
                                    radius: 20.r,
                                    backgroundColor: Colors.grey[200],
                                  ),
                                ),
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.only(top: 0.h),
                              child: SizedBox(
                                width: 30.w,
                                child: CircleAvatar(
                                  radius: 25.r,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .textClrChange,
                                  child: (widget.photoWidget != null &&
                                          _isValidUuid(widget.photoWidget))
                                      ? CircleAvatar(
                                          radius: 20.r,
                                          backgroundImage: NetworkImage(
                                              '$activePictureUrl/${widget.photoWidget}'),
                                          backgroundColor: Colors.grey[200],
                                        )
                                      : CircleAvatar(
                                          radius: 20.r,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .backGroundColor,
                                          child: CircleAvatar(
                                            radius: 20.r,
                                            backgroundColor: Colors.grey[200],
                                            child: Icon(
                                              Icons.person,
                                              size: 20.sp,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SizedBox(
                        width: 50.w,
                        child: CircleAvatar(
                          radius: 26.r,
                          backgroundColor:
                              Theme.of(context).colorScheme.backGroundColor,
                          child: CircleAvatar(
                            radius: 25.r,
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 15.h,
                ),
                BlocConsumer<PermissionsBloc, PermissionsState>(
                  listener: (context, state) {
                    if (state is PermissionsSuccess) {}
                  },
                  builder: (context, state) {
                    return Column(
                      children: [
                        context.read<PermissionsBloc>().isManageProject == true
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          const DashBoard(initialIndex: 1),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: const HeroIcon(
                                    HeroIcons.wallet,
                                    style: HeroIconStyle.outline,
                                    color: AppColors.greyColor,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        context.read<PermissionsBloc>().isManageTask == true
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          const DashBoard(initialIndex: 2),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: const HeroIcon(
                                    size: 26,
                                    HeroIcons.documentCheck,
                                    style: HeroIconStyle.outline,
                                    color: AppColors.greyColor,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        context
                                    .read<PermissionsBloc>()
                                    .isManageSystemNotification ==
                                true
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  Navigator.pop(context);
                                  router.push("/Status");
                                  // widget.toggleDrawer(false);
                                  // GoRouter.of(context).pushNamed('StatusScreen');
                                  // router.push("/status");
                                  context
                                      .read<NotificationBloc>()
                                      .add(NotificationList());
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: const HeroIcon(
                                    HeroIcons.square2Stack,
                                    style: HeroIconStyle.outline,
                                    color: AppColors.greyColor,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        context
                                    .read<PermissionsBloc>()
                                    .isManageSystemNotification ==
                                true
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  Navigator.pop(context);
                                  router.push("/priorities");
                                  context
                                      .read<NotificationBloc>()
                                      .add(NotificationList());
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: const HeroIcon(
                                    HeroIcons.arrowUp,
                                    style: HeroIconStyle.outline,
                                    color: AppColors.greyColor,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        context.read<PermissionsBloc>().isManageWorkspace ==
                                true
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  Navigator.pop(context);
                                  router.push('/workspaces',
                                      extra: {"fromNoti": false});
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: const HeroIcon(
                                    HeroIcons.squares2x2,
                                    style: HeroIconStyle.outline,
                                    color: AppColors.greyColor,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        context
                                    .read<PermissionsBloc>()
                                    .isManageSystemNotification ==
                                true
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  Navigator.pop(context);
                                  router.push("/notification");
                                  context
                                      .read<NotificationBloc>()
                                      .add(NotificationList());
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: const HeroIcon(
                                    HeroIcons.bellAlert,
                                    style: HeroIconStyle.outline,
                                    color: AppColors.greyColor,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            Navigator.pop(context);
                            context.read<TodosBloc>().add(const TodosList());
                            router.push("/todos");
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            child: const HeroIcon(
                              HeroIcons.barsArrowUp,
                              style: HeroIconStyle.outline,
                              color: AppColors.greyColor,
                            ),
                          ),
                        ),
                        context.read<PermissionsBloc>().isManageUser == true
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  Navigator.pop(context);
                                  router.push('/user');
                                  BlocProvider.of<UserBloc>(context)
                                      .add(UserList());
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: const HeroIcon(
                                    HeroIcons.users,
                                    style: HeroIconStyle.outline,
                                    color: AppColors.greyColor,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        widget.role == "admin"
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  Navigator.pop(context);
                                  router.push("/settings");
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: const HeroIcon(
                                    HeroIcons.cog6Tooth,
                                    style: HeroIconStyle.outline,
                                    color: AppColors.greyColor,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    );
                  },
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    BlocProvider.of<AuthBloc>(context).add(LoggedOut(
                      context: context,
                    ));
                    router.pop();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: const HeroIcon(
                      HeroIcons.arrowLeftStartOnRectangle,
                      style: HeroIconStyle.outline,
                      color: AppColors.greyColor,
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.h,
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    widget.toggleDrawer(!widget.isExpand);
                  },
                  child: widget.isExpand
                      ? Container(
                          height: 30.h,
                          width: 30.w,
                          decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                              color: AppColors.primary),
                          child: const HeroIcon(
                            size: 15,
                            HeroIcons.arrowRight,
                            style: HeroIconStyle.solid,
                            color: AppColors.pureWhiteColor,
                          ))
                      : Container(),
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _expandedDrawer(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20.0),
        bottomRight: Radius.circular(20.0),
      ),
      child: Drawer(
        elevation: 0,
        width: 270.w,
        backgroundColor: Theme.of(context).colorScheme.bgColorChange,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 20.h,
                ),
                BlocConsumer<UserProfileBloc, UserProfileState>(
                  listener: (context, state) {
                    if (state is UserProfileSuccess) {
                      for (var data in state.profile) {
                        firstNameUser = data.firstName ?? "First Name";
                        lastNameUSer = data.lastName ?? "LastName";
                        email = data.email ?? "Email";
                        roleInUser = data.roleId.toString();
                        photoWidget = data.profile ?? "Photo";
                        role = data.role ?? "Role";
                      }
                    } else if (state is UserProfileError) {}
                  },
                  builder: (context, state) {
                    if (state is UserProfileSuccess) {
                      firstNameUser =
                          context.read<UserProfileBloc>().firstname ??
                              "First Name";
                      lastNameUSer = context.read<UserProfileBloc>().lastName ??
                          "LastName";
                      email = context.read<UserProfileBloc>().email ?? "Email";
                      roleInUser =
                          context.read<UserProfileBloc>().roleId.toString();
                      photoWidget =
                          context.read<UserProfileBloc>().profilePic ?? "Photo";
                      role = context.read<UserProfileBloc>().role ?? "Role";

                      // Use local variable for null safety promotion
                      final String? localPhotoWidget = photoWidget;

                      return widget.photoWidget == null
                          ? Padding(
                              padding: EdgeInsets.only(top: 30.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    // width: 30.w,
                                    child: CircleAvatar(
                                      radius: 26.r,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .backGroundColor,
                                      child: (localPhotoWidget != null &&
                                              localPhotoWidget != "Photo" &&
                                              localPhotoWidget.isNotEmpty)
                                          ? CircleAvatar(
                                              radius: 25.r,
                                              backgroundColor: Colors.grey[200],
                                              backgroundImage: NetworkImage(
                                                  localPhotoWidget),
                                            )
                                          : CircleAvatar(
                                              radius: 25.r,
                                              backgroundColor: Colors.grey[200],
                                              child: Icon(
                                                Icons.person,
                                                size: 20.sp,
                                                color: Colors.grey,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10.h,
                                  ),
                                  firstNameUser != null
                                      ? CustomText(
                                          text:
                                              "${firstNameUser} ${lastNameUSer}",
                                          color: Theme.of(context)
                                              .colorScheme
                                              .textClrChange,
                                        )
                                      : SizedBox(),
                                  email != null
                                      ? CustomText(
                                          text: email ?? "",
                                          size: 12,
                                          color: AppColors.greyColor,
                                        )
                                      : SizedBox()
                                ],
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.only(top: 30.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    // width: 30.w,
                                    child: CircleAvatar(
                                      radius: 26.r,
                                      backgroundColor: AppColors.greyColor,
                                      child: (widget.photoWidget != null &&
                                              _isValidUuid(widget.photoWidget))
                                          ? CircleAvatar(
                                              radius: 25.r,
                                              backgroundImage: NetworkImage(
                                                  '$activePictureUrl/${widget.photoWidget}'),
                                              backgroundColor: Colors.grey[200],
                                            )
                                          : CircleAvatar(
                                              radius: 25.r,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .backGroundColor,
                                              child: CircleAvatar(
                                                radius: 25.r,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                child: Icon(
                                                  Icons.person,
                                                  size: 20.sp,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10.h,
                                  ),
                                  firstNameUser != null
                                      ? CustomText(
                                          text:
                                              "${firstNameUser} ${lastNameUSer}",
                                          color: Theme.of(context)
                                              .colorScheme
                                              .textClrChange,
                                        )
                                      : SizedBox(),
                                  email != null
                                      ? CustomText(
                                          text: email ?? "",
                                          size: 12,
                                          color: AppColors.greyColor,
                                        )
                                      : SizedBox()
                                ],
                              ),
                            );
                    }
                    return Padding(
                      padding: EdgeInsets.only(top: 30.h),
                      child: SizedBox(
                        // width: 26.w,
                        child: CircleAvatar(
                          radius: 26.r,
                          backgroundColor: AppColors.greyColor,
                          child: CircleAvatar(
                            radius: 25.r,
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 12.h,
                ),
                BlocConsumer<PermissionsBloc, PermissionsState>(
                  listener: (context, state) {
                    if (state is PermissionsSuccess) {}
                  },
                  builder: (context, state) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => const DashBoard(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            child: Row(
                              children: [
                                const HeroIcon(
                                  size: 26,
                                  HeroIcons.home,
                                  style: HeroIconStyle.outline,
                                  color: AppColors.greyColor,
                                ),
                                SizedBox(
                                  width: 20.w,
                                ),
                                CustomText(
                                  text: AppLocalizations.of(context)!.home,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .textClrChange,
                                )
                              ],
                            ),
                          ),
                        ),
                        context.read<PermissionsBloc>().isManageInspection !=
                                false
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  widget.toggleDrawer(false);
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          const InspectionScreen(
                                        type: "open",
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: Row(
                                    children: [
                                      const HeroIcon(
                                        size: 26,
                                        HeroIcons.queueList,
                                        style: HeroIconStyle.outline,
                                        color: AppColors.greyColor,
                                      ),
                                      SizedBox(
                                        width: 20.w,
                                      ),
                                      CustomText(
                                        text: AppLocalizations.of(context)!
                                            .myInspections,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .textClrChange,
                                      )
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        context.read<PermissionsBloc>().isManageWork != false
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  Navigator.pop(context);
                                  router.push('/works',
                                      extra: {"fromNoti": false});
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: Row(
                                    children: [
                                      const HeroIcon(
                                        size: 26,
                                        HeroIcons.documentCheck,
                                        style: HeroIconStyle.outline,
                                        color: AppColors.greyColor,
                                      ),
                                      SizedBox(
                                        width: 20.w,
                                      ),
                                      CustomText(
                                        text: AppLocalizations.of(context)!
                                            .myWorks,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .textClrChange,
                                      )
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        context.read<PermissionsBloc>().isManageAssign != false
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  widget.toggleDrawer(false);
                                  // Navigator.of(context).push(
                                  //   CupertinoPageRoute(
                                  //     builder: (context) =>
                                  //         const DashBoard(initialIndex: 2),
                                  //   ),
                                  // );

                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                        builder: (context) => const WorkScreen(
                                              type: "assigned",
                                            )),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: Row(
                                    children: [
                                      const HeroIcon(
                                        size: 26,
                                        HeroIcons.squares2x2,
                                        style: HeroIconStyle.outline,
                                        color: AppColors.greyColor,
                                      ),
                                      SizedBox(
                                        width: 20.w,
                                      ),
                                      CustomText(
                                        text: AppLocalizations.of(context)!
                                            .myAssign,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .textClrChange,
                                      )
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        context.read<PermissionsBloc>().isManageWorkspace !=
                                false
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  // widget.toggleDrawer(false);
                                  Navigator.pop(context);
                                  router.push('/workspaces',
                                      extra: {"fromNoti": false});
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const HeroIcon(
                                            HeroIcons.swatch,
                                            style: HeroIconStyle.outline,
                                            color: AppColors.greyColor,
                                          ),
                                          SizedBox(
                                            width: 20.w,
                                          ),
                                          CustomText(
                                            text: AppLocalizations.of(context)!
                                                .myTeams,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .textClrChange,
                                          ),
                                        ],
                                      ),
                                      Container(
                                        height: 20,
                                        width: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red.shade300,
                                        ),
                                        child: Center(
                                            child: CustomText(
                                          size: 10,
                                          fontWeight: FontWeight.w600,
                                          text:
                                              "${context.read<WorkspaceBloc>().totalWorkspace ?? 0}",
                                          color: AppColors.pureWhiteColor,
                                        )),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        context.read<PermissionsBloc>().isManageProject != false
                            ? InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  widget.toggleDrawer(false);
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          const DashBoard(initialIndex: 1),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: Row(
                                    children: [
                                      const HeroIcon(
                                        HeroIcons.wallet,
                                        style: HeroIconStyle.outline,
                                        color: AppColors.greyColor,
                                      ),
                                      SizedBox(
                                        width: 20.w,
                                      ),
                                      CustomText(
                                        text: AppLocalizations.of(context)!
                                            .statistics,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .textClrChange,
                                      )
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    );
                  },
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    // widget.toggleDrawer(false);
                    Navigator.pop(context);
                    router.push("/todos");
                    BlocProvider.of<TodosBloc>(context).add(TodosList());
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Row(
                      children: [
                        const HeroIcon(
                          HeroIcons.barsArrowUp,
                          style: HeroIconStyle.outline,
                          color: AppColors.greyColor,
                        ),
                        SizedBox(
                          width: 20.w,
                        ),
                        CustomText(
                          text: AppLocalizations.of(context)!.todos,
                          color: Theme.of(context).colorScheme.textClrChange,
                        )
                      ],
                    ),
                  ),
                ),
                context.read<PermissionsBloc>().isManageUser != false
                    ? InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          // widget.toggleDrawer(false);
                          Navigator.pop(context);
                          router.push('/user');
                          BlocProvider.of<UserBloc>(context).add(UserList());
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Row(
                            children: [
                              const HeroIcon(
                                HeroIcons.users,
                                style: HeroIconStyle.outline,
                                color: AppColors.greyColor,
                              ),
                              SizedBox(
                                width: 20.w,
                              ),
                              CustomText(
                                text: AppLocalizations.of(context)!
                                    .usersFordrawer,
                                color:
                                    Theme.of(context).colorScheme.textClrChange,
                              )
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                context.read<PermissionsBloc>().isManageSystemNotification !=
                        false
                    ? InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          // widget.toggleDrawer(false);
                          Navigator.pop(context);
                          router.push("/notification");
                          context
                              .read<NotificationBloc>()
                              .add(NotificationList());
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const HeroIcon(
                                    HeroIcons.bellAlert,
                                    style: HeroIconStyle.outline,
                                    color: AppColors.greyColor,
                                  ),
                                  SizedBox(
                                    width: 20.w,
                                  ),
                                  CustomText(
                                    text: AppLocalizations.of(context)!
                                        .notifications,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .textClrChange,
                                  )
                                ],
                              ),
                              BlocConsumer<NotificationBloc,
                                      NotificationsState>(
                                  listener: (context, state) {
                                if (state is NotificationPaginated) {}
                              }, builder: (context, state) {
                                if (state is UnreadNotification) {
                                  return Container(
                                    height: 20,
                                    width: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.yellow.shade800,
                                    ),
                                    child: Center(
                                        child: CustomText(
                                      size: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      text: "${state.total}",
                                      color: AppColors.pureWhiteColor,
                                    )),
                                  );
                                }
                                return SizedBox();
                              })
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                widget.role == "admin"
                    ? InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          // widget.toggleDrawer(false);
                          Navigator.pop(context);
                          router.push("/settings");
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Row(
                            children: [
                              const HeroIcon(
                                HeroIcons.cog6Tooth,
                                style: HeroIconStyle.outline,
                                color: AppColors.greyColor,
                              ),
                              SizedBox(
                                width: 20.w,
                              ),
                              CustomText(
                                text: AppLocalizations.of(context)!.settings,
                                color:
                                    Theme.of(context).colorScheme.textClrChange,
                              )
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    // widget.toggleDrawer(false);
                    BlocProvider.of<AuthBloc>(context).add(LoggedOut(
                      context: context,
                    ));
                    router.replace('/login');
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Row(
                      children: [
                        const HeroIcon(
                          HeroIcons.arrowLeftStartOnRectangle,
                          style: HeroIconStyle.outline,
                          color: AppColors.greyColor,
                        ),
                        SizedBox(
                          width: 20.w,
                        ),
                        CustomText(
                          text: AppLocalizations.of(context)!.logout,
                          color: Theme.of(context).colorScheme.textClrChange,
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 15.h,
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    widget.toggleDrawer(!widget.isExpand);
                  },
                  child: !widget.isExpand
                      ? Container(
                          height: 30.h,
                          width: 30.w,
                          decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                              color: AppColors.primary),
                          child: const HeroIcon(
                            size: 15,
                            HeroIcons.arrowLeft,
                            style: HeroIconStyle.solid,
                            color: AppColors.whiteColor,
                          ))
                      : Container(),
                ),
                const SizedBox(
                  height: 100,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceItem(String text, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          CircleAvatar(radius: 3, backgroundColor: AppColors.primary),
          SizedBox(width: 10.w),
          CustomText(
            text: text,
            color: Theme.of(context).colorScheme.textClrChange,
          ),
        ],
      ),
    );
  }
}
