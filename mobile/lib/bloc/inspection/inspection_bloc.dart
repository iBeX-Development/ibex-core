import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/inspection/inspection_event.dart';
import 'package:ibex/bloc/inspection/inspection_state.dart';
import 'package:ibex/data/model/inspection/inspection.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';
import '../../data/repositories/inspection/inspection_repo.dart';
import '../../api_helper/api.dart';
import '../../../data/localStorage/hive.dart';
import '../../utils/user_id_mapper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionBloc extends Bloc<InspectionEvent, InspectionState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 25;
  int totalCount = 0;
  List<Object> woStatusData = [];
  List<int>? ids;

  bool _hasReachedMax = false;
  InspectionBloc() : super(InspectionInitial()) {
    _initializeStatusData();

    on<InspectionDashBoardList>(_getInspectionLists);
    on<InspectionDashBoardFavList>(_getInspectionFavLists);
    on<SelectedInspection>(_onSelectInspection);
    on<InspectionLoadMore>(_onLoadMoreInspection);
    on<DeleteInspection>(_onDeleteInspection);
    on<SearchInspection>(_onSearchInspection);
    on<InspectionCreated>(_onCreateInspection);
    on<UpdateInspection>(_onUpdateInspection);
    on<InspectionMindMap>(_onInspectionMindMap);
  }

  Future<void> _initializeStatusData() async {
    woStatusData = await HiveStorage.getAllStatusData();
  }

  Future<void> _onInspectionMindMap(
    InspectionMindMap event,
    Emitter<InspectionState> emit,
  ) async {
    try {
      //
      emit(InspectionMapLoading());

      Map<String, dynamic> result = await InspectionRepo().getInspectionMindMap(
        id: event.id,
      );

      if (result['original']['error'] == false) {
        emit(InspectionMindMapSuccess(result));
      }
      if (result.containsKey('errors')) {
        emit((InspectionError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e('API Exception: $e');
      emit((InspectionError("Error: $e")));
    }
  }

  Future<void> _getInspectionLists(
    InspectionDashBoardList event,
    Emitter<InspectionState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(InspectionLoading());

      // ✅ Reload status data from Hive before parsing
      woStatusData = await HiveStorage.getAllStatusData() ?? [];
      // {"user":{"_in":["7e91d147-dbbd-4211-8bbc-a83c51fdfaa3"]}}

      int myIntId = await HiveStorage.getUserId();
      String myUuid = UserIdMapper().convertIntsToUuids([myIntId]).first;

      Map<String, dynamic> myInspectionsIds =
          await InspectionRepo().getInspectionsUsers(
        userId: myIntId,
        fields: 'id, work_order.id',
      );

      // ✅ Extract IDs from response data
      if (myInspectionsIds['data'] != null) {
        ids = (myInspectionsIds['data'] as List)
            .map((item) => item['work_order']['id'] as int)
            .toList();
        if (kDebugMode) {
          logger.i(' 🔹 Extracted IDs: $ids ');
        }
      }

      List<InspectionModel> notification = [];
      Map<String, dynamic> result = await InspectionRepo().getInspections(
        ids: ids,
        id: event.id,
        isFav: event.isFav,
        limit: _limit,
        offset: _offset,
        active: '1',
        location: event.location,
        woStatus: event.woStatus,
        workType: event.workType,
        createType: event.createType,
        actionStatus: event.actionStatus, // ✅ Pass action_status filter
        search: '',
        userId: event.userId,
        assetId: event.assetId,
        statusId: event.statusId,
        priorityId: event.priorityId,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      totalCount = result['meta']['filter_count'] != null
          ? result['meta']['filter_count'] as int
          : 0;

      notification = List<InspectionModel>.from(
        result['data'].map(
            (workData) => InspectionModel.fromJson(workData, woStatusData)),
      );
      if (event.id != null) {
        _offset = 0;
      } else {
        _offset += _limit;
        _hasReachedMax = notification.length >= (result['data'].length ?? 1);
      }

      if (!result.containsKey('error') || notification.length > 0) {
        emit(InspectionPaginated(
            work: notification,
            hasReachedMax: _hasReachedMax,
            totalCount: totalCount));
      }
      if (result.containsKey('errors')) {
        emit((InspectionError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e('API Exception: $e');
      emit((InspectionError("Error: $e")));
    }
  }

  Future<void> _getInspectionFavLists(
    InspectionDashBoardFavList event,
    Emitter<InspectionState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      emit(InspectionLoading());
      List<InspectionModel> fav = [];
      Map<String, dynamic> result = await InspectionRepo().getInspectionsFav(
        isFav: event.isFav,
        limit: _limit,
        offset: _offset,
        search: '',
      );
      fav = List<InspectionModel>.from(
        result['data'].map(
            (workData) => InspectionModel.fromJson(workData, woStatusData)),
      );
      _offset += _limit;
      _hasReachedMax = fav.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(InspectionFavPaginated(work: fav, hasReachedMax: _hasReachedMax));
      }
      if (result.containsKey('errors')) {
        emit((InspectionError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e('API Exception: $e');
      emit((InspectionError("Error: $e")));
    }
  }

  void _onDeleteInspection(
      DeleteInspection event, Emitter<InspectionState> emit) async {
    // if (emit is NotesSuccess) {
    final work = event.workId;

    try {
      Map<String, dynamic> result = await InspectionRepo().getDeleteInspection(
        id: work.toString(),
        token: true,
      );
      if (result['data']['error'] == false) {
        emit(InspectionDeleteSuccess());
      }
      if (result['data']['error'] == true) {
        emit((InspectionDeleteError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(InspectionError(e.toString()));
    }
    // }
  }

  Future<void> _onCreateInspection(
      InspectionCreated event, Emitter<InspectionState> emit) async {
    try {
      List<InspectionModel> work = [];

      emit(InspectionCreateLoading());
      var result = await InspectionRepo().createInspection(
        title: event.title,
        statusId: event.statusId ?? 1,
        userId: event.userId,
        actionStatus: event.actionStatus,
        workType: event.workType,
        requestUser: event.userIdString,
        locationId: event.locationId,
        desc: event.desc ?? '',
        note: event.note ?? '',
        priorityId: event.priorityId ?? 1,
        startDate: event.startDate ?? '',
        endDate: event.endDate ?? '',
        createdType: event.createdType ?? 'open', // ✅ Default утга нэмэх
        assetId: event.assetId != null ? event.assetId! : null,
        taskAccess: event.taskAccess ?? '',
        enable: event.enable ?? 0,
        budget: event.budget ?? '',
        customFieldValues: event.customFieldValues ?? null,
      );
      if (result.containsKey('data') && result['data'] != null) {
        // ✅ Parse created work data
        InspectionModel? createdInspection;
        int? createdInspectionId;

        if (result['data'] is List && (result['data'] as List).isNotEmpty) {
          var workData = result['data'][0];
          createdInspection = InspectionModel.fromJson(workData, []);
          createdInspectionId = workData['id'];
        } else if (result['data'] is Map) {
          createdInspection = InspectionModel.fromJson(result['data'], []);
          createdInspectionId = result['data']['id'];
        }

        emit(InspectionCreateSuccess(
          createdInspection: createdInspection,
          createdInspectionId: createdInspectionId,
        ));
      } else if (result.containsKey('errors')) {
        String errorMessage =
            result['errors'][0]['message'] ?? 'Create work failed';
        logger.e("❌ Create work failed: $errorMessage");
        emit(InspectionCreateError(errorMessage));
      } else {
        logger.e("❌ Unexpected response format");
        emit(InspectionCreateError('Unexpected response format'));
      }
    } on ApiException catch (e) {
      logger.e('API Exception: $e');
      emit((InspectionError("Error: $e")));
    }
  }

  void _onSelectInspection(
      SelectedInspection event, Emitter<InspectionState> emit) {
    if (state is InspectionSuccess) {
      final currentState = state as InspectionSuccess;
      emit(
        InspectionSuccess(
          currentState.work,
          event.selectedIndex,
          event.selectedTitle,
          false,
        ),
      );
    }
  }

  void _onUpdateInspection(
      UpdateInspection event, Emitter<InspectionState> emit) async {
    if (state is InspectionPaginated) {
      List<InspectionModel> work = [];
      final id = event.id;
      final title = event.title;
      final statusId = event.statusId;
      final priorityId = event.priorityId;
      final startDate = event.startDate;
      final endDate = event.endDate;
      final desc = event.desc;
      final note = event.note;
      final taskAccess = event.taskAccess;
      final budget = event.budget;
      final userId = event.userId;
      final assetId = event.assetId;
      final clientId = event.clientId;
      final tagId = event.tagId;
      final canClientDiscuss = event.clientCanDiscuss;
      final isEnabled = event.enable;
      final customFieldValues =
          event.customFieldValues; // Access from the event

      // Get custom field values
      // final fieldValues = getFieldValues(); // From your submitToAPI function

      emit(InspectionEditLoading());
      try {
        Map<String, dynamic> updatedInspection =
            await InspectionRepo().updateInspection(
          id: id,
          title: title,
          statusId: statusId ?? 0,
          priorityId: priorityId ?? 0,
          startDate: startDate ?? '',
          endDate: endDate ?? '',
          desc: desc ?? '',
          note: note ?? '',
          userId: userId ?? [],
          assetId: assetId ?? [],
          taskAccess: taskAccess ?? '',
          budget: budget ?? '',
          clientId: clientId ?? [],
          canClientDiscuss: canClientDiscuss!,
          enable: isEnabled!,
          tagId: tagId ?? [],
          customFieldValues: customFieldValues, // Pass as a named parameter
        );

        if (!updatedInspection.containsKey('error')) {
          emit(InspectionEditSuccess(work));
          add(InspectionDashBoardList());
        } else if (updatedInspection.containsKey('error')) {
          flutterToastCustom(msg: updatedInspection['message']);
          add(InspectionDashBoardList());
          emit(InspectionEditError(updatedInspection['message']));
        }
      } catch (e) {
        logger.e('Error while updating Task: $e');
      }
    }
  }

  Future<void> _onSearchInspection(
      SearchInspection event, Emitter<InspectionState> emit) async {
    try {
      List<InspectionModel> works = [];
      _offset = 0;
      emit(InspectionLoading());
      var result = await InspectionRepo().getInspections(
        limit: _limit,
        offset: _offset,
        search: event.searchQuery,
        clientId: event.clientId,
      );

      if (!result.containsKey('error')) {
        works = List<InspectionModel>.from(
          result['data'].map(
              (workData) => InspectionModel.fromJson(workData, woStatusData)),
        );
        bool hasReachedMax = works.length < _limit;
        emit(InspectionPaginated(
            work: works, hasReachedMax: hasReachedMax, totalCount: totalCount));
      } else if (result.containsKey('errors')) {
        emit(InspectionError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e('API Exception: $e');
      emit(InspectionError("Error: $e"));
    }
  }

  Future<void> _onLoadMoreInspection(
    InspectionLoadMore event,
    Emitter<InspectionState> emit,
  ) async {
    if (state is InspectionPaginated && !_hasReachedMax) {
      try {
        final currentState = state as InspectionPaginated;
        final updatedInspection = List<InspectionModel>.from(currentState.work);

        // Fetch additional Inspections from the repository
        Map<String, dynamic> result = await InspectionRepo().getInspections(
          limit: _limit,
          offset: _offset,
          search: event.searchQuery,
          clientId: event.clientId,
          userId: event.userId,
        );
        final additional = List<InspectionModel>.from(
          result['data'].map(
              (workData) => InspectionModel.fromJson(workData, woStatusData)),
        );

        if (additional.isEmpty) {
          _hasReachedMax = true;
        } else {
          _offset += _limit; // Increment the offset consistently
          updatedInspection.addAll(additional);
        }

        if (!result.containsKey('error')) {
          totalCount = result['meta']['filter_count'] != null
              ? result['meta']['filter_count'] as int
              : 0;
          emit(InspectionPaginated(
              work: updatedInspection,
              hasReachedMax: _hasReachedMax,
              totalCount: totalCount));
        } else {
          emit(InspectionError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } on ApiException catch (e) {
        emit(InspectionError("Error: $e"));
      }
    }
  }
}
