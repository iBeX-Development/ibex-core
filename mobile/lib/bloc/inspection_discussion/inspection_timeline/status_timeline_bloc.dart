import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../api_helper/api.dart';
import '../../../data/model/inspection/status_timeline.dart';
import '../../../data/repositories/inspection/inspection_repo.dart';
import '../../../utils/widgets/toast_widget.dart';
import 'package:logger/logger.dart';

part 'status_timeline_event.dart';
part 'status_timeline_state.dart';

final logger = Logger();

class InspectionStatusTimelineBloc
    extends Bloc<StatusTimelineEvent, StatusTimelineState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;

  InspectionStatusTimelineBloc() : super(StatusTimelineInitial()) {
    on<StatusTimelineList>(_getStatausTimelineLists);
    // on<DeleteInspectionMedia>(_deleteInspectionMedia);
  }
  Future<void> _getStatausTimelineLists(
      StatusTimelineList event, Emitter<StatusTimelineState> emit) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;

      emit(InspectionStatusTimelineLoading());

      List<StatusTimelineModel> timeline = [];
      Map<String, dynamic> result =
          await InspectionRepo().getInspectionTimeLineStatus(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: '',
      );
      timeline = List<StatusTimelineModel>.from(result['data']
          .map((projectData) => StatusTimelineModel.fromJson(projectData)));
      if (event.id != null) {
        _offset = 0;
      } else {
        _offset += _limit;
      }
      _hasReachedMax = timeline.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(InspectionStatusTimelinePaginated(
          InspectionTimeline: timeline,
          hasReachedMax: _hasReachedMax,
        ));
      }
      if (result.containsKey('errors')) {
        emit((InspectionStatusTimelineError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e("Error: $e");
      emit((InspectionStatusTimelineError("Error: $e")));
    }
  }
}
