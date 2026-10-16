import 'package:equatable/equatable.dart';

abstract class InspectionidEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionIdListId extends InspectionidEvent {
  final int? id;

  InspectionIdListId(this.id);

  @override
  List<Object?> get props => [id];
}
