import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../api_helper/api.dart';
import '../../../data/model/project/status_timeline.dart';
import '../../../data/repositories/Task/task_repo.dart';
import '../../../utils/widgets/toast_widget.dart';
import 'package:logger/logger.dart';

part 'task_status_timeline_event.dart';
part 'task_status_timeline_state.dart';

final logger = Logger();

class TaskStatusTimelineBloc
    extends Bloc<TaskStatusTimelineEvent, TaskStatusTimelineState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;

  TaskStatusTimelineBloc() : super(StatusTimelineInitial()) {
    on<TaskStatusTimelineList>(_getStatausTimelineLists);
    // on<DeleteProjectMedia>(_deleteProjectMedia);
  }
  Future<void> _getStatausTimelineLists(
    TaskStatusTimelineList event,
    Emitter<TaskStatusTimelineState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;

      emit(TaskStatusTimelineLoading());

      List<StatusTimelineModel> timeline = [];
      Map<String, dynamic> result = await TaskRepo().getTaskTimeLineStatus(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: '',
      );
      timeline = List<StatusTimelineModel>.from(
        result['data'].map(
          (projectData) => StatusTimelineModel.fromJson(projectData),
        ),
      );
      if (event.id != null) {
        _offset = 0;
      } else {
        _offset += _limit;
      }
      _hasReachedMax = timeline.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(
          TaskStatusTimelinePaginated(
            TaskTimeline: timeline,
            hasReachedMax: _hasReachedMax,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((TaskStatusTimelineError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((TaskStatusTimelineError("Error: $e")));
    }
  }
}
