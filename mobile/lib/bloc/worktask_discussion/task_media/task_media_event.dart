part of 'task_media_bloc.dart';

abstract class WorkTaskMediaEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkTaskMediaList extends WorkTaskMediaEvent {
  final int? id;

  WorkTaskMediaList({
    this.id,
  });

  @override
  List<Object?> get props => [id];
}

class WorkDeleteTaskMedia extends WorkTaskMediaEvent {
  final int id;

  WorkDeleteTaskMedia({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}

class WorkTaskSilentMediaRefresh extends WorkTaskMediaEvent {
  final int? id;
  WorkTaskSilentMediaRefresh({this.id});

  @override
  List<Object?> get props => [id];
}

class WorkTaskStartDownload extends WorkTaskMediaEvent {
  final String fileUrl;
  final String fileName;

  WorkTaskStartDownload({required this.fileUrl, required this.fileName});

  @override
  List<Object?> get props => [fileUrl, fileName];
}

class WorkTaskSearchMedia extends WorkTaskMediaEvent {
  final String searchQuery;
  final int? id;

  WorkTaskSearchMedia(this.searchQuery, this.id);

  @override
  List<Object?> get props => [searchQuery];
}

class WorkUploadTaskMedia extends WorkTaskMediaEvent {
  final int id;
  final List<File> media; // List of files to be uploaded

  WorkUploadTaskMedia({required this.id, required this.media});

  @override
  List<Object?> get props => [id, media];
}
