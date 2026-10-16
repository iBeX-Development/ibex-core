import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../api_helper/api.dart';

import 'package:ibex/bloc/inspectiontask_discussion/task_media/task_media_state.dart';
import '../../../data/model/inspectiontask/media.dart';
import '../../../data/repositories/inspectiontask/task_repo.dart';
import '../../../utils/widgets/toast_widget.dart';
import 'package:logger/logger.dart';

part 'task_media_event.dart';

final logger = Logger();

class InspectionTaskMediaBloc
    extends Bloc<InspectionTaskMediaEvent, InspectionTaskMediaState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;
  String filter = '';
  String fields = '';
  InspectionTaskMediaBloc() : super(InspectionTaskMediaInitial()) {
    on<InspectionTaskMediaList>(_getMediaLists);
    on<InspectionTaskStartDownload>(_onStartDownload);
    on<InspectionTaskSilentMediaRefresh>(_silentRefresh);
    on<InspectionTaskDeleteMedia>(_deleteTaskMedia);
    on<InspectionTaskSearchMedia>(_onSearchMedia);
    on<InspectionUploadTaskMedia>(_onUploadMedia);
    on<InspectionUploadTaskMediaOnTask>(_onUploadMediaOnTask);
  }
  Future<void> _silentRefresh(
    InspectionTaskSilentMediaRefresh event,
    Emitter<InspectionTaskMediaState> emit,
  ) async {
    try {
      _offset = 0;
      _hasReachedMax = false;

      // Don't emit loading state - keep current state visible
      List<InspectionTaskMediaModel> media = [];
      Map<String, dynamic> result = await InspectionTaskRepo().getTaskMedia(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: '',
      );

      media = List<InspectionTaskMediaModel>.from(
        result['data'].map(
            (projectData) => InspectionTaskMediaModel.fromJson(projectData)),
      );

      if (event.id != null) {
        _offset = 0;
      } else {
        _offset += _limit;
      }
      _hasReachedMax = media.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(
          InspectionTaskMediaPaginated(
            TaskMediaList: media,
            hasReachedMax: _hasReachedMax,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((InspectionTaskMediaError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      logger.e("Error: $e");
      emit((InspectionTaskMediaError("Error: $e")));
    }
  }

  Future<void> _onUploadMedia(
    InspectionUploadTaskMedia event,
    Emitter<InspectionTaskMediaState> emit,
  ) async {
    try {
      Map<String, dynamic> result = await InspectionTaskRepo().uploadTaskMedia(
        id: event.id,
        media: event.media,
      );

      if (result['data']['error'] == false) {
        emit(InspectionTaskMediaUploadSuccess());
      }
      if (result['data']['error'] == true) {
        emit((InspectionTaskMediaError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(InspectionTaskMediaError(e.toString()));
    }
  }

  Future<void> _onUploadMediaOnTask(
    InspectionUploadTaskMediaOnTask event,
    Emitter<InspectionTaskMediaState> emit,
  ) async {
    try {
      Map<String, dynamic> result =
          await InspectionTaskRepo().uploadInspectionTaskMedia(
        id: event.id,
        media: event.media,
      );

      // ✅ Check top-level error field
      if (result['error'] == false && result['data'] != null) {
        emit(InspectionTaskMediaUploadSuccess());
      } else {
        emit(InspectionTaskMediaError(result['message'] ?? 'Upload failed'));
        flutterToastCustom(msg: result['message'] ?? 'Upload failed');
      }
    } catch (e) {
      logger.e("❌ Error uploading task media: $e");
      emit(InspectionTaskMediaError(e.toString()));
      flutterToastCustom(msg: "Upload failed: ${e.toString()}");
    }
  }

  Future<void> _onSearchMedia(
    InspectionTaskSearchMedia event,
    Emitter<InspectionTaskMediaState> emit,
  ) async {
    try {
      List<InspectionTaskMediaModel> media = [];
      if (kDebugMode) {
        logger.i("_onSearchMedia: ${event.searchQuery}");
      }
      Map<String, dynamic> result = await InspectionTaskRepo().getTaskMedia(
        limit: _limit,
        offset: 0,
        search: event.searchQuery,
        id: event.id,
      );
      media = List<InspectionTaskMediaModel>.from(
        result['data']
            .map((TaskData) => InspectionTaskMediaModel.fromJson(TaskData)),
      );

      bool hasReachedMax = media.length >= result['total'];
      if (!result.containsKey('error')) {
        emit(
          InspectionTaskMediaPaginated(
            TaskMediaList: media,
            hasReachedMax: hasReachedMax,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((InspectionTaskMediaError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      flutterToastCustom(msg: "$e");

      emit(InspectionTaskMediaError("Error: $e"));
    }
  }

  void _deleteTaskMedia(
    InspectionTaskDeleteMedia event,
    Emitter<InspectionTaskMediaState> emit,
  ) async {
    try {
      final result = await InspectionTaskRepo().getDeleteTaskMedia(
        id: event.id ?? 0,
      );

      // Check if delete was successful
      // API might return error: false for success, or no error field at all
      if (result['error'] == false ||
          result['status'] == 200 ||
          !result.containsKey('error')) {
        emit(InspectionTaskMediaDeleteSuccess());
        return;
      }

      final errorMessage = result['message']?.toString() ?? 'Delete failed';
      emit(InspectionTaskMediaError(errorMessage));
      flutterToastCustom(msg: errorMessage);
    } catch (e) {
      emit(InspectionTaskMediaError(e.toString()));
      flutterToastCustom(msg: e.toString());
    }
  }

  Future<void> _getMediaLists(
    InspectionTaskMediaList event,
    Emitter<InspectionTaskMediaState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      filter = 'filter[parent]=null&filter[id]=${event.id}&filter[active]=1';
      fields = '*, photos.id, photos.directus_files_id.*';

      if (state is! InspectionTaskDownloadSuccess) {
        emit(InspectionTaskMediaLoading());
      }

      Map<String, dynamic> result = await InspectionTaskRepo().getTaskMedia(
        id: event.id,
        limit: _limit,
        offset: _offset,
        // filter: filter,
        // fields: fields,
        search: '',
      );

      // Check if 'data' exists and is a List
      if (result['data'] == null || result['data'] is! List) {
        emit(
            InspectionTaskMediaError("Invalid response: Missing 'data' field"));
        return;
      }

      List<InspectionTaskMediaModel> media = [];

      for (var i = 0; i < result['data'].length; i++) {
        try {
          var item = InspectionTaskMediaModel.fromJson(result['data'][i]);
          media.add(item);
        } catch (e, stackTrace) {
          logger.e("❌ Error parsing item $i: $e");
          logger.e("❌ Stack trace: $stackTrace");
          logger.e("❌ Problematic data: ${result['data'][i]}");
        }
      }

      if (event.id == null) {
        _offset += _limit;
      } else {
        _offset = 0;
      }

      // Safe comparison with total
      int total = 0;
      if (result['total'] is int) {
        total = result['total'];
      } else if (result['total'] != null) {
        total = int.tryParse(result['total'].toString()) ?? media.length;
      } else {
        total = media.length;
      }

      _hasReachedMax = media.length >= total;

      if (!result.containsKey('error') && media.isNotEmpty) {
        emit(
          InspectionTaskMediaPaginated(
            TaskMediaList: media,
            hasReachedMax: _hasReachedMax,
          ),
        );
      } else if (media.isEmpty) {
        emit(InspectionTaskMediaError("No media files found"));
      } else {
        emit(InspectionTaskMediaError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on DioException catch (e) {
      logger.e("DioException statusCode: ${e.response?.statusCode}");
      logger.e("DioException message: ${e.message}");
      logger.e("DioException response: ${e.response?.data}");
      String errorMessage = "Error loading media";
      if (e.response?.statusCode == 403) {
        errorMessage =
            "Permission denied. You don't have access to view these files.";
      } else if (e.response?.statusCode == 404) {
        errorMessage = "Files not found";
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = "Connection timeout";
      }

      emit(InspectionTaskMediaError(errorMessage));
      flutterToastCustom(msg: errorMessage);
    } on ApiException catch (e) {
      logger.e("API Exception: $e");

      emit(InspectionTaskMediaError("Error: $e"));
      flutterToastCustom(msg: "Error: $e");
    } catch (e) {
      logger.e("Unexpected error: $e");

      emit(InspectionTaskMediaError("Unexpected error: ${e.toString()}"));
      flutterToastCustom(msg: "Unexpected error: ${e.toString()}");
    }
  }

  Future<void> _onStartDownload(
    InspectionTaskStartDownload event,
    Emitter<InspectionTaskMediaState> emit,
  ) async {
    emit(InspectionTaskDownloadInProgress(0.0, event.fileName));

    try {
      String? filePath;

      if (Platform.isAndroid) {
        // Method 1: Try to save directly to Downloads folder
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            filePath = "${downloadsDir.path}/${event.fileName}";

            // Test if we can write to Downloads folder
            final testFile = File(filePath);
            await testFile.writeAsString('test');
            await testFile.delete();

            // If we reach here, we can write to Downloads
            await _downloadFile(event.fileUrl, filePath, emit, event.fileName);
            emit(InspectionTaskDownloadSuccess(filePath, event.fileName));
            return;
          }
        } catch (e) {
          logger.e("Cannot write to Downloads folder: $e");
        }

        // Method 2: Use file picker to let user choose location
        try {
          // First download to temporary location
          final tempDir = await getTemporaryDirectory();
          final tempFile = File("${tempDir.path}/${event.fileName}");

          await _downloadFile(
            event.fileUrl,
            tempFile.path,
            emit,
            event.fileName,
          );

          // Let user choose where to save
          final result = await FilePicker.platform.saveFile(
            dialogTitle: 'Save ${event.fileName}',
            fileName: event.fileName,
            bytes: await tempFile.readAsBytes(),
          );

          if (result != null) {
            await tempFile.delete(); // Clean up temp file
            emit(InspectionTaskDownloadSuccess(result, event.fileName));
          } else {
            await tempFile.delete(); // Clean up temp file
            emit(InspectionTaskDownloadFailure("Save cancelled by user"));
          }
          return;
        } catch (e) {
          logger.e("File picker failed: $e");
        }

        // Method 3: Fallback - save to app documents and provide sharing option
        final documentsDir = await getApplicationDocumentsDirectory();
        filePath = "${documentsDir.path}/${event.fileName}";

        await _downloadFile(event.fileUrl, filePath, emit, event.fileName);
        emit(InspectionTaskDownloadSuccess(filePath, event.fileName));
      } else {
        // iOS
        final documentsDir = await getApplicationDocumentsDirectory();
        filePath = "${documentsDir.path}/${event.fileName}";

        await _downloadFile(event.fileUrl, filePath, emit, event.fileName);
        emit(InspectionTaskDownloadSuccess(filePath, event.fileName));
      }
    } catch (e) {
      emit(InspectionTaskDownloadFailure(e.toString()));
    }
  }

  // Helper method to download file
  Future<void> _downloadFile(
    String url,
    String filePath,
    Emitter<InspectionTaskMediaState> emit,
    String fileName,
  ) async {
    Dio dio = Dio();
    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          emit(InspectionTaskDownloadInProgress(received / total, fileName));
        }
      },
    );
  }
}
