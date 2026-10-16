import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ibex/bloc/worktask_discussion/task_media/task_media_state.dart';

import '../../../api_helper/api.dart';

import '../../../data/model/work/media.dart';
import '../../../data/repositories/Worktask/Task_repo.dart';
import '../../../utils/widgets/toast_widget.dart';
import 'package:logger/logger.dart';

part 'task_media_event.dart';

final logger = Logger();

class WorkTaskMediaBloc extends Bloc<WorkTaskMediaEvent, WorkTaskMediaState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;
  WorkTaskMediaBloc() : super(WorkTaskMediaInitial()) {
    on<WorkTaskMediaList>(_getMediaLists);
    on<WorkTaskStartDownload>(_onStartDownload);
    on<WorkTaskSilentMediaRefresh>(_silentRefresh);
    on<WorkDeleteTaskMedia>(_deleteTaskMedia);
    on<WorkTaskSearchMedia>(_onSearchMedia);
    on<WorkUploadTaskMedia>(_onUploadMedia);
  }
  Future<void> _silentRefresh(
    WorkTaskSilentMediaRefresh event,
    Emitter<WorkTaskMediaState> emit,
  ) async {
    try {
      _offset = 0;
      _hasReachedMax = false;

      // Don't emit loading state - keep current state visible
      List<MediaModel> media = [];
      Map<String, dynamic> result = await WorkTaskRepo().getTaskMedia(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: '',
      );

      media = List<MediaModel>.from(
        result['data'].map((projectData) => MediaModel.fromJson(projectData)),
      );

      if (event.id != null) {
        _offset = 0;
      } else {
        _offset += _limit;
      }
      _hasReachedMax = media.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(
          WorkTaskMediaPaginated(
            TaskMediaList: media,
            hasReachedMax: _hasReachedMax,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((WorkTaskMediaError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
        if (kDebugMode) {
          logger.d(e);
        }
      emit((WorkTaskMediaError("Error: $e")));
    }
  }

  Future<void> _onUploadMedia(
    WorkUploadTaskMedia event,
    Emitter<WorkTaskMediaState> emit,
  ) async {
    try {
      Map<String, dynamic> result = await WorkTaskRepo().uploadTaskMedia(
        id: event.id,
        media: event.media,
      );

      if (result['data']['error'] == false) {
        emit(WorkTaskMediaUploadSuccess());
      }
      if (result['data']['error'] == true) {
        emit((WorkTaskMediaError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(WorkTaskMediaError(e.toString()));
    }
  }

  Future<void> _onSearchMedia(
    WorkTaskSearchMedia event,
    Emitter<WorkTaskMediaState> emit,
  ) async {
    try {
      List<MediaModel> media = [];
      Map<String, dynamic> result = await WorkTaskRepo().getTaskMedia(
        limit: _limit,
        offset: 0,
        search: event.searchQuery,
        id: event.id,
      );
      media = List<MediaModel>.from(
        result['data'].map((TaskData) => MediaModel.fromJson(TaskData)),
      );

      bool hasReachedMax = media.length >= result['total'];
      if (!result.containsKey('error')) {
        emit(
          WorkTaskMediaPaginated(
            TaskMediaList: media,
            hasReachedMax: hasReachedMax,
          ),
        );
      }
      if (result.containsKey('errors')) {
        emit((WorkTaskMediaError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      flutterToastCustom(msg: "$e");

      emit(WorkTaskMediaError("Error: $e"));
    }
  }

  void _deleteTaskMedia(
    WorkDeleteTaskMedia event,
    Emitter<WorkTaskMediaState> emit,
  ) async {
    final Task = event.id;

    try {
      Map<String, dynamic> result = await WorkTaskRepo().getDeleteTaskMedia(
        id: event.id.toString(),
        token: true,
      );
      if (result['data']['error'] == false) {
        emit(WorkTaskMediaDeleteSuccess());
      }
      if (result['data']['error'] == true) {
        emit((WorkTaskMediaError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(WorkTaskMediaError(e.toString()));
    }
    // }
  }

  Future<void> _getMediaLists(
    WorkTaskMediaList event,
    Emitter<WorkTaskMediaState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;

      if (state is! WorkTaskDownloadSuccess) {
        emit(WorkTaskMediaLoading());
      }

      Map<String, dynamic> result = await WorkTaskRepo().getTaskMedia(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: '',
      );

      // Check if 'data' exists and is a List
      if (result['data'] == null || result['data'] is! List) {
        emit(WorkTaskMediaError("Invalid response: Missing 'data' field"));
        return;
      }

      List<MediaModel> media = List<MediaModel>.from(
        result['data'].map((taskData) => MediaModel.fromJson(taskData)),
      );

      if (event.id == null) {
        _offset += _limit;
      } else {
        _offset = 0;
      }

      _hasReachedMax = media.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(
          WorkTaskMediaPaginated(
            TaskMediaList: media,
            hasReachedMax: _hasReachedMax,
          ),
        );
      } else {
        emit(WorkTaskMediaError(result['message']));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d("API Exception: $e");
      }
      emit(WorkTaskMediaError("Error: $e"));
    } catch (e) {
      if (kDebugMode) {
        logger.d("Unexpected error: $e");
      }

      emit(WorkTaskMediaError("Unexpected error occurred"));
    }
  }

  Future<void> _onStartDownload(
    WorkTaskStartDownload event,
    Emitter<WorkTaskMediaState> emit,
  ) async {
    emit(WorkTaskDownloadInProgress(0.0, event.fileName));

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
            emit(WorkTaskDownloadSuccess(filePath, event.fileName));
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            logger.d("Cannot write to Downloads folder: $e");
          }
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
            emit(WorkTaskDownloadSuccess(result, event.fileName));
          } else {
            await tempFile.delete(); // Clean up temp file
            emit(WorkTaskDownloadFailure("Save cancelled by user"));
          }
          return;
        } catch (e) {
          if (kDebugMode) {
            logger.d("File picker failed: $e");
          }
        }

        // Method 3: Fallback - save to app documents and provide sharing option
        final documentsDir = await getApplicationDocumentsDirectory();
        filePath = "${documentsDir.path}/${event.fileName}";

        await _downloadFile(event.fileUrl, filePath, emit, event.fileName);
        emit(WorkTaskDownloadSuccess(filePath, event.fileName));
      } else {
        // iOS
        final documentsDir = await getApplicationDocumentsDirectory();
        filePath = "${documentsDir.path}/${event.fileName}";

        await _downloadFile(event.fileUrl, filePath, emit, event.fileName);
        emit(WorkTaskDownloadSuccess(filePath, event.fileName));
      }
    } catch (e) {
      emit(WorkTaskDownloadFailure(e.toString()));
    }
  }

  // Helper method to download file
  Future<void> _downloadFile(
    String url,
    String filePath,
    Emitter<WorkTaskMediaState> emit,
    String fileName,
  ) async {
    Dio dio = Dio();
    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          emit(WorkTaskDownloadInProgress(received / total, fileName));
        }
      },
    );
  }
}
