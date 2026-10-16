import 'package:equatable/equatable.dart';

abstract class WorkidEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkIdListId extends WorkidEvent {
  final int? id;

  WorkIdListId(this.id);

  @override
  List<Object?> get props => [id];
}
