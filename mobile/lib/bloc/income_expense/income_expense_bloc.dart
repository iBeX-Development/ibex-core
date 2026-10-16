import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:ibex/data/repositories/income_expense/income_expense_repo.dart';
import '../../api_helper/api.dart';
import '../../data/model/income_expense/income_expense_model.dart';
import 'income_expense_event.dart';
import 'income_expense_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ChartBloc extends Bloc<ChartEvent, ChartState> {
  final Dio dio = Dio();

  ChartBloc() : super(ChartInitial()) {
    on<FetchChartData>(_onIncomeExpenseData);
  }
  Future<void> _onIncomeExpenseData(
    FetchChartData event,
    Emitter<ChartState> emit,
  ) async {
    try {
      Map<String, dynamic> result = await IncomeExpenseRepo().getIncomeExpense(
        token: true,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      ChartDataModel chartData = ChartDataModel.fromJson(result);
      emit(ChartLoaded(chartData));
    } on ApiException catch (e) {
      logger.e('API Exception: $e');
      emit((ChartError("Error: $e")));
    }
  }
}
