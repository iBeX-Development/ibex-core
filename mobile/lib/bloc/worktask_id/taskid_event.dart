import 'package:equatable/equatable.dart';

abstract class WorkTaskidEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkTaskIdListId extends WorkTaskidEvent {
  final int? id;

  WorkTaskIdListId(this.id);

  @override
  List<Object?> get props => [id];
}
