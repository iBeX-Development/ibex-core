part of 'task_media_bloc.dart';

abstract class InspectionTaskMediaEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionTaskMediaList extends InspectionTaskMediaEvent {
  final int? id;
  final int? workorderId;

  InspectionTaskMediaList({
    this.id,
    this.workorderId,
  });

  @override
  List<Object?> get props => [id, workorderId];
}

class InspectionDeleteTaskMedia extends InspectionTaskMediaEvent {
  final int? id;

  InspectionDeleteTaskMedia({
    this.id,
  });

  @override
  List<Object?> get props => [id];
}

class InspectionTaskSilentMediaRefresh extends InspectionTaskMediaEvent {
  final int? id;
  InspectionTaskSilentMediaRefresh({this.id});

  @override
  List<Object?> get props => [id];
}

class InspectionTaskStartDownload extends InspectionTaskMediaEvent {
  final String fileUrl;
  final String fileName;

  InspectionTaskStartDownload({required this.fileUrl, required this.fileName});

  @override
  List<Object?> get props => [fileUrl, fileName];
}

class InspectionTaskSearchMedia extends InspectionTaskMediaEvent {
  final String searchQuery;
  final int? id;

  InspectionTaskSearchMedia(this.searchQuery, this.id);

  @override
  List<Object?> get props => [searchQuery];
}

class InspectionTaskDeleteMedia extends InspectionTaskMediaEvent {
  final String? searchQuery;
  final int? id;

  InspectionTaskDeleteMedia(this.id, this.searchQuery);
  @override
  List<Object?> get props => [id, searchQuery];
}

class InspectionUploadTaskMedia extends InspectionTaskMediaEvent {
  final int id;
  final List<File> media; // List of files to be uploaded

  InspectionUploadTaskMedia({required this.id, required this.media});

  @override
  List<Object?> get props => [id, media];
}

class InspectionUploadTaskMediaOnTask extends InspectionTaskMediaEvent {
  final int id;
  final List<File> media; // List of files to be uploaded

  InspectionUploadTaskMediaOnTask({required this.id, required this.media});
  @override
  List<Object?> get props => [id, media];
}
