part of 'work_media_bloc.dart';

abstract class WorkMediaEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MediaList extends WorkMediaEvent {
  final int? id;

  MediaList({
    this.id,
  });

  @override
  List<Object?> get props => [id];
}

class SilentMediaRefresh extends WorkMediaEvent {
  final int? id;
  SilentMediaRefresh({this.id});

  @override
  List<Object?> get props => [id];
}

class DeleteWorkMedia extends WorkMediaEvent {
  final int? id;

  DeleteWorkMedia({
    this.id,
  });

  @override
  List<Object?> get props => [id];
}

class StartDownload extends WorkMediaEvent {
  final String fileUrl; // ✅ Should be String, not MediaFile
  final String fileName;

  StartDownload({
    required this.fileUrl,
    required this.fileName,
  });

  @override
  List<Object?> get props => [fileUrl, fileName];
}

class UploadMedia extends WorkMediaEvent {
  final int id;
  final List<File> media; // List of files to be uploaded

  UploadMedia({required this.id, required this.media}); // ✅ Mark required

  @override
  List<Object?> get props => [id, media];
}

class SearchMedia extends WorkMediaEvent {
  final String searchQuery;
  final int? id;

  SearchMedia(this.searchQuery, this.id);

  @override
  List<Object?> get props => [searchQuery];
}
