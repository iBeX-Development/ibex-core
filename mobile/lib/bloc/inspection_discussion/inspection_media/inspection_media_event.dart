part of 'inspection_media_bloc.dart';

abstract class InspectionMediaEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MediaList extends InspectionMediaEvent {
  final int? id;

  MediaList({
    this.id,
  });

  @override
  List<Object?> get props => [id];
}

class SilentMediaRefresh extends InspectionMediaEvent {
  final int? id;
  SilentMediaRefresh({this.id});

  @override
  List<Object?> get props => [id];
}

class DeleteInspectionMedia extends InspectionMediaEvent {
  final int? id;

  DeleteInspectionMedia({
    this.id,
  });

  @override
  List<Object?> get props => [id];
}

class StartDownload extends InspectionMediaEvent {
  final String fileUrl; // ✅ Should be String, not MediaFile
  final String fileName;

  StartDownload({
    required this.fileUrl,
    required this.fileName,
  });

  @override
  List<Object?> get props => [fileUrl, fileName];
}

class UploadMedia extends InspectionMediaEvent {
  final int id;
  final List<File> media; // List of files to be uploaded

  UploadMedia({required this.id, required this.media}); // ✅ Mark required

  @override
  List<Object?> get props => [id, media];
}

class UploadMediaOnTask extends InspectionMediaEvent {
  final int id;
  final List<File> media; // List of files to be uploaded

  UploadMediaOnTask({required this.id, required this.media});
  @override
  List<Object?> get props => [id, media];
}

class SearchMedia extends InspectionMediaEvent {
  final String searchQuery;
  final int? id;

  SearchMedia(this.searchQuery, this.id);

  @override
  List<Object?> get props => [searchQuery];
}
