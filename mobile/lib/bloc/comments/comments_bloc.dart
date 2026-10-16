import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:ibex/data/model/discussion/discussion_model.dart';
import '../../data/repositories/comments/comment_repo.dart';
import 'comments_event.dart';
import 'comments_state.dart';

import 'package:logger/logger.dart';

final logger = Logger();

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final DiscussionRepo discussionRepo;
  List<CommentModel> _currentComments = [];
  int _offset = 0;
  String parentId = "";
  String content = "";
  String parentName = "";
  bool isUpdate = false;
  int _limit = 20;
  String? _lastSearch;
  int? _currentId;
  bool _hasMore = true;
  bool _isLoading = false;
  String updateContent = "";
  String model = "";
  bool isProject = true;
  final StreamController<void> _focusController =
      StreamController<void>.broadcast();

  CommentsBloc({required this.discussionRepo}) : super(CommentInitial()) {
    on<LoadComments>(_onLoadComments);
    on<AddComment>(_onAddComment);
    on<RefreshComments>(_onRefreshComments);
    on<DeleteComment>(_onDeleteComment);
    on<DeleteCommentAttachment>(_onDeleteCommentAttachment);
    on<UpdateComment>(_onUpdateComment);
    on<FocusCommentTextField>(_onFocusCommentTextField);
    on<EditComment>(_onEditComment);
  }
  Future<void> _onEditComment(
    EditComment event,
    Emitter<CommentsState> emit,
  ) async {
    isUpdate = true;
    content = event.content;
    parentName = event.parentName;

    emit(
      CommentEditState(
        comments: List<CommentModel>.from(_currentComments),
        content: content,
        parentName: parentName,
      ),
    );
  }

  Future<void> _onFocusCommentTextField(
    FocusCommentTextField event,
    Emitter<CommentsState> emit,
  ) async {
    if (kDebugMode) {
      logger.i("FocusCommentTextField triggered at ${DateTime.now()}");
    }
    _focusController.add(null); // Notify FloatingActionBar to focus
    if (kDebugMode) {
      logger.i("Focus event emitted to focusStream");
    }
  }

  Future<void> _onUpdateComment(
    UpdateComment event,
    Emitter<CommentsState> emit,
  ) async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;

    // Keep current state visible during update
    emit(CommentLoaded(_currentComments));
    if (kDebugMode) {
      logger.i("Updating comment with ID: ${event.commentId}");
    }
    try {
      await discussionRepo.updateDiscussion(
        DiscussionId: int.parse(event.commentId),
        content: event.content,
        isProject: event.isProject,
      );

      // Silently reload comments without changing UI
      final response = await discussionRepo.DiscussionList(
        isProject: event.isProject,
        id: _currentId ?? 1,
        limit: _limit,
        offset: 0,
        search: _lastSearch,
      );
      final commentJsonList = response['data'] as List<dynamic>?;
      if (commentJsonList == null || commentJsonList.isEmpty) {
        _currentComments = [];
        _hasMore = false;
        emit(CommentLoaded([]));
        return;
      }
      final comments = commentJsonList
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _currentComments = comments;
      _offset = comments.length;
      _hasMore = comments.length >= _limit;
      emit(CommentLoaded(_currentComments));
    } catch (e) {
      emit(CommentError('Failed to update comment: ${e.toString()}'));
    } finally {
      _isLoading = false;
    }
    _focusController.add(null);
  }

  Future<void> _onDeleteComment(
    DeleteComment event,
    Emitter<CommentsState> emit,
  ) async {
    if (_isLoading) {
      if (kDebugMode) {
        logger.i('Skipping DeleteComment: already loading');
      }
      return;
    }
    _isLoading = true;

    // Optimistically update the comments list
    List<CommentModel> updatedComments = List.from(_currentComments);
    bool isChildComment = false;
    if (kDebugMode) {
      logger.i("Initial isChildComment value: $isChildComment");
    }
    // Update the comments list by removing the comment (top-level or child)
    updatedComments = updatedComments
        .map((comment) {
          if (comment.id == event.commentId.toString()) {
            return null; // Remove top-level comment
          }
          if (comment.children != null && comment.children!.isNotEmpty) {
            // Check if the commentId matches a child comment
            final updatedChildren = comment.children!
                .where((child) => child.id != event.commentId.toString())
                .toList();
            if (updatedChildren.length < comment.children!.length) {
              isChildComment = true; // Mark as child comment deletion
              return comment.copyWith(children: updatedChildren);
            }
          }
          return comment;
        })
        .where((comment) => comment != null)
        .cast<CommentModel>()
        .toList();

    // Emit the optimistic update
    emit(CommentLoaded(updatedComments));

    try {
      final result = await discussionRepo.deleteComment(
        CommentId: event.commentId.toString(),
        token: true,
        isProject: event.isProject,
        model: event.model,
      );

      if (!result.containsKey('error')) {
        _currentComments = updatedComments;
        _offset = _currentComments.length;
        emit(CommentDeleteSuccess());
        emit(CommentLoaded(List<CommentModel>.from(_currentComments)));

        // Optionally, fetch the latest comments from the server to ensure consistency
        final response = await discussionRepo.DiscussionList(
          id: _currentId ?? 1,
          limit: _limit,
          offset: 0,
          search: _lastSearch,
          isProject: event.isProject,
          model: event.model,
          work_order: event.work_order,
        );

        final commentJsonList = response['data'] as List<dynamic>?;
        if (commentJsonList == null || commentJsonList.isEmpty) {
          _currentComments = [];
          _hasMore = false;
          emit(CommentLoaded([]));
        } else {
          _currentComments = commentJsonList
              .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _offset = _currentComments.length;
          _hasMore = _currentComments.length >= _limit;
          emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
        }
      } else {
        // Revert on failure
        emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
        emit(CommentDeleteError(result['message'] as String));
      }
    } catch (e) {
      // Revert on error
      emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
      emit(CommentDeleteError('Failed to delete comment: ${e.toString()}'));
      logger.e('Failed to delete comment: ${e.toString()}');
    } finally {
      _isLoading = false;
    }
  }

  // Future<void> _onDeleteComment(DeleteComment event, Emitter<CommentsState> emit) async {
  //   if (_isLoading) {
  //     print('Skipping DeleteComment: already loading');
  //     return;
  //   }
  //   _isLoading = true;
  //
  //   // Optimistically remove comment from UI
  //   final updatedComments = _currentComments.where((comment) =>
  //   comment.id != event.commentId.toString()).toList();
  //   emit(CommentLoaded(updatedComments));
  //
  //   try {
  //     final result = await discussionRepo.deleteComment(
  //       CommentId: event.commentId.toString(),
  //       token: true,
  //         isProject: event.isProject
  //     );
  //     if (!result.containsKey('error')) {
  //       _currentComments = updatedComments;
  //       _offset = updatedComments.length;
  //       emit(CommentDeleteSuccess());
  //       emit(CommentLoaded(_currentComments));
  //     } else {
  //       // Revert on failure
  //       emit(CommentLoaded(_currentComments));
  //       emit(CommentDeleteError(result['message'] as String));
  //     }
  //   } catch (e) {
  //     // Revert on error
  //     emit(CommentLoaded(_currentComments));
  //     emit(CommentDeleteError('Failed to delete comment: ${e.toString()}'));
  //   } finally {
  //     _isLoading = false;
  //   }
  // }
  Future<void> _onDeleteCommentAttachment(
    DeleteCommentAttachment event,
    Emitter<CommentsState> emit,
  ) async {
    if (_isLoading) {
      if (kDebugMode) {
        logger.i('Skipping DeleteCommentAttachment: already loading');
      }
      return;
    }
    _isLoading = true;

    // Optimistically update the comment's attachments in the UI
    final updatedComments = _currentComments.map((comment) {
      if (comment.id == event.commentId.toString()) {
        final updatedAttachments = comment.attachments
                ?.where((attachment) => attachment.id != event.commentId)
                .toList() ??
            [];
        return comment.copyWith(attachments: updatedAttachments);
      }
      return comment;
    }).toList();

    emit(CommentLoaded(updatedComments));

    try {
      final result = await discussionRepo.deleteCommentAttachment(
        id: event.commentId.toString(), // Use attachment ID
        token: true,
        isProject: event.isProject,
      );

      if (!result.containsKey('error')) {
        // Fetch the updated comment list from the server
        final response = await discussionRepo.DiscussionList(
          id: _currentId ?? 1,
          limit: _limit,
          offset: 0,
          search: _lastSearch,
          isProject: event.isProject,
        );

        final commentJsonList = response['data'] as List<dynamic>?;
        if (commentJsonList == null || commentJsonList.isEmpty) {
          _currentComments = [];
          _hasMore = false;
          emit(CommentLoaded([]));
          emit(CommentDeleteSuccess());
          return;
        }

        // Update _currentComments with the fresh list
        _currentComments = commentJsonList
            .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _offset = _currentComments.length;
        _hasMore = _currentComments.length >= _limit;

        emit(CommentDeleteSuccess());
        emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
      } else {
        // Revert on failure
        emit(CommentLoaded(_currentComments));
        emit(CommentDeleteError(result['message'] as String));
      }
    } catch (e) {
      // Revert on error
      emit(CommentLoaded(_currentComments));
      emit(CommentDeleteError('Failed to delete attachment: ${e.toString()}'));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _onLoadComments(
    LoadComments event,
    Emitter<CommentsState> emit,
  ) async {
    if (_isLoading) {
      return;
    }

    // Reset if ID/search changes or refresh (offset = 0)
    if (event.id != _currentId ||
        event.search != _lastSearch ||
        event.offset == 0) {
      _currentId = event.id;
      _lastSearch = event.search;
      _offset = 0;
      _hasMore = true;
      _currentComments.clear();
    }

    if (!_hasMore) {
      return;
    }

    _isLoading = true;

    // ✅ Emit only if we already have some comments (pagination case)
    if (_currentComments.isNotEmpty) {
      emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
    }

    try {
      final response = await discussionRepo.DiscussionList(
        id: event.id,
        limit: event.limit,
        offset: _offset,
        search: event.search,
        isProject: event.isProject,
        model: event.model,
        work_order: event.work_order,
      );

      final commentJsonList = response['data'] as List<dynamic>?;

      if (commentJsonList == null || commentJsonList.isEmpty) {
        _hasMore = false;
        emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
        return;
      }

      final newComments = commentJsonList
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList();

      _currentComments.addAll(newComments);
      _offset = _currentComments.length;
      _hasMore = newComments.length >= event.limit;

      emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
    } catch (e) {
      logger.e('Error: $e');
      emit(CommentError('Failed to load comments: $e'));
    } finally {
      _isLoading = false;
    }
  }

  // Future<void> _onLoadComments(LoadComments event, Emitter<CommentsState> emit,) async {
  //   if (_isLoading) {
  //     logger.i('Skipping LoadComments: already loading');
  //     return;
  //   }
  //
  //   // Reset if ID/search changes or refresh (offset = 0)
  //   if (event.id != _currentId || event.search != _lastSearch || event.offset == 0) {
  //     logger.i('Refreshing comments...');
  //     _currentId = event.id;
  //     _lastSearch = event.search;
  //     _offset = 0;
  //     _hasMore = true;
  //     _currentComments.clear();
  //   }
  //
  //   if (!_hasMore) {
  //     logger.i('No more comments to load');
  //     return;
  //   }
  //
  //   _isLoading = true;
  //
  //   // Emit current list without shimmer (always show existing comments)
  //   emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
  //
  //   try {
  //     final response = await discussionRepo.DiscussionList(
  //       id: event.id,
  //       limit: event.limit,
  //       offset: _offset,
  //       search: event.search,
  //     );
  //
  //     final commentJsonList = response['data'] as List<dynamic>?;
  //
  //     if (commentJsonList == null || commentJsonList.isEmpty) {
  //       _hasMore = false;
  //       emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
  //       return;
  //     }
  //
  //     final newComments = commentJsonList
  //         .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
  //         .toList();
  //
  //     logger.i('Fetched ${newComments.length} comments');
  //
  //     _currentComments.addAll(newComments);
  //     _offset = _currentComments.length;
  //     _hasMore = newComments.length >= event.limit;
  //
  //     emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
  //   } catch (e) {
  //     logger.e('Error: $e');
  //     emit(CommentError('Failed to load comments: $e'));
  //   } finally {
  //     _isLoading = false;
  //   }
  // }

  // Future<void> _onLoadComments(LoadComments event, Emitter<CommentsState> emit) async {
  //   if (_isLoading) {
  //     logger.i('Skipping LoadComments: already loading');
  //     return;
  //   }
  //
  //   // Reset state for new ID, search, or when explicitly requesting offset 0
  //   if (event.id != _currentId || event.search != _lastSearch || event.offset == 0) {
  //     if (event.id != _currentId || event.search != _lastSearch) {
  //       _currentComments.clear();
  //     }
  //     _offset = 0;
  //     _hasMore = true;
  //     _currentId = event.id;
  //     _lastSearch = event.search;
  //   }
  //
  //   if (!_hasMore) {
  //     logger.i('No more comments to load');
  //     return;
  //   }
  //
  //   _isLoading = true;
  //   if (_offset == 0 && _currentComments.isEmpty) {
  //     logger.i('Emitting CommentLoading for initial load');
  //     emit(CommentLoading(currentComments: []));
  //   } else if (_offset > 0) {
  //     logger.i('Emitting CommentLoadMoreLoading with ${_currentComments.length} comments');
  //     emit(CommentLoadMoreLoading(_currentComments));
  //   }
  //   // If _currentComments is not empty and offset is 0, don't emit loading state
  //
  //   try {
  //     logger.i('Calling DiscussionList with id: ${event.id}, offset: $_offset, limit: ${event.limit}');
  //     final response = await discussionRepo.DiscussionList(
  //       id: event.id,
  //       limit: event.limit,
  //       offset: _offset,
  //       search: event.search,
  //     );
  //
  //     final commentJsonList = response['data'] as List<dynamic>?;
  //     if (commentJsonList == null || commentJsonList.isEmpty) {
  //       logger.i('No comments found');
  //       if (_offset == 0) {
  //         _currentComments = [];
  //       }
  //       _hasMore = false;
  //       emit(CommentLoaded(_currentComments));
  //       return;
  //     }
  //
  //     final newComments = commentJsonList
  //         .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
  //         .toList();
  //
  //     logger.i('Parsed ${newComments.length} new comments:');
  //     for (var comment in newComments) {
  //       logger.i('ID: ${comment.id}, Content: ${comment.content}, By: ${comment.commenter?.firstName}');
  //     }
  //
  //     if (_offset == 0) {
  //       _currentComments = newComments;
  //     } else {
  //       _currentComments.addAll(newComments);
  //     }
  //     _offset += newComments.length;
  //     _hasMore = newComments.length >= event.limit;
  //     logger.i('Updated _currentComments: ${_currentComments.length} comments');
  //     emit(CommentLoaded(_currentComments));
  //   } catch (e) {
  //     logger.e('Error loading comments: ${e.toString()}');
  //     emit(CommentError('Failed to load comments: ${e.toString()}'));
  //   } finally {
  //     _isLoading = false;
  //   }
  // }

  Future<void> _onAddComment(
    AddComment event,
    Emitter<CommentsState> emit,
  ) async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      log("Starting createDiscussion call at ${DateTime.now()}");
      final response = await discussionRepo.createDiscussion(
        modelType: event.modelType,
        work_order: event.work_order,
        model: event.model,
        modelId: event.modelId,
        content: event.content,
        parentId: event.parentId,
        media: event.media,
        isProject: event.isProject,
      );
      // print("createDiscussion Response : $response");

      // Refresh comments list after successful creation
      if (response.containsKey('data')) {
        // Add a small delay to ensure backend has processed
        await Future.delayed(Duration(milliseconds: 500));

        final freshResponse = await discussionRepo.DiscussionList(
          id: event.modelId,
          limit: _limit,
          offset: 0,
          search: _lastSearch,
          isProject: event.isProject,
          model: event.model,
          work_order: event.work_order,
        );

        final commentJsonList = freshResponse['data'] as List<dynamic>?;
        if (commentJsonList != null) {
          _currentComments = commentJsonList
              .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _offset = _currentComments.length;
          _hasMore = _currentComments.length >= _limit;

          emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
        }
      } else if (response.containsKey('error')) {
        emit(CommentError('Failed to add comment: ${response['message']}'));
      }
      // else {
      //   // Remove optimistic comment on failure
      //   _currentComments.removeWhere((comment) => comment.isTemporary);
      //   emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
      //   emit(CommentError('Failed to add comment: ${response['message']}'));
      //   print("Emitted CommentError at ${DateTime.now()} - Remaining IDs: ${_currentComments.map((comment) => comment.id).join(', ')}");
      // }
    } catch (e) {
      // Remove optimistic comment on error
      _currentComments.removeWhere((comment) => comment.isTemporary);
      emit(CommentLoaded(List<CommentModel>.from(_currentComments)));
      emit(CommentError('Failed to add comment: ${e.toString()}'));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _onRefreshComments(
    RefreshComments event,
    Emitter<CommentsState> emit,
  ) async {
    if (_isLoading) {
      if (kDebugMode) {
        logger.i('Skipping RefreshComments: already loading');
      }
      return;
    }
    // logger.i('Refreshing comments for id: ${event.id}, search: ${event.search}');

    emit(CommentLoading(currentComments: _currentComments));
    _offset = 0;
    _hasMore = true;
    _currentId = event.id;
    _lastSearch = event.search;

    add(
      LoadComments(
        id: event.id,
        limit: _limit,
        offset: 0,
        isProject: event.isProject,
      ),
    );
  }
  // Future<void> _onRefreshComments(RefreshComments event, Emitter<CommentsState> emit) async {
  //   if (_isLoading) {
  //     return;
  //   }
  //
  //   // Keep current state visible during refresh
  //   emit(CommentLoaded(_currentComments));
  //
  //   _offset = 0;
  //   _hasMore = true;
  //   _currentId = event.id;
  //   _lastSearch = event.search;
  //
  //   add(LoadComments(id: event.id, limit: _limit, offset: 0, isProject: event.isProject));
  // }

  void loadMoreComments(isProject) {
    if (_currentId != null && !_isLoading && _hasMore) {
      if (kDebugMode) {
        logger.i('Loading more comments at offset: $_offset');
      }
      add(
        LoadComments(
          id: _currentId!,
          limit: _limit,
          offset: _offset,
          isProject: isProject,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _focusController.close();
    return super.close();
  }
}
