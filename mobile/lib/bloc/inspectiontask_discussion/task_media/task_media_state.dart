import 'package:equatable/equatable.dart';

import '../../../data/model/inspectiontask/media.dart';

abstract class InspectionTaskMediaState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionTaskMediaInitial extends InspectionTaskMediaState {}

class InspectionTaskMediaLoading extends InspectionTaskMediaState {}

class InspectionTaskMediaSuccess extends InspectionTaskMediaState {}

class InspectionTaskMediaPaginated extends InspectionTaskMediaState {
  final List<InspectionTaskMediaModel> TaskMediaList;
  final bool hasReachedMax;

  InspectionTaskMediaPaginated({
    required this.TaskMediaList,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [TaskMediaList, hasReachedMax];
}

class InspectionTaskMediaError extends InspectionTaskMediaState {
  final String errorMessage;
  InspectionTaskMediaError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionTaskDownloadInProgress extends InspectionTaskMediaState {
  final double progress;
  final String fileName;
  InspectionTaskDownloadInProgress(this.progress, this.fileName);

  @override
  List<Object?> get props => [progress];
}

class InspectionTaskDownloadSuccess extends InspectionTaskMediaState {
  final String filePath;
  final String fileName;
  InspectionTaskDownloadSuccess(this.filePath, this.fileName);

  @override
  List<Object?> get props => [filePath];
}

class InspectionTaskDownloadFailure extends InspectionTaskMediaState {
  final String error;
  InspectionTaskDownloadFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class InspectionTaskMediaDeleteSuccess extends InspectionTaskMediaState {
  InspectionTaskMediaDeleteSuccess();
  @override
  List<Object> get props => [];
}

class InspectionTaskMediaUploadSuccess extends InspectionTaskMediaState {
  InspectionTaskMediaUploadSuccess();
  @override
  List<Object> get props => [];
}
