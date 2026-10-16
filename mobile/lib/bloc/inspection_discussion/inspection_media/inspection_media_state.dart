import 'package:equatable/equatable.dart';
import 'package:ibex/data/model/inspection/media.dart';

abstract class InspectionMediaState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionMediaInitial extends InspectionMediaState {}

class InspectionMediaLoading extends InspectionMediaState {}

class InspectionMediaSuccess extends InspectionMediaState {}

class InspectionMediaPaginated extends InspectionMediaState {
  final List<InspectionMediaModel> InspectionMedia;
  final bool hasReachedMax;
  final Map<String, double>
      downloadProgress; // Map of fileName to progress (0.0 to 1.0)

  InspectionMediaPaginated({
    required this.InspectionMedia,
    required this.hasReachedMax,
    this.downloadProgress = const {}, // Empty by default
  });

  InspectionMediaPaginated copyWith({
    List<InspectionMediaModel>? InspectionMedia,
    bool? hasReachedMax,
    Map<String, double>? downloadProgress,
  }) {
    return InspectionMediaPaginated(
      InspectionMedia: InspectionMedia ?? this.InspectionMedia,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  @override
  List<Object> get props => [InspectionMedia, hasReachedMax, downloadProgress];
}

class InspectionMediaError extends InspectionMediaState {
  final String errorMessage;
  InspectionMediaError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class DownloadInProgress extends InspectionMediaState {
  final double progress;
  final String fileName;
  DownloadInProgress(this.progress, this.fileName);

  @override
  List<Object?> get props => [progress];
}

class DownloadSuccess extends InspectionMediaState {
  final String filePath;
  final String fileName;
  DownloadSuccess(this.filePath, this.fileName);

  @override
  List<Object?> get props => [filePath];
}

class DownloadFailure extends InspectionMediaState {
  final String error;
  DownloadFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class InspectionMediaDeleteSuccess extends InspectionMediaState {
  InspectionMediaDeleteSuccess();
  @override
  List<Object> get props => [];
}

class InspectionMediaUploadSuccess extends InspectionMediaState {
  InspectionMediaUploadSuccess();
  @override
  List<Object> get props => [];
}
