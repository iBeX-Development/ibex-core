import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';
import 'package:ibex/config/constants.dart';

import '../../../bloc/auth/auth_bloc.dart';

import '../../../data/localStorage/hive.dart';
import '../../../data/model/discussion/discussion_model.dart';
import '../../../utils/widgets/custom_text.dart';

class CommentItem extends StatefulWidget {
  final String avatarUrl;
  final String name;
  final String message;
  final String time;
  final List<CommentsAttachments> attachments;
  final String commentId;
  final int replyCount;
  final Function(String, String, String) onUpdate;
  final VoidCallback onDelete;
  final bool isProject;
  final String commentatorId;
  final bool isReply;

  const CommentItem({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.message,
    required this.time,
    required this.attachments,
    required this.commentId,
    required this.replyCount,
    required this.onUpdate,
    required this.onDelete,
    required this.isProject,
    required this.commentatorId,
    this.isReply = false,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _showMenu = false;
  int? userId;

  @override
  void initState() {
    super.initState();
    _getUserID();
  }

  Future<void> _getUserID() async {
    final id = await HiveStorage.getUserId();
    setState(() {
      userId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPermission =
        context.read<AuthBloc>().hasAllDataAccess ?? false;
    final String role = context.read<AuthBloc>().role ?? '';
    final bool isAdmin = role.toLowerCase() == "admin";
    final bool canEditOrDelete =
        isAdmin || hasPermission || widget.commentatorId == userId.toString();

    return Container(
      margin: EdgeInsets.only(
        bottom: 12.h,
        left: widget.isReply ? 48.w : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            backgroundImage: widget.avatarUrl.isNotEmpty
                ? NetworkImage('${activePictureUrl}/${widget.avatarUrl}')
                : const AssetImage("assets/images/png/person.png")
                    as ImageProvider,
            radius: 20.r,
            backgroundColor: Colors.grey[300],
          ),
          SizedBox(width: 12.w),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and time header
                Transform.translate(
                  offset: Offset(0, -4.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: CustomText(
                                text: widget.name,
                                size: 14.sp,
                                color: const Color(0xFF1F2937),
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            CustomText(
                              text: widget.time,
                              size: 12.sp,
                              color: const Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w400,
                            ),
                            if (canEditOrDelete) ...[
                              SizedBox(width: 8.w),
                              InkWell(
                                onTap: widget.onDelete,
                                child: HeroIcon(
                                  HeroIcons.trash,
                                  size: 16.sp,
                                  color: Colors.red.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Message content
                Transform.translate(
                  offset: Offset(0, -2.h),
                  child: CustomText(
                    text: widget.message,
                    size: 14.sp,
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w400,
                    textAlign: TextAlign.left,
                  ),
                ),
                SizedBox(height: 8.h),

                // Attachments
                // if (widget.attachments.isNotEmpty)
                //   Padding(
                //     padding: EdgeInsets.only(top: 8.h),
                //     child: AttachmentBubble(
                //       attachments: widget.attachments,
                //       isProject: widget.isProject,
                //     ),
                //   ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
