import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/single_client/single_client_event.dart';
import 'package:ibex/bloc/single_client/single_client_state.dart';
import 'package:ibex/data/model/clients/all_client_model.dart';

import '../../data/repositories/clients/client_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class SingleClientBloc extends Bloc<SingleClientEvent, SingleClientState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 15;

  bool _hasReachedMax = false;
  SingleClientBloc() : super(SingleClientInitial()) {
    on<SingleClientList>(_getSingleClientList);
    on<SelectedSingleClient>(_onSelectSingleClient);
    on<SingleClientLoadMore>(_onLoadMoreSingleClients);
  }
  Future<void> _getSingleClientList(
    SingleClientList event,
    Emitter<SingleClientState> emit,
  ) async {
    try {
      _offset = 0; // Reset offset for the initial load
      _hasReachedMax = false;
      List<AllClientModel> singleClients = [];
      Map<String, dynamic> result = await ClientRepo().getClients(
        token: true,
        limit: _limit,
        offset: _offset,
      );
      singleClients = List<AllClientModel>.from(
        result['data'].map(
          (projectData) => AllClientModel.fromJson(projectData),
        ),
      );
      _offset += _limit;
      _hasReachedMax = singleClients.length >= result['total'];
      if (!result.containsKey('error')) {
        emit(SingleClientSuccess(singleClients, -1, '', _hasReachedMax));
      }
      if (result.containsKey('errors')) {
        emit((SingleClientError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((SingleClientError("Error: $e")));
    }
  }

  Future<void> _onLoadMoreSingleClients(
    SingleClientLoadMore event,
    Emitter<SingleClientState> emit,
  ) async {
    // Check if the current state is SingleClientSuccess before proceeding
    if (state is SingleClientSuccess) {
      final currentState = state as SingleClientSuccess;

      // Log the current offset to track pagination

      try {
        // Fetch more SingleClientes from the repository
        Map<String, dynamic> result = await ClientRepo().getClients(
          limit: _limit,
          offset: _offset,
          search: '',
          token: true,
        );

        // Convert the fetched data into a list of SingleClientes
        List<AllClientModel> moreSingleClientes = List<AllClientModel>.from(
          result['data'].map(
            (projectData) => AllClientModel.fromJson(projectData),
          ),
        );

        // Update the offset after successfully loading more SingleClientes
        _offset += moreSingleClientes.length;

        // Check if more loading is needed based on the total available SingleClientes
        if (currentState.singleClient.length >= result['total']) {
          _hasReachedMax = true;
        } else {
          _hasReachedMax = false;
        }

        if (!result.containsKey('error')) {
          // Emit the new state with the updated list of SingleClientes
          emit(
            SingleClientSuccess(
              [...currentState.singleClient, ...moreSingleClientes],
              currentState.selectedIndex,
              currentState.selectedTitle,
              _hasReachedMax,
            ),
          );
        } else {
          // Emit an error state if there is an issue with the response
          emit(SingleClientError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } on ApiException catch (e) {
        // Log the error for debugging
        if (kDebugMode) {
          logger.d("API Exception: $e");
        }

        // Emit an error state with the exception message
        emit(SingleClientError("Error: $e"));
      } catch (e) {
        // Catch any other exceptions
        if (kDebugMode) {
          logger.d("Unexpected error: $e");
        }

        emit(SingleClientError("Unexpected error occurred."));
      }
    }
  }

  void _onSelectSingleClient(
    SelectedSingleClient event,
    Emitter<SingleClientState> emit,
  ) {
    if (state is SingleClientSuccess) {
      final currentState = state as SingleClientSuccess;
      emit(
        SingleClientSuccess(
          currentState.singleClient,
          event.selectedIndex,
          event.selectedTitle,
          false,
        ),
      );
    }
  }
}
