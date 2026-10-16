import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';

import 'package:ibex/bloc/permissions/permissions_bloc.dart';
import 'package:ibex/config/colors.dart';
import 'package:ibex/routes/routes.dart';
import 'package:ibex/src/generated/i18n/app_localizations.dart';

class MoreActionButton extends StatelessWidget {
  final BuildContext context;
  final int? itemId;
  final String? itemTitle;
  final bool isProject; // true = Work, false = Task
  final int? clientCanDiscuss;
  final String? role;
  final VoidCallback? onpressAssign;
  final VoidCallback? onpressApprove;
  final VoidCallback? onpressDecline; //sent to request
  final VoidCallback? onpressReturn; //approved bol butsaana
  final bool isSmall; // ✅ Шинэ parameter нэмэх

  const MoreActionButton({
    Key? key,
    required this.context,
    this.itemId,
    this.itemTitle,
    this.isProject = true,
    this.clientCanDiscuss,
    this.role,
    this.onpressAssign,
    this.onpressApprove,
    this.onpressDecline,
    this.onpressReturn,
    this.isSmall = false, // ✅ Default: false (энгийн хэмжээ)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Dynamic хэмжээ
    final double buttonSize = isSmall ? 24.h : 28.h;
    final double iconSize = isSmall ? 12.sp : 14.sp;
    final double borderRadius = isSmall ? 5.r : 6.r;

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor:
              Theme.of(context).colorScheme.alertBoxBackGroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20.r),
            ),
          ),
          builder: (context) {
            return Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onpressDecline != null &&
                      (isProject
                          ? context.read<PermissionsBloc>().iseditWork == true
                          : context.read<PermissionsBloc>().iseditTask == true))
                    ListTile(
                      leading: HeroIcon(
                        HeroIcons.xCircle,
                        color: Colors.pink,
                        style: HeroIconStyle.solid,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.decline,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onpressDecline?.call();
                      },
                    ),
                  // Assign option
                  if (onpressAssign != null &&
                      (isProject
                          ? context.read<PermissionsBloc>().iseditWork == true
                          : context.read<PermissionsBloc>().iseditTask == true))
                    ListTile(
                      leading: HeroIcon(
                        HeroIcons.share,
                        color: Colors.blue,
                        style: HeroIconStyle.solid,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.assign,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onpressAssign?.call();
                      },
                    ),

                  // Approve option
                  if (onpressApprove != null &&
                      (isProject
                          ? context.read<PermissionsBloc>().isdeleteWork == true
                          : context.read<PermissionsBloc>().isdeleteTask ==
                              true))
                    ListTile(
                      leading: HeroIcon(
                        HeroIcons.checkCircle,
                        color: Colors.green,
                        style: HeroIconStyle.solid,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.approve,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onpressApprove?.call();
                      },
                    ),

                  if (onpressReturn != null &&
                      (isProject
                          ? context.read<PermissionsBloc>().iseditWork == true
                          : context.read<PermissionsBloc>().iseditTask == true))
                    ListTile(
                      leading: HeroIcon(
                        HeroIcons.xCircle,
                        color: Colors.orange,
                        style: HeroIconStyle.solid,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.dontapprove,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onpressReturn?.call();
                      },
                    ),

                  // Discussion option
                  if (clientCanDiscuss == 1)
                    ListTile(
                      leading: HeroIcon(
                        HeroIcons.chatBubbleBottomCenterText,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.discussion,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        router.push(
                          isProject
                              ? "/discussionTabs"
                              : "/worktaskdiscussionTabs",
                          extra: {"isDetail": true, "id": itemId},
                        );
                      },
                    ),

                  // Chat option
                  // if (role != "Client" || clientCanDiscuss == 1)
                  //   ListTile(
                  //     leading: HeroIcon(
                  //       HeroIcons.chatBubbleBottomCenter,
                  //       color: Colors.green,
                  //     ),
                  //     title: Text(
                  //       AppLocalizations.of(context)!.chats,
                  //     ),
                  //     onTap: () {
                  //       Navigator.pop(context);
                  //       router.push(
                  //         "/commentsection",
                  //         extra: {
                  //           "id": itemId,
                  //           "title": itemTitle,
                  //           "isProject": isProject,
                  //         },
                  //       );
                  //       context.read<CommentsBloc>().isProject = isProject;
                  //     },
                  //   ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        height: buttonSize, // ✅ Dynamic height
        width: buttonSize, // ✅ Dynamic width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius), // ✅ Dynamic radius
          color: AppColors.primary.withValues(alpha: 0.15),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: HeroIcon(
          HeroIcons.ellipsisVertical,
          size: iconSize, // ✅ Dynamic icon size
          style: HeroIconStyle.solid,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
