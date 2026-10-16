import 'package:equatable/equatable.dart';

import '../../../data/model/work/trade.dart';

abstract class WorkTradeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkTradeInitial extends WorkTradeState {}

class WorkTradeWithId extends WorkTradeState {
  final List<WorksTrade> WorkTrade;

  WorkTradeWithId(
    this.WorkTrade,
  );
  @override
  List<Object> get props => [WorkTrade];
}

class WorkTradeLoading extends WorkTradeState {}

class WorkTradeSuccess extends WorkTradeState {
  WorkTradeSuccess(this.WorkTrade, this.selectedIndex, this.selectedTitle,
      this.isLoadingMore);
  final List<WorksTrade> WorkTrade;
  final int? selectedIndex;
  final String selectedTitle;
  final bool isLoadingMore;

  @override
  List<Object> get props =>
      [WorkTrade, selectedIndex!, selectedTitle, isLoadingMore];
}

class WorkTradePaginated extends WorkTradeState {
  final List<WorksTrade> WorkTrade;
  final bool hasReachedMax;

  WorkTradePaginated({
    required this.WorkTrade,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [WorkTrade, hasReachedMax];
}

class WorkTradeTradePaginated extends WorkTradeState {
  final List<WorksTrade> WorkTradeTrade;
  final bool hasReachedMax;

  WorkTradeTradePaginated({
    required this.WorkTradeTrade,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [WorkTradeTrade, hasReachedMax];
}

class WorkTradeError extends WorkTradeState {
  final String errorMessage;
  WorkTradeError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkTradeCreateLoading extends WorkTradeState {}

class WorkTradeCreateSuccess extends WorkTradeState {
  final List<WorksTrade> createWorkTrade;
  WorkTradeCreateSuccess(this.createWorkTrade);
  @override
  List<Object> get props => [createWorkTrade];
}

class WorkTradeEditLoading extends WorkTradeState {}

class WorkTradeEditSuccess extends WorkTradeState {
  final List<WorksTrade> editWorkTrade;
  WorkTradeEditSuccess(this.editWorkTrade);
  @override
  List<Object> get props => [editWorkTrade];
}

class WorkTradeCreateError extends WorkTradeState {
  final String errorMessage;
  WorkTradeCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkTradeEditError extends WorkTradeState {
  final String errorMessage;
  WorkTradeEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class WorkTradeDeleteSuccess extends WorkTradeState {
  WorkTradeDeleteSuccess();
  @override
  List<Object> get props => [];
}

class WorkTradeDeleteError extends WorkTradeState {
  final String errorMessage;
  WorkTradeDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
