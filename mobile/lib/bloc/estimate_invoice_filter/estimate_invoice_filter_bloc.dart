import 'package:bloc/bloc.dart';
import 'estimate_invoice_filter_event.dart';
import 'estimate_invoice_filter_state.dart';

class EstimateInvoiceFilterCountBloc extends Bloc<
    EstimateInvoiceFilterCountEvent, EstimateInvoiceFilterCountState> {
  EstimateInvoiceFilterCountBloc()
      : super(EstimateInvoiceFilterCountState.initial()) {
    on<EstimateInvoiceUpdateFilterCount>(_onUpdateFilterCount);
    on<EstimateInvoiceResetFilterCount>(_onResetFilterCount);
    on<SetClients>(_onSetClients);
    on<SetTypes>(_onSetTypes);
    on<SetUserCreator>(_onSetUserCreator);
    on<SetClientCreator>(_onSetClientCreator);
    on<SetDateEstimate>(_onSetDate);
  }

  void _onUpdateFilterCount(
    EstimateInvoiceUpdateFilterCount event,
    Emitter<EstimateInvoiceFilterCountState> emit,
  ) {
    final updatedFilters = Map<String, bool>.from(state.activeFilters);
    updatedFilters[event.filterType.toLowerCase()] = event.isSelected;

    final newCount = updatedFilters.values.where((isActive) => isActive).length;

    emit(state.copyWith(
      activeFilters: updatedFilters,
      count: newCount,
    ));
  }

  void _onResetFilterCount(
    EstimateInvoiceResetFilterCount event,
    Emitter<EstimateInvoiceFilterCountState> emit,
  ) {
    final resetFilters = {
      'clients': false,
      'type': false,
      'usercreator': false,
      'clientcreator': false,
      'date': false,
    };

    emit(state.copyWith(
      activeFilters: resetFilters,
      count: 0,
      selectedClientIds: [],
      selectedTypeIds: [],
      selectedUserCreatorIds: [],
      selectedClientCreatorIds: [],
      fromDate: "",
      toDate: "",
    ));
  }

  void _onSetClients(
      SetClients event, Emitter<EstimateInvoiceFilterCountState> emit) {
    emit(state.copyWith(selectedClientIds: event.clientIds));
  }

  void _onSetTypes(
      SetTypes event, Emitter<EstimateInvoiceFilterCountState> emit) {
    emit(state.copyWith(selectedTypeIds: event.typeIds));
  }

  void _onSetUserCreator(
      SetUserCreator event, Emitter<EstimateInvoiceFilterCountState> emit) {
    emit(state.copyWith(selectedUserCreatorIds: event.userCreatorIds));
  }

  void _onSetClientCreator(
      SetClientCreator event, Emitter<EstimateInvoiceFilterCountState> emit) {
    emit(state.copyWith(selectedClientCreatorIds: event.clientCreatorIds));
  }

  void _onSetDate(
      SetDateEstimate event, Emitter<EstimateInvoiceFilterCountState> emit) {
    emit(state.copyWith(fromDate: event.fromDate, toDate: event.toDate));
  }
}
