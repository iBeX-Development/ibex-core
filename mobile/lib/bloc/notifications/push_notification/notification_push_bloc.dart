import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/data/model/notification/notification_model.dart';
import '../../../api_helper/api.dart';
import '../../../data/repositories/notification/notification_repo.dart';
import '../../../utils/widgets/toast_widget.dart';

import 'notification_push_event.dart';
import 'notification_push_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class NotificationPushBloc
    extends Bloc<NotificationsPushEvent, NotificationPushState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  int? totalUnreadCount = 0;
  bool _isLoading = false; // Add a loading flag to prevent multiple calls

  bool _hasReachedMax = false;
  NotificationPushBloc() : super(NotificationPushInitial()) {
    on<NotificationPushList>(_onAllPushNotification);
    on<UnreadPushNotificationCount>(_onUnreadPushNotificationCount);
    on<SearchPushNotification>(_onSearchPushNoti);
    on<DeletePushNotification>(onDeletePushNotifications);
    on<LoadMorePushNotification>(_onLoadMorePushNotification);
    on<MarkAsReadPushNotification>(_onMarkAsReadPushNotification);
  }
  Future<void> _onMarkAsReadPushNotification(
    MarkAsReadPushNotification event,
    Emitter<NotificationPushState> emit,
  ) async {
    try {
      emit(NotificationPushLoading());
      Map<String, dynamic> result = await NotificationRepo().markAsReadNoti(
        id: event.id,
      );

      if (!result.containsKey('error')) {
        emit(MarkAsReadNotificationPushSuccess());
        add(NotificationPushList());
        flutterToastCustom(msg: result['message']);
      }
      if (result.containsKey('errors')) {
        emit((MarkAsReadNotificationPushError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e("Error while marking notification as read: $e");
      emit((MarkAsReadNotificationPushError("Error: $e")));
    }
  }

  Future<void> _onSearchPushNoti(
    SearchPushNotification event,
    Emitter<NotificationPushState> emit,
  ) async {
    try {
      emit(NotificationPushLoading());
      if (kDebugMode) {
        logger.i("SEARCH ${event.searchQuery}");
      }

      List<NotificationModel> notes = [];

      Map<String, dynamic> result = await NotificationRepo().getNoti(
        limit: _limit,
        offset: 0,
        search: event.searchQuery,
        token: true,
        notificationType: 'push',
      );
      notes = List<NotificationModel>.from(
        result['data'].map(
          (projectData) => NotificationModel.fromJson(projectData),
        ),
      );

      bool hasReachedMax = notes.length < _limit;
      if (!result.containsKey('error')) {
        emit(
          NotificationPushPaginated(noti: notes, hasReachedMax: hasReachedMax),
        );
      }
      if (result.containsKey('errors')) {
        emit((NotificationPushError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      emit(NotificationPushError("Error: $e"));
    }
  }

  Future<void> _onAllPushNotification(
    NotificationPushList event,
    Emitter<NotificationPushState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(NotificationPushLoading());
      List<NotificationModel> notification = [];
      Map<String, dynamic> result = await NotificationRepo().getNoti(
        limit: _limit,
        offset: _offset,
        search: '',
        token: true,
        notificationType: 'push',
      );
      notification = List<NotificationModel>.from(
        result['data'].map(
          (projectData) => NotificationModel.fromJson(projectData),
        ),
      );

      _offset += _limit;
      _hasReachedMax = notification.length < _limit;

      if (!result.containsKey('error')) {
        emit(
          NotificationPushPaginated(
            noti: notification,
            hasReachedMax: _hasReachedMax,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((NotificationPushError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e("Error while fetching push notifications: $e");
      emit((NotificationPushError("Error: $e")));
    }
  }

  Future<void> _onUnreadPushNotificationCount(
    UnreadPushNotificationCount event,
    Emitter<NotificationPushState> emit,
  ) async {
    try {
      emit(NotificationPushLoading());
      Map<String, dynamic> result = await NotificationRepo().getUnreadNotiCount(
        token: true,
        notificationType: 'push',
      );
      List<NotificationModel>.from(
        result['data'].map(
          (projectData) => NotificationModel.fromJson(projectData),
        ),
      );
      totalUnreadCount = result['total'];
      if (!result.containsKey('error')) {
        emit(UnreadNotificationPush(total: totalUnreadCount!));
      }
      if (result.containsKey('errors')) {
        emit((NotificationPushError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e("Error while fetching unread push notifications count: $e");
      emit((NotificationPushError("Error: $e")));
    }
  }

  void onDeletePushNotifications(
    DeletePushNotification event,
    Emitter<NotificationPushState> emit,
  ) async {
    final noti = event.id;

    try {
      Map<String, dynamic> result = await NotificationRepo().getDeleteNoti(
        id: noti.toString(),
        token: true,
      );
      if (!result.containsKey('error')) {
        emit(PushNotificationDeleteSuccess());
        add(NotificationPushList());
        flutterToastCustom(msg: result['message']);
      }
      if (result.containsKey('errors')) {
        emit((NotificationPushError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(NotificationPushError(e.toString()));
    }
    // }
  }

  Future<void> _onLoadMorePushNotification(
    LoadMorePushNotification event,
    Emitter<NotificationPushState> emit,
  ) async {
    if (state is NotificationPushPaginated && !_hasReachedMax && !_isLoading) {
      _isLoading = true; // Prevent concurrent API calls

      try {
        final currentState = state as NotificationPushPaginated;
        final updatedNotification = List<NotificationModel>.from(
          currentState.noti,
        );
        List<NotificationModel> additional = [];
        Map<String, dynamic> result = await NotificationRepo().getNoti(
          limit: _limit,
          offset: _offset,
          search: event.searchQuery,
          notificationType: 'push',
          token: true,
        );

        additional = List<NotificationModel>.from(
          result['data'].map(
            (projectData) => NotificationModel.fromJson(projectData),
          ),
        );

        // Update the offset for the next load
        if (additional.isNotEmpty) {
          _offset += _limit; // Increment the offset by the limit
        }

        // Check if the total number of items has been reached
        if (updatedNotification.length + additional.length >= result['total']) {
          _hasReachedMax = true;
        } else {
          _hasReachedMax = false;
        }

        // Add the newly fetched Notifications to the existing list
        updatedNotification.addAll(additional);

        if (!result.containsKey('error')) {
          emit(
            NotificationPushPaginated(
              noti: updatedNotification,
              hasReachedMax: _hasReachedMax,
            ),
          );
        }

        if (result.containsKey('errors')) {
          emit((NotificationPushError(result['message'])));
          flutterToastCustom(msg: result['message']);
        }
      } on ApiException catch (e) {
        emit(NotificationPushError("Error: $e"));
      } finally {
        _isLoading =
            false; // Reset the loading flag after the API call finishes
      }
    }
  }
}
