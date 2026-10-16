import 'package:equatable/equatable.dart';

import '../../../data/model/work/media.dart';

abstract class WorkTaskMediaState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkTaskMediaInitial extends WorkTaskMediaState {}

class WorkTaskMediaLoading extends WorkTaskMediaState {}

class WorkTaskMediaSuccess extends WorkTaskMediaState {}

class WorkTaskMediaPaginated extends WorkTaskMediaState {
  final List<MediaModel> TaskMediaList;
  final bool hasReachedMax;

  WorkTaskMediaPaginated({
    required this.TaskMediaList,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [TaskMediaList, hasReachedMax];
}

class WorkTaskMediaError extends WorkTaskMediaState {
  final String errorMessage;
  WorkTaskMediaError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkTaskDownloadInProgress extends WorkTaskMediaState {
  final double progress;
  final String fileName;
  WorkTaskDownloadInProgress(this.progress, this.fileName);

  @override
  List<Object?> get props => [progress];
}

class WorkTaskDownloadSuccess extends WorkTaskMediaState {
  final String filePath;
  final String fileName;
  WorkTaskDownloadSuccess(this.filePath, this.fileName);

  @override
  List<Object?> get props => [filePath];
}

class WorkTaskDownloadFailure extends WorkTaskMediaState {
  final String error;
  WorkTaskDownloadFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class WorkTaskMediaDeleteSuccess extends WorkTaskMediaState {
  WorkTaskMediaDeleteSuccess();
  @override
  List<Object> get props => [];
}

class WorkTaskMediaUploadSuccess extends WorkTaskMediaState {
  WorkTaskMediaUploadSuccess();
  @override
  List<Object> get props => [];
}
