import 'package:bloc/bloc.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';

import '../../api_helper/api.dart';
import '../../data/model/inspection/inspection.dart';
import '../../data/repositories/inspection/inspection_repo.dart';
import '../../data/localStorage/hive.dart';

import 'inspectionid_event.dart';
import 'inspectionid_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionidBloc extends Bloc<InspectionidEvent, InspectionidState> {
  List<Object> woStatusData = [];
  InspectionidBloc() : super(InspectionidInitial()) {
    _initializeStatusData();
    on<InspectionIdListId>(_getprojectListId);
  }

  Future<void> _initializeStatusData() async {
    woStatusData = await HiveStorage.getAllStatusData();
  }

  Future<void> _getprojectListId(
      InspectionIdListId event, Emitter<InspectionidState> emit) async {
    try {
      List<InspectionModel> projects = [];

      List<InspectionModel> existingprojects = [];

      if (state is InspectionidWithId) {
        var oldData = state as InspectionidWithId;
        emit(InspectionidLoading());
        existingprojects = oldData.work;
      } else {
        emit(InspectionidLoading());
      }

      Map<String, dynamic> result = await InspectionRepo().getInspections(
        id: event.id,
      );

      if (result.containsKey('errors')) {
        emit((InspectionidError(result['message'])));
        flutterToastCustom(msg: result['message']);
        return;
      }

      var data = result['data'];
      if (data is List) {
        projects = data
            .map((projectData) =>
                InspectionModel.fromJson(projectData, woStatusData))
            .toList();
      } else if (data is Map) {
        // Хэрвээ ганцхан объект ирвэл List болгож хөрвүүлнэ
        projects = [
          InspectionModel.fromJson(
              Map<String, dynamic>.from(data), woStatusData)
        ];
      } else {
        projects = [];
      }

      Map<String, dynamic> inspectionsUsers =
          await InspectionRepo().getInspectionsUsers(
        id: event.id,
      );

      if (state is InspectionidWithId) {
        bool flag = false;
        for (var i = 0; i < existingprojects.length; i++) {
          if (event.id == existingprojects[i].id) {
            existingprojects[i] = projects[0];

            flag = true;
          }
        }
        for (var i = 0; i < existingprojects.length; i++) {}
        if (!flag) {
          existingprojects.addAll(projects);
        }

        emit(InspectionidWithId(
          existingprojects,
          inspectionsUsers: inspectionsUsers['data'],
        ));
        return;
      }
      emit(InspectionidWithId(
        projects,
        inspectionsUsers: inspectionsUsers['data'],
      ));
    } on ApiException catch (e) {
      logger.e("Error: $e");
      // emit((projectError("Error: $e")));
    }
  }
}
