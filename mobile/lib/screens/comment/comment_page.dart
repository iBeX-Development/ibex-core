import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:heroicons/heroicons.dart';
import 'package:ibex/config/colors.dart';

import 'package:ibex/utils/widgets/custom_text.dart';
import '../../bloc/comments/comments_bloc.dart';
import '../../bloc/comments/comments_event.dart';
import '../../bloc/comments/comments_state.dart';

import '../../data/model/discussion/discussion_model.dart';
import '../../data/repositories/comments/comment_repo.dart';

import 'comment_widgets/chat_header.dart';
import 'comment_widgets/floating_actionbar.dart';
import 'comment_widgets/comment_item.dart';
import '../../../src/generated/i18n/app_localizations.dart';

class CommentSection extends StatefulWidget {
  final int? id;
  final int? work_order;
  final String? title;
  final String? model;
  final bool? isProject;

  const CommentSection({
    super.key,
    this.id,
    this.title,
    this.model,
    this.isProject,
    this.work_order,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final ScrollController _scrollController = ScrollController();
  late CommentsBloc _commentsBloc;
  final Map<String, bool> _isExpanded = {};

  @override
  void initState() {
    super.initState();
    _commentsBloc = CommentsBloc(discussionRepo: DiscussionRepo())
      ..add(
        LoadComments(
          id: widget.id ?? 0,
          limit: 20,
          offset: 0,
          isProject: widget.isProject!,
          work_order: widget.work_order,
          model: widget.model,
        ),
      );
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        _commentsBloc.loadMoreComments(widget.isProject!);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentsBloc.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    _commentsBloc.add(
      LoadComments(
        id: widget.id ?? 0,
        limit: 20,
        offset: 0,
        isProject: widget.isProject!,
        work_order: widget.work_order,
        model: widget.model,
      ),
    );
    await _commentsBloc.stream.firstWhere(
      (state) => state is CommentLoaded || state is CommentError,
    );
  }

  void _toggleExpanded(String commentId) {
    setState(() {
      _isExpanded[commentId] = !(_isExpanded[commentId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _commentsBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.white,
        body: Container(
          decoration: BoxDecoration(
            // borderRadius: BorderRadius.circular(20),
            // gradient: LinearGradient(
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            //   colors: AppColors.chatBackgroundColor,
            // ),
          ),
          child: Column(
            children: [
              widget.model == "inspectioncomment"
                  ? SizedBox(height: 5.h)
                  : ChatHeader(title: widget.title ?? ""),
              Expanded(
                child: RefreshIndicator(
                  backgroundColor: Colors.white,
                  color: const Color(0xFF6366F1),
                  onRefresh: _onRefresh,
                  child: BlocConsumer<CommentsBloc, CommentsState>(
                    listener: (context, state) {
                      if (state is CommentDeleteSuccess) {
                        Fluttertoast.showToast(
                          msg: AppLocalizations.of(
                            context,
                          )!.deletedsuccessfully,
                        );
                      } else if (state is CommentDeleteError) {
                        Fluttertoast.showToast(msg: state.errorMessage);
                      } else if (state is CommentError) {
                        Fluttertoast.showToast(
                          msg: AppLocalizations.of(
                            context,
                          )!.failedtoaddorupdatecomment,
                        );
                      }
                    },
                    builder: (context, state) {
                      List<CommentModel> comments = [];
                      bool isLoadingMore = false;
                      if (state is CommentInitial) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF6366F1),
                          ),
                        );
                      }
                      if (state is CommentLoading) {
                        comments = state.currentComments;
                      } else if (state is CommentLoadMoreLoading) {
                        comments = state.currentComments;
                        isLoadingMore = true;
                      } else if (state is CommentLoaded ||
                          state is CommentEditState) {
                        comments = state is CommentLoaded
                            ? state.comments
                            : (state as CommentEditState).comments;
                      } else if (state is CommentError) {
                        return Center(child: Text(state.message));
                      }

                      // ✅ Show simple loading if first-time loading and comments are empty
                      if (state is CommentLoading && comments.isEmpty) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF6366F1),
                          ),
                        );
                      }

                      // ✅ Show "No Comments" if loaded but empty
                      if (comments.isEmpty) {
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 24.sp,
                                color: const Color(0xFFD1D5DB),
                              ),
                              SizedBox(height: 16.h),
                              CustomText(
                                text: "No comments",
                                color: const Color(0xFF6B7280),
                                size: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              SizedBox(height: 8.h),
                              CustomText(
                                text: AppLocalizations.of(
                                  context,
                                )!.betheonetobreaktheice,
                                color: const Color(0xFF9CA3AF),
                                size: 14.sp,
                                fontWeight: FontWeight.w400,
                              ),
                              SizedBox(height: 16.h),
                              IconButton(
                                onPressed: _onRefresh,
                                icon: Icon(
                                  Icons.refresh,
                                  size: 14.sp,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Render comments list
                      return ListView.builder(
                        key: ValueKey(comments.length),
                        padding: EdgeInsets.only(
                          bottom: 80.h,
                          top: 16.h,
                          left: 16.w,
                          right: 16.w,
                        ),
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: comments.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Loading spinner for pagination
                          if (index == comments.length && isLoadingMore) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: SpinKitThreeBounce(
                                  color: const Color(0xFF6366F1),
                                  size: 40.0,
                                ),
                              ),
                            );
                          }

                          final comment = comments[index];
                          return _buildCommentItem(context, comment, comments);
                        },
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: FloatingActionBar(
                  isProject: widget.isProject!,
                  commentsBloc: _commentsBloc,
                  discussionId: widget.id,
                  model: widget.model,
                  work_order: widget.work_order,
                  onCommentAdded: () {
                    _commentsBloc.add(
                      LoadComments(
                        id: widget.id ?? 0,
                        limit: 20,
                        offset: 0,
                        model: widget.model,
                        isProject: widget.isProject!,
                        work_order: widget.work_order,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    CommentModel comment,
    List<CommentModel> allComments,
  ) {
    final commentId = comment.id?.toString() ?? '';
    final replyCount = comment.children?.length ?? 0;
    final isExpanded = _isExpanded[commentId] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment
        CommentItem(
          avatarUrl:
              comment.commenter?.avatar ?? 'https://i.pravatar.cc/150?img=4',
          name:
              '${comment.commenter?.firstName ?? ''} ${comment.commenter?.lastName ?? ''}',
          message: comment.content ?? '',
          time: comment.sentTime ?? '',
          attachments: comment.attachments ?? <CommentsAttachments>[],
          commentId: commentId,
          replyCount: replyCount,
          onUpdate: (message, parentName, parentId) {
            setState(() {
              context.read<CommentsBloc>().isUpdate = true;
              context.read<CommentsBloc>().parentId = parentId;
              context.read<CommentsBloc>().content = message;
            });
          },
          onDelete: () async {
            FocusScope.of(context).unfocus();
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.confirmDelete,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: const Text(
                    "Are you sure you want to delete this comment?",
                    style: TextStyle(color: Colors.black87),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        AppLocalizations.of(context)!.delete,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );

            if (confirm == true) {
              context.read<CommentsBloc>().add(
                DeleteComment(
                  int.parse(comment.id!),
                  widget.isProject!,
                  widget.model,
                  widget.work_order,
                ),
              );

              // Reload comments list after deletion
              await Future.delayed(Duration(milliseconds: 500));
              _commentsBloc.add(
                LoadComments(
                  id: widget.id ?? 0,
                  limit: 20,
                  offset: 0,
                  isProject: widget.isProject!,
                  work_order: widget.work_order,
                  model: widget.model,
                ),
              );
            }
          },
          isProject: widget.isProject!,
          commentatorId: comment.commenter!.id.toString(),
          isReply: false,
        ),

        // Replies toggle
        if (replyCount > 0)
          Padding(
            padding: EdgeInsets.only(left: 52.w, top: 4.h, bottom: 8.h),
            child: InkWell(
              onTap: () => _toggleExpanded(commentId),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HeroIcon(
                    isExpanded ? HeroIcons.chevronUp : HeroIcons.chevronDown,
                    style: HeroIconStyle.outline,
                    size: 14.sp,
                    color: const Color(0xFF6366F1),
                  ),
                  SizedBox(width: 4.w),
                  CustomText(
                    text: isExpanded
                        ? "${AppLocalizations.of(context)!.hidereplies}"
                        : "$replyCount ${replyCount == 1 ? 'reply' : 'replies'}",
                    color: const Color(0xFF6366F1),
                    size: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),

        // Replies
        if (isExpanded &&
            comment.children != null &&
            comment.children!.isNotEmpty)
          ...comment.children!.map((child) {
            return CommentItem(
              avatarUrl:
                  child.commenter?.avatar ?? 'https://i.pravatar.cc/150?img=4',
              name:
                  '${child.commenter?.firstName ?? ''} ${child.commenter?.lastName ?? ''}',
              message: child.content ?? '',
              time: child.sentTime ?? '',
              attachments: child.attachments ?? <CommentsAttachments>[],
              commentId: child.id?.toString() ?? '',
              replyCount: 0,
              onUpdate: (message, parentName, parentId) {
                setState(() {
                  context.read<CommentsBloc>().isUpdate = true;
                  context.read<CommentsBloc>().parentId = parentId;
                  context.read<CommentsBloc>().content = message;
                });
              },
              onDelete: () async {
                FocusScope.of(context).unfocus();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.confirmDelete,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!.areyousurewanttodeletethiscomment,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            AppLocalizations.of(context)!.delete,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  context.read<CommentsBloc>().add(
                    DeleteComment(
                      int.parse(child.id!),
                      widget.isProject!,
                      widget.model,
                      widget.work_order,
                    ),
                  );

                  // Reload comments list after deletion
                  await Future.delayed(Duration(milliseconds: 500));
                  _commentsBloc.add(
                    LoadComments(
                      id: widget.id ?? 0,
                      limit: 20,
                      offset: 0,
                      isProject: widget.isProject!,
                      work_order: widget.work_order,
                      model: widget.model,
                    ),
                  );
                }
              },
              isProject: widget.isProject!,
              commentatorId: child.commenter!.id.toString(),
              isReply: true,
            );
          }),
      ],
    );
  }
}

// Custom Painter for drawing the vertical line
class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
