import 'package:equatable/equatable.dart';
import 'package:ibex/data/model/work/media.dart';

abstract class WorkMediaState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkMediaInitial extends WorkMediaState {}

class WorkMediaLoading extends WorkMediaState {}

class WorkMediaSuccess extends WorkMediaState {}

class WorkMediaPaginated extends WorkMediaState {
  final List<MediaModel> WorkMedia;
  final bool hasReachedMax;
  final Map<String, double>
      downloadProgress; // Map of fileName to progress (0.0 to 1.0)

  WorkMediaPaginated({
    required this.WorkMedia,
    required this.hasReachedMax,
    this.downloadProgress = const {}, // Empty by default
  });

  WorkMediaPaginated copyWith({
    List<MediaModel>? WorkMedia,
    bool? hasReachedMax,
    Map<String, double>? downloadProgress,
  }) {
    return WorkMediaPaginated(
      WorkMedia: WorkMedia ?? this.WorkMedia,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  @override
  List<Object> get props => [WorkMedia, hasReachedMax, downloadProgress];
}

class WorkMediaError extends WorkMediaState {
  final String errorMessage;
  WorkMediaError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class DownloadInProgress extends WorkMediaState {
  final double progress;
  final String fileName;
  DownloadInProgress(this.progress, this.fileName);

  @override
  List<Object?> get props => [progress];
}

class DownloadSuccess extends WorkMediaState {
  final String filePath;
  final String fileName;
  DownloadSuccess(this.filePath, this.fileName);

  @override
  List<Object?> get props => [filePath];
}

class DownloadFailure extends WorkMediaState {
  final String error;
  DownloadFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class WorkMediaDeleteSuccess extends WorkMediaState {
  WorkMediaDeleteSuccess();
  @override
  List<Object> get props => [];
}

class WorkMediaUploadSuccess extends WorkMediaState {
  WorkMediaUploadSuccess();
  @override
  List<Object> get props => [];
}
