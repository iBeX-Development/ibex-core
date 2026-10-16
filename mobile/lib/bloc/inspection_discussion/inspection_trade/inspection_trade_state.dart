import 'package:equatable/equatable.dart';

import '../../../data/model/inspection/trade.dart';

abstract class InspectionTradeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InspectionTradeInitial extends InspectionTradeState {}

class InspectionTradeWithId extends InspectionTradeState {
  final List<InspectionsTrade> InspectionTrade;

  InspectionTradeWithId(
    this.InspectionTrade,
  );
  @override
  List<Object> get props => [InspectionTrade];
}

class InspectionTradeLoading extends InspectionTradeState {}

class InspectionTradeSuccess extends InspectionTradeState {
  InspectionTradeSuccess(this.InspectionTrade, this.selectedIndex,
      this.selectedTitle, this.isLoadingMore);
  final List<InspectionsTrade> InspectionTrade;
  final int? selectedIndex;
  final String selectedTitle;
  final bool isLoadingMore;

  @override
  List<Object> get props =>
      [InspectionTrade, selectedIndex!, selectedTitle, isLoadingMore];
}

class InspectionTradePaginated extends InspectionTradeState {
  final List<InspectionsTrade> InspectionTrade;
  final bool hasReachedMax;

  InspectionTradePaginated({
    required this.InspectionTrade,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [InspectionTrade, hasReachedMax];
}

class InspectionTradeTradePaginated extends InspectionTradeState {
  final List<InspectionsTrade> InspectionTradeTrade;
  final bool hasReachedMax;

  InspectionTradeTradePaginated({
    required this.InspectionTradeTrade,
    required this.hasReachedMax,
  });

  @override
  List<Object> get props => [InspectionTradeTrade, hasReachedMax];
}

class InspectionTradeError extends InspectionTradeState {
  final String errorMessage;
  InspectionTradeError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionTradeCreateLoading extends InspectionTradeState {}

class InspectionTradeCreateSuccess extends InspectionTradeState {
  final List<InspectionsTrade> createInspectionTrade;
  InspectionTradeCreateSuccess(this.createInspectionTrade);
  @override
  List<Object> get props => [createInspectionTrade];
}

class InspectionTradeEditLoading extends InspectionTradeState {}

class InspectionTradeEditSuccess extends InspectionTradeState {
  final List<InspectionsTrade> editInspectionTrade;
  InspectionTradeEditSuccess(this.editInspectionTrade);
  @override
  List<Object> get props => [editInspectionTrade];
}

class InspectionTradeCreateError extends InspectionTradeState {
  final String errorMessage;
  InspectionTradeCreateError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionTradeEditError extends InspectionTradeState {
  final String errorMessage;
  InspectionTradeEditError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class InspectionTradeDeleteSuccess extends InspectionTradeState {
  InspectionTradeDeleteSuccess();
  @override
  List<Object> get props => [];
}

class InspectionTradeDeleteError extends InspectionTradeState {
  final String errorMessage;
  InspectionTradeDeleteError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
