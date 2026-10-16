import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/inspection_discussion/inspection_part/inspection_part_event.dart';
import 'package:ibex/bloc/inspection_discussion/inspection_part/inspection_part_state.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';

import '../../../api_helper/api.dart';
import '../../../data/model/inspection/part.dart';
import '../../../data/repositories/inspection/inspection_repo.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionPartBloc
    extends Bloc<InspectionPartEvent, InspectionPartState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;
  InspectionPartBloc() : super(InspectionPartInitial()) {
    on<InspectionPartList>(_getPartLists);
    on<InspectionPartLoadMore>(_onLoadMoreInspectionPart);
    on<DeleteInspectionPart>(_onDeleteInspectionPart);
    on<SearchInspectionPart>(_onSearchInspectionPart);
    on<InspectionPartCreated>(_onCreatePartInspection);
    on<UpdatePartInspection>(_onUpdateInspectionPart);
  }

  Future<void> _getPartLists(
    InspectionPartList event,
    Emitter<InspectionPartState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(InspectionPartLoading());

      List<InspectionsPart> workpart = [];

      Map<String, dynamic> result = await InspectionRepo().getInspectionsPart(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: '',
        dateBetweenFrom: event.dateBetweenFrom,
        dateBetweenTo: event.dateBetweenTo,
        startDateFrom: event.startDateFrom,
        startDateTo: event.startDateTo,
        endDateFrom: event.endDateFrom,
        endDateTo: event.endDateTo,
        status: event.status,
      );

      workpart = List<InspectionsPart>.from(
        result['data'].map((workData) => InspectionsPart.fromJson(workData)),
      );

      int? totalCount;

      if (result['meta'] != null) {
        totalCount =
            result['meta']['filter_count'] ?? result['meta']['total_count'];
      }

      totalCount ??= workpart.length;
      if (workpart.isNotEmpty) {
        _offset +=
            workpart.length; // Update offset based on actual fetched data
      }

      _hasReachedMax = workpart.length < _limit || (_offset >= totalCount);

      if (!result.containsKey('error')) {
        emit(
          InspectionPartPaginated(
            InspectionPart: workpart,
            hasReachedMax: _hasReachedMax,
          ),
        );
      } else {
        emit(InspectionPartError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e("Error: $e");
      emit(InspectionPartError("Error: $e"));
    }
  }

  void _onDeleteInspectionPart(
    DeleteInspectionPart event,
    Emitter<InspectionPartState> emit,
  ) async {
    // if (emit is NotesSuccess) {
    final work = event.workPartId;

    try {
      Map<String, dynamic> result =
          await InspectionRepo().getDeleteInspectionPart(
        id: work.toString(),
        token: true,
      );
      if (result['data']['error'] == false) {
        emit(InspectionPartDeleteSuccess());
      }
      if (result['data']['error'] == true) {
        emit((InspectionPartDeleteError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(InspectionPartError(e.toString()));
    }
    // }
  }

  Future<void> _onCreatePartInspection(
    InspectionPartCreated event,
    Emitter<InspectionPartState> emit,
  ) async {
    try {
      List<InspectionsPart> work = [];

      emit(InspectionPartCreateLoading());
      var result = await InspectionRepo().createInspectionPart(
        id: event.projId,
        title: event.title,
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
        desc: event.desc,
        cost: event.cost,
      );
      if (!result.containsKey('error')) {
        emit(InspectionPartCreateSuccess(work));
      }
      if (result.containsKey('errors')) {
        emit(InspectionPartCreateError(result['message']));
        flutterToastCustom(msg: result['message']);
        // add(InspectionDashBoardList());
      }
    } on ApiException catch (e) {
      logger.e("Error: $e");

      emit((InspectionPartError("Error: $e")));
    }
  }

  // void _selectInspection(SelectedInspection event, Emitter<InspectionState> emit) {
  //   if (state is InspectionSuccess) {
  //     final currentState = state as InspectionSuccess;
  //     emit(InspectionSuccess(currentState.work, event.selectedIndex,
  //         event.selectedTitle, false));
  //   }

  void _onUpdateInspectionPart(
    UpdatePartInspection event,
    Emitter<InspectionPartState> emit,
  ) async {
    if (state is InspectionPartPaginated) {
      List<InspectionsPart> workpart = [];
      final id = event.id;
      final workId = event.workId;
      final title = event.title;
      final status = event.status;
      final startDate = event.startDate;
      final endDate = event.endDate;
      final desc = event.desc;
      final cost = event.cost;
      final progress = event.progress;

      emit(InspectionPartEditLoading());
      // Try to update the task via the repository
      try {
        Map<String, dynamic> updatedInspection =
            await InspectionRepo().updateInspectionPart(
          id: id,
          projectId: workId,
          title: title,
          status: status,
          startDate: startDate,
          endDate: endDate,
          desc: desc,
          cost: cost,
          progress: progress,
        );
        // work = List<InspectionModel>.from(updatedInspection['data']
        //     .map((workData) => InspectionModel.fromJson(workData)));
        if (updatedInspection['error'] == false) {
          emit(InspectionPartEditSuccess(workpart));
          // add(InspectionDashBoardList());
          // add(InspectionList());
        }
        if (updatedInspection['error'] == true) {
          flutterToastCustom(msg: updatedInspection['message']);
          // add(InspectionDashBoardList());
          emit(InspectionPartEditError(updatedInspection['message']));
        }
      } catch (e) {
        logger.e('Error while updating Task: $e');
      }
    }
  }

  Future<void> _onSearchInspectionPart(
    SearchInspectionPart event,
    Emitter<InspectionPartState> emit,
  ) async {
    try {
      List<InspectionsPart> workpart = [];
      _offset = 0;
      emit(InspectionPartLoading());
      var result = await InspectionRepo().getInspectionsPart(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: event.searchQuery,
        dateBetweenFrom: event.dateBetweenFrom,
        dateBetweenTo: event.dateBetweenTo,
        startDateFrom: event.startDateFrom,
        startDateTo: event.startDateTo,
        endDateFrom: event.endDateFrom,
        endDateTo: event.endDateTo,
      );

      if (!result.containsKey('error')) {
        workpart = List<InspectionsPart>.from(
          result['data'].map((workData) => InspectionsPart.fromJson(workData)),
        );
        bool hasReachedMax = workpart.length < _limit;
        emit(
          InspectionPartPaginated(
            InspectionPart: workpart,
            hasReachedMax: hasReachedMax,
          ),
        );
      } else if (result.containsKey('errors')) {
        emit(InspectionPartError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e("Error: $e");
      emit(InspectionPartError("Error: $e"));
    }
  }

  Future<void> _onLoadMoreInspectionPart(
    InspectionPartLoadMore event,
    Emitter<InspectionPartState> emit,
  ) async {
    if (state is InspectionPartPaginated && !_hasReachedMax) {
      try {
        final currentState = state as InspectionPartPaginated;
        final updatedInspection = List<InspectionsPart>.from(
          currentState.InspectionPart,
        );

        // Fetch additional Inspections from the repository
        Map<String, dynamic> result = await InspectionRepo().getInspectionsPart(
          id: event.id,
          limit: _limit,
          offset: _offset,
          search: event.searchQuery,
          dateBetweenFrom: event.dateBetweenFrom,
          dateBetweenTo: event.dateBetweenTo,
          startDateFrom: event.startDateFrom,
          startDateTo: event.startDateTo,
          endDateFrom: event.endDateFrom,
          endDateTo: event.endDateTo,
        );
        final additional = List<InspectionsPart>.from(
          result['data'].map((workData) => InspectionsPart.fromJson(workData)),
        );

        if (additional.isEmpty) {
          _hasReachedMax = true;
        } else {
          _offset += _limit; // Increment the offset consistently
          updatedInspection.addAll(additional);
        }

        if (!result.containsKey('error')) {
          emit(
            InspectionPartPaginated(
              InspectionPart: updatedInspection,
              hasReachedMax: _hasReachedMax,
            ),
          );
        } else {
          emit(InspectionPartError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } on ApiException catch (e) {
        emit(InspectionPartError("Error: $e"));
      }
    }
  }
}
