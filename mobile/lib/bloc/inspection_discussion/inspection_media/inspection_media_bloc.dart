import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:ibex/bloc/inspection_discussion/inspection_media/inspection_media_state.dart';
import '../../../api_helper/api.dart';
import '../../../data/model/inspection/media.dart';
import '../../../data/repositories/inspection/inspection_repo.dart';
import '../../../utils/widgets/toast_widget.dart';
import '../../../api_helper/header.dart';
import 'package:logger/logger.dart';

part 'inspection_media_event.dart';

final logger = Logger();

class InspectionMediaBloc
    extends Bloc<InspectionMediaEvent, InspectionMediaState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 10;
  bool _hasReachedMax = false;

  InspectionMediaBloc() : super(InspectionMediaInitial()) {
    on<MediaList>(_getMediaLists);
    on<SilentMediaRefresh>(_silentRefresh);
    on<StartDownload>(_onStartDownload);
    on<DeleteInspectionMedia>(_onDeleteInspectionMedia);
    on<SearchMedia>(_onSearchMedia);
    on<UploadMedia>(_onUploadMedia);
    on<UploadMediaOnTask>(_onUploadMediaonTask);
  }

  Future<void> _onUploadMedia(
    UploadMedia event,
    Emitter<InspectionMediaState> emit,
  ) async {
    try {
      emit(InspectionMediaLoading());

      Map<String, dynamic> result =
          await InspectionRepo().uploadInspectionMedia(
        id: event.id,
        media: event.media,
      );

      // ✅ Check if upload was successful
      if (result['error'] == false || result['data'] != null) {
        // ✅ Reload media list after successful upload
        add(MediaList(id: event.id));

        flutterToastCustom(
          msg: 'Files uploaded successfully',
          color: Colors.green,
        );
      } else {
        final errorMessage = result['message'] ?? 'Upload failed';
        emit(InspectionMediaError(errorMessage));
        flutterToastCustom(
          msg: errorMessage,
        );
      }
    } catch (e) {
      emit(InspectionMediaError(e.toString()));
    }
  }

  Future<void> _onUploadMediaonTask(
    UploadMediaOnTask event,
    Emitter<InspectionMediaState> emit,
  ) async {
    try {
      emit(InspectionMediaLoading());

      Map<String, dynamic> result =
          await InspectionRepo().uploadInspectionTaskMedia(
        id: event.id,
        media: event.media,
      );

      // ✅ Check if upload was successful
      if (result['error'] == false || result['data'] != null) {
        // ✅ Reload media list after successful upload
        add(MediaList(id: event.id));

        flutterToastCustom(
          msg: 'Files uploaded successfully',
          color: Colors.green,
        );
      } else {
        final errorMessage = result['message'] ?? 'Upload failed';
        emit(InspectionMediaError(errorMessage));
        flutterToastCustom(
          msg: errorMessage,
        );
      }
    } catch (e) {
      emit(InspectionMediaError(e.toString()));
    }
  }

  Future<void> _onSearchMedia(
    SearchMedia event,
    Emitter<InspectionMediaState> emit,
  ) async {
    try {
      List<InspectionMediaModel> media = [];

      Map<String, dynamic> result = await InspectionRepo().getInspectionMedia(
        limit: _limit,
        offset: 0,
        search: event.searchQuery,
        id: event.id,
      );
      media = List<InspectionMediaModel>.from(
        result['data'].map(
            (inspectionData) => InspectionMediaModel.fromJson(inspectionData)),
      );

      bool hasReachedMax = media.length >= result['total'];
      if (!result.containsKey('error')) {
        emit(
          InspectionMediaPaginated(
              InspectionMedia: media, hasReachedMax: hasReachedMax),
        );
      }
      if (result.containsKey('errors')) {
        emit((InspectionMediaError(result['message'])));
        flutterToastCustom(
          msg: result['message'],
        );
      }
    } on ApiException catch (e) {
      flutterToastCustom(msg: "$e");
      emit(InspectionMediaError("Error: $e"));
    }
  }

  void _onDeleteInspectionMedia(
    DeleteInspectionMedia event,
    Emitter<InspectionMediaState> emit,
  ) async {
    final inspection = event.id;

    try {
      Map<String, dynamic> result =
          await InspectionRepo().getDeleteInspectionMedia(
        id: inspection.toString(),
        token: true,
      );
      if (result['data']['error'] == false) {
        emit(InspectionMediaDeleteSuccess());
      }
      if (result['data']['error'] == true) {
        emit((InspectionMediaError(result['message'])));
        flutterToastCustom(
          msg: result['message'],
        );
      }
    } catch (e) {
      emit(InspectionMediaError(e.toString()));
    }
  }

  Future<void> _getMediaLists(
    MediaList event,
    Emitter<InspectionMediaState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;

      // Only show loading if not downloading or download completed
      if (state is! DownloadInProgress && state is! DownloadSuccess) {
        emit(InspectionMediaLoading());
      }

      List<InspectionMediaModel> media = [];
      Map<String, dynamic> result = await InspectionRepo().getInspectionMedia(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: '',
      );

      media = List<InspectionMediaModel>.from(
        result['data'].map(
            (inspectionData) => InspectionMediaModel.fromJson(inspectionData)),
      );

      if (event.id != null) {
        _offset = 0;
      } else {
        _offset += _limit;
      }

      int? totalCount = result['meta']?['filter_count'] ??
          result['meta']?['total_count'] ??
          result['total_count'] ??
          result['total'] ??
          result['count'];
      _hasReachedMax = media.length >= (totalCount ?? 0);

      if (!result.containsKey('error')) {
        emit(
          InspectionMediaPaginated(
              InspectionMedia: media, hasReachedMax: _hasReachedMax),
        );
      }
      if (result.containsKey('errors')) {
        emit((InspectionMediaError(result['message'])));
        flutterToastCustom(
          msg: result['message'],
        );
      }
    } on ApiException catch (e) {
      logger.e('API Exception: $e');
      emit((InspectionMediaError("Error: $e")));
    }
  }

  // Silent refresh method to avoid showing loading state
  Future<void> _silentRefresh(
    SilentMediaRefresh event,
    Emitter<InspectionMediaState> emit,
  ) async {
    try {
      _offset = 0;
      _hasReachedMax = false;

      // Don't emit loading state - keep current state visible
      List<InspectionMediaModel> media = [];
      Map<String, dynamic> result = await InspectionRepo().getInspectionMedia(
        id: event.id,
        limit: _limit,
        offset: _offset,
        search: '',
      );

      media = List<InspectionMediaModel>.from(
        result['data'].map(
            (inspectionData) => InspectionMediaModel.fromJson(inspectionData)),
      );

      if (event.id != null) {
        _offset = 0;
      } else {
        _offset += _limit;
      }
      _hasReachedMax = media.length >= result['total'];

      if (!result.containsKey('error')) {
        emit(
          InspectionMediaPaginated(
              InspectionMedia: media, hasReachedMax: _hasReachedMax),
        );
      }
      if (result.containsKey('errors')) {
        emit((InspectionMediaError(result['message'])));
        flutterToastCustom(
          msg: result['message'],
        );
      }
    } on ApiException catch (e) {
      logger.e('API Exception: $e');
      emit((InspectionMediaError("Error: $e")));
    }
  }

  Future<void> _onStartDownload(
    StartDownload event,
    Emitter<InspectionMediaState> emit,
  ) async {
    emit(DownloadInProgress(0.0, event.fileName));

    try {
      // ✅ Ensure fileUrl is a String
      // ✅ event.fileUrl is already String
      final String downloadUrl = event.fileUrl;
      final String fileName = event.fileName;

      // ✅ Validate URL
      if (downloadUrl.isEmpty) {
        emit(DownloadFailure("Invalid file URL"));
        flutterToastCustom(msg: 'Invalid file URL', color: Colors.red);
        return;
      }

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
            await _downloadFile(downloadUrl, filePath, emit, event.fileName);
            emit(DownloadSuccess(filePath, event.fileName));

            flutterToastCustom(
              msg: 'Downloaded to Downloads folder',
              color: Colors.green,
            );
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
            downloadUrl,
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
            emit(DownloadSuccess(result, event.fileName));

            flutterToastCustom(
              msg: 'File saved successfully',
              color: Colors.green,
            );
          } else {
            await tempFile.delete(); // Clean up temp file
            emit(DownloadFailure("Save cancelled by user"));

            flutterToastCustom(
              msg: 'Save cancelled',
            );
          }
          return;
        } catch (e) {
          logger.e("File picker failed: $e");
        }

        // Method 3: Fallback - save to app documents and provide sharing option
        final documentsDir = await getApplicationDocumentsDirectory();
        filePath = "${documentsDir.path}/${event.fileName}";

        await _downloadFile(downloadUrl, filePath, emit, event.fileName);
        emit(DownloadSuccess(filePath, event.fileName));

        flutterToastCustom(
          msg: 'Downloaded to app folder',
          color: Colors.green,
        );
      } else {
        // iOS
        final documentsDir = await getApplicationDocumentsDirectory();
        filePath = "${documentsDir.path}/${event.fileName}";

        await _downloadFile(downloadUrl, filePath, emit, event.fileName);
        emit(DownloadSuccess(filePath, event.fileName));

        flutterToastCustom(
          msg: 'File downloaded successfully',
          color: Colors.green,
        );
      }
    } catch (e, stackTrace) {
      logger.e("❌ Download error: $e");
      logger.e("❌ Stack trace: $stackTrace");

      emit(DownloadFailure(e.toString()));

      flutterToastCustom(
        msg: 'Download failed: ${e.toString()}',
      );
    }
  }

  // Helper method to download file
  Future<void> _downloadFile(
    String url,
    String filePath,
    Emitter<InspectionMediaState> emit,
    String fileName,
  ) async {
    try {
      Dio dio = Dio();

      // ✅ Add proper headers for authentication if needed
      final Map<String, String>? authHeaders = await headers;

      await dio.download(
        url,
        filePath,
        options: Options(headers: authHeaders),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            logger.i(
                "📥 Download progress: ${(progress * 100).toStringAsFixed(1)}%");
            emit(DownloadInProgress(progress, fileName));
          }
        },
      );

      if (kDebugMode) {

        logger.i("✅ Download completed: $filePath");

      }
    } catch (e) {
      logger.e("❌ Download file error: $e");
      throw Exception('Download failed: $e');
    }
  }
}
