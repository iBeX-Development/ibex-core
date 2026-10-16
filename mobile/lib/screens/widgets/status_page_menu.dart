import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';

import 'package:ibex/config/colors.dart';
import 'package:ibex/data/localStorage/hive.dart';

import 'package:ibex/src/generated/i18n/app_localizations.dart';

class MoreStatusButton extends StatelessWidget {
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
  final Function(int statusId, String statusText)?
      onStatusChanged; // ✅ Status сонгоход дуудах callback

  const MoreStatusButton({
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
    this.onStatusChanged,
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
            return FutureBuilder<List<Object>?>(
              future: HiveStorage.getAllStatusData(),
              builder: (context, snapshot) {
                final statusList = snapshot.data ?? [];

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ Status жагсаалт Hive-аас
                        if (statusList.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 8.h),
                            child: Text(
                              AppLocalizations.of(context)!.status,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...statusList
                              .where((e) => e is Map<String, dynamic>)
                              .map((statusObj) {
                            final status = statusObj as Map<String, dynamic>;
                            final statusId =
                                status['status_value'] ?? status['id'];
                            final statusText =
                                status['status_text'] ?? status['title'] ?? '';

                            // ✅ Debug: Print full status object
                            // print("📊 Status object: $status");

                            // ✅ Get icon from status or infer from statusText
                            String? statusIcon = status['icon']?.toString();

                            // ✅ Fallback: Infer icon from status text if icon is null
                            if (statusIcon == null || statusIcon.isEmpty) {
                              statusIcon = _inferIconFromStatusText(statusText);
                            }

                            // Parse color
                            Color statusColor = AppColors.primary;
                            if (status['code_color'] != null &&
                                status['code_color'] is Map) {
                              final codeColor =
                                  status['code_color'] as Map<String, dynamic>;
                              final colorHex =
                                  codeColor['text_color']?.toString();
                              if (colorHex != null) {
                                try {
                                  final hex = colorHex.replaceAll('#', '');
                                  statusColor =
                                      Color(int.parse('FF$hex', radix: 16));
                                } catch (e) {
                                  statusColor = AppColors.primary;
                                }
                              }
                            }

                            // ✅ Get icon based on status data
                            HeroIcons iconData = _getStatusIcon(statusIcon);

                            return ListTile(
                              leading: Container(
                                width: 32.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor.withValues(alpha: 0.15),
                                ),
                                child: Center(
                                  child: HeroIcon(
                                    iconData,
                                    size: 18.sp,
                                    style: HeroIconStyle.solid,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              title: Text(statusText),
                              onTap: () {
                                Navigator.pop(context);
                                if (onStatusChanged != null &&
                                    statusId != null) {
                                  onStatusChanged!(statusId, statusText);
                                }
                              },
                            );
                          }).toList(),
                          Divider(height: 20.h),
                        ],

                        // ✅ Бусад action-ууд
                        // if (onpressDecline != null &&
                        //     (isProject
                        //         ? context.read<PermissionsBloc>().iseditWork ==
                        //             true
                        //         : context.read<PermissionsBloc>().iseditTask ==
                        //             true))
                        //   ListTile(
                        //     leading: HeroIcon(
                        //       HeroIcons.xCircle,
                        //       color: Colors.pink,
                        //       style: HeroIconStyle.solid,
                        //     ),
                        //     title: Text(
                        //       AppLocalizations.of(context)!.decline,
                        //     ),
                        //     onTap: () {
                        //       Navigator.pop(context);
                        //       onpressDecline?.call();
                        //     },
                        //   ),
                        // // Assign option
                        // if (onpressAssign != null &&
                        //     (isProject
                        //         ? context.read<PermissionsBloc>().iseditWork ==
                        //             true
                        //         : context.read<PermissionsBloc>().iseditTask ==
                        //             true))
                        //   ListTile(
                        //     leading: HeroIcon(
                        //       HeroIcons.share,
                        //       color: Colors.blue,
                        //       style: HeroIconStyle.solid,
                        //     ),
                        //     title: Text(
                        //       AppLocalizations.of(context)!.assign,
                        //     ),
                        //     onTap: () {
                        //       Navigator.pop(context);
                        //       onpressAssign?.call();
                        //     },
                        //   ),

                        // // Approve option
                        // if (onpressApprove != null &&
                        //     (isProject
                        //         ? context.read<PermissionsBloc>().isdeleteWork ==
                        //             true
                        //         : context.read<PermissionsBloc>().isdeleteTask ==
                        //             true))
                        //   ListTile(
                        //     leading: HeroIcon(
                        //       HeroIcons.checkCircle,
                        //       color: Colors.green,
                        //       style: HeroIconStyle.solid,
                        //     ),
                        //     title: Text(
                        //       AppLocalizations.of(context)!.approve,
                        //     ),
                        //     onTap: () {
                        //       Navigator.pop(context);
                        //       onpressApprove?.call();
                        //     },
                        //   ),

                        // if (onpressReturn != null &&
                        //     (isProject
                        //         ? context.read<PermissionsBloc>().iseditWork ==
                        //             true
                        //         : context.read<PermissionsBloc>().iseditTask ==
                        //             true))
                        //   ListTile(
                        //     leading: HeroIcon(
                        //       HeroIcons.xCircle,
                        //       color: Colors.orange,
                        //       style: HeroIconStyle.solid,
                        //     ),
                        //     title: Text(
                        //       AppLocalizations.of(context)!.dontapprove,
                        //     ),
                        //     onTap: () {
                        //       Navigator.pop(context);
                        //       onpressReturn?.call();
                        //     },
                        //   ),

                        // // Discussion option
                        // if (clientCanDiscuss == 1)
                        //   ListTile(
                        //     leading: HeroIcon(
                        //       HeroIcons.chatBubbleBottomCenterText,
                        //       color: AppColors.primary,
                        //     ),
                        //     title: Text(
                        //       AppLocalizations.of(context)!.discussion,
                        //     ),
                        //     onTap: () {
                        //       Navigator.pop(context);
                        //       router.push(
                        //         isProject
                        //             ? "/discussionTabs"
                        //             : "/worktaskdiscussionTabs",
                        //         extra: {"isDetail": true, "id": itemId},
                        //       );
                        //     },
                        //   ),

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
                  ),
                );
              },
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

  // ✅ Helper function: Map icon string to HeroIcons
  static HeroIcons _getStatusIcon(String? iconString) {
    if (iconString == null || iconString.isEmpty) {
      return HeroIcons.clipboardDocumentList;
    }

    // Clean icon string
    final cleanIcon = iconString.toLowerCase().trim();
    // ✅ Comprehensive icon mapping
    final iconMap = <String, HeroIcons>{
      // Clock icons
      'uit:clock': HeroIcons.clock,
      'clock': HeroIcons.clock,
      'time': HeroIcons.clock,

      // Check/Success icons
      'check': HeroIcons.checkCircle,
      'check-circle': HeroIcons.checkCircle,
      'checkcircle': HeroIcons.checkCircle,
      'success': HeroIcons.checkCircle,
      'complete': HeroIcons.checkCircle,
      'done': HeroIcons.checkCircle,

      // Close/Cancel icons
      'x': HeroIcons.xCircle,
      'x-circle': HeroIcons.xCircle,
      'xcircle': HeroIcons.xCircle,
      'close': HeroIcons.xCircle,
      'cancel': HeroIcons.xCircle,
      'delete': HeroIcons.xCircle,

      // Warning/Alert icons
      'exclamation': HeroIcons.exclamationCircle,
      'exclamation-circle': HeroIcons.exclamationCircle,
      'exclamationcircle': HeroIcons.exclamationCircle,
      'warning': HeroIcons.exclamationTriangle,
      'alert': HeroIcons.exclamationTriangle,

      // Lock icons
      'gis:map-unlock': HeroIcons.lockOpen,
      'lock-open': HeroIcons.lockOpen,
      'unlock': HeroIcons.lockOpen,
      'open': HeroIcons.lockOpen,
      'lock': HeroIcons.lockClosed,
      'locked': HeroIcons.lockClosed,

      // Play/Pause icons
      'play': HeroIcons.play,
      'start': HeroIcons.play,
      'pause': HeroIcons.pause,
      'stop': HeroIcons.stop,
      'end': HeroIcons.stop,

      // Progress icons
      'progress': HeroIcons.arrowPath,
      'in-progress': HeroIcons.arrowPath,
      'inprogress': HeroIcons.arrowPath,
      'pending': HeroIcons.clock,
      'waiting': HeroIcons.clock,

      // Archive/Storage icons
      'archive': HeroIcons.archiveBox,
      'box': HeroIcons.archiveBox,
      'folder': HeroIcons.folder,
      'file': HeroIcons.document,
      'document': HeroIcons.documentText,

      // Tool icons
      'wrench': HeroIcons.wrench,
      'tool': HeroIcons.wrench,
      'repair': HeroIcons.wrench,
      'fix': HeroIcons.wrench,
      'cog': HeroIcons.cog6Tooth,
      'settings': HeroIcons.cog6Tooth,
      'gear': HeroIcons.cog6Tooth,

      // Status icons
      'new': HeroIcons.sparkles,
      'draft': HeroIcons.pencilSquare,
      'review': HeroIcons.eyeSlash,
      'approved': HeroIcons.checkBadge,
      'rejected': HeroIcons.xMark,
      'closed': HeroIcons.lockClosed,
      'reopened': HeroIcons.arrowPath,

      // Arrow icons
      'arrow-right': HeroIcons.arrowRight,
      'arrow-left': HeroIcons.arrowLeft,
      'arrow-up': HeroIcons.arrowUp,
      'arrow-down': HeroIcons.arrowDown,

      // Misc
      'info': HeroIcons.informationCircle,
      'question': HeroIcons.questionMarkCircle,
      'plus': HeroIcons.plusCircle,
      'minus': HeroIcons.minusCircle,
      'list': HeroIcons.listBullet,
      'clipboard': HeroIcons.clipboardDocumentList,
    };

    // Try exact match on cleaned string
    if (iconMap.containsKey(cleanIcon)) {
      return iconMap[cleanIcon]!;
    }

    // Try to extract icon name after colon (e.g., "uit:clock" -> "clock")
    if (cleanIcon.contains(':')) {
      final iconName = cleanIcon.split(':').last.trim();
      if (iconMap.containsKey(iconName)) {
        return iconMap[iconName]!;
      }
    }

    // Try to match partial string
    for (var entry in iconMap.entries) {
      if (cleanIcon.contains(entry.key) || entry.key.contains(cleanIcon)) {
        return entry.value;
      }
    }

    // Default fallback
    return HeroIcons.clipboardDocumentList;
  }

  // ✅ Helper: Infer icon from status text when icon field is null
  static String _inferIconFromStatusText(String statusText) {
    final lowerText = statusText.toLowerCase().trim();

    // Map status text keywords to icon strings
    if (lowerText.contains('progress') || lowerText.contains('progressing')) {
      return 'inprogress';
    } else if (lowerText.contains('wait') || lowerText.contains('spare')) {
      return 'clock';
    } else if (lowerText.contains('close') || lowerText.contains('closed')) {
      return 'closed';
    } else if (lowerText.contains('open') || lowerText.contains('unlock')) {
      return 'open';
    } else if (lowerText.contains('new') || lowerText.contains('created')) {
      return 'new';
    } else if (lowerText.contains('complete') || lowerText.contains('done')) {
      return 'complete';
    } else if (lowerText.contains('approve') ||
        lowerText.contains('approved')) {
      return 'approved';
    } else if (lowerText.contains('reject') || lowerText.contains('declined')) {
      return 'rejected';
    } else if (lowerText.contains('cancel')) {
      return 'cancel';
    } else if (lowerText.contains('pending')) {
      return 'pending';
    } else if (lowerText.contains('review')) {
      return 'review';
    } else if (lowerText.contains('draft')) {
      return 'draft';
    }

    // Default fallback
    return 'clipboard';
  }
}
