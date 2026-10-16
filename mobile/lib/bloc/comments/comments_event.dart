// import 'package:equatable/equatable.dart';
// import 'dart:io';
//
// abstract class CommentsEvent extends Equatable {
//   const CommentsEvent();
//
//   @override
//   List<Object?> get props => [];
// }
//
// class LoadComments extends CommentsEvent {
//   final int id;
//   final int limit;
//   final int offset;
//   final String? search;
//   final bool isFollowUp;
//
//   const LoadComments({
//     required this.id,
//     this.limit = 10,
//     this.offset = 0,
//     this.search,
//     this.isFollowUp = false,
//   });
//
//   @override
//   List<Object?> get props => [id, limit, offset, search];
// }
//
// class AddComment extends CommentsEvent {
//   final String modelType;
//   final int modelId;
//   final String content;
//   final String parentId;
//   final List<File> media;
//
//   const AddComment({
//     required this.modelType,
//     required this.modelId,
//     required this.content,
//     required this.parentId,
//     required this.media,
//   });
//
//   @override
//   List<Object?> get props => [modelType, modelId, content, parentId, media];
// }
//
// class RefreshComments extends CommentsEvent {
//   final int id;
//   final String? search;
//
//   const RefreshComments({
//     required this.id,
//     this.search,
//   });
//
//   @override
//   List<Object?> get props => [id, search];
// }
// class DeleteComment extends CommentsEvent {
//   final int commentId;
//
//   DeleteComment(this.commentId );
//
//   @override
//   List<Object?> get props => [commentId];
// }
// class UpdateComment extends CommentsEvent {
//   final String commentId;
//   final String content;
//   final List<File> media;
//   const UpdateComment({
//     required this.commentId,
//     required this.content,
//     this.media = const [],
//   });
// }
// comments_event.dart
import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../data/model/discussion/discussion_model.dart';

abstract class CommentsEvent extends Equatable {
  const CommentsEvent();

  @override
  List<Object?> get props => [];
}

class FocusCommentTextField extends CommentsEvent {
  FocusCommentTextField();
}

class AddCommentOptimistic extends CommentsEvent {
  final CommentModel tempComment;
  final bool isProject;
  const AddCommentOptimistic(this.tempComment, this.isProject);
}

class EditComment extends CommentsEvent {
  final String content;
  final String parentName;
  final String? model;

  EditComment({required this.content, required this.parentName, this.model});
}

class LoadComments extends CommentsEvent {
  final int id;
  final int limit;
  final int offset;
  final int? work_order;
  final String? search;
  final String? model;
  final bool isProject;

  const LoadComments({
    required this.id,
    required this.isProject,
    this.limit = 20,
    this.offset = 0,
    this.work_order,
    this.model,
    this.search,
  });

  @override
  List<Object?> get props =>
      [id, limit, offset, search, model, isProject, work_order];
}

class AddComment extends CommentsEvent {
  final String modelType;
  final int modelId;
  final String content;
  final String parentId;
  final String? model;
  final int? work_order;
  final List<File> media;
  final bool isProject;

  const AddComment({
    required this.modelType,
    required this.modelId,
    required this.content,
    required this.parentId,
    required this.isProject,
    required this.media,
    this.model,
    this.work_order,
  });

  @override
  List<Object?> get props => [
        modelType,
        modelId,
        content,
        parentId,
        media,
        model,
        isProject,
        work_order
      ];
}

class RefreshComments extends CommentsEvent {
  final int id;
  final int? work_order;
  final String? search;
  final String? model;
  final bool isProject;

  const RefreshComments(
      {required this.id,
      this.search,
      this.model,
      required this.isProject,
      this.work_order});

  @override
  List<Object?> get props => [id, search, model, isProject, work_order];
}

class DeleteComment extends CommentsEvent {
  final int commentId;
  final bool isProject;
  final String? model;
  final int? work_order;

  const DeleteComment(
      this.commentId, this.isProject, this.model, this.work_order);

  @override
  List<Object?> get props => [commentId, isProject, model];
}

class DeleteCommentAttachment extends CommentsEvent {
  final bool isProject;
  final int commentId;

  const DeleteCommentAttachment(this.commentId, this.isProject);

  @override
  List<Object?> get props => [commentId, isProject];
}

class UpdateComment extends CommentsEvent {
  final String commentId;
  final String content;
  final String? model;
  final bool isProject;
  final List<File> media;

  const UpdateComment({
    required this.commentId,
    required this.content,
    required this.isProject,
    required this.media,
    this.model,
  });

  @override
  List<Object?> get props => [commentId, content, media, model, isProject];
}
