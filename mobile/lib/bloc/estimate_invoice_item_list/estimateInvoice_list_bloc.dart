import 'package:bloc/bloc.dart';

import '../../data/model/finance/estimate_invoices_model.dart';
import 'estimateInvoice_list_event.dart';
import 'estimateInvoice_list_state.dart';

class ItemInvoiceBloc extends Bloc<ItemEvent, ItemState> {
  ItemInvoiceBloc() : super(ItemState(itemsPerInvoice: {})) {
    final Set<int> clearedEstimateIds = {};

    on<AddItemEvent>((event, emit) {
      final estimateId = event.estimateInvoiceId;

      final currentItems = state.itemsPerInvoice[estimateId] ?? [];

      // ✅ Check for duplicate
      final exists = currentItems.any((item) => item.id == event.newItem.id);
      if (exists) {
        return;
      }

      // ✅ Clear only once for this estimateId
      final updatedMap =
          Map<int, List<InvoicesItems>>.from(state.itemsPerInvoice);
      if (!clearedEstimateIds.contains(estimateId)) {
        updatedMap[estimateId] = [];
        clearedEstimateIds.add(estimateId);
      }

      // ✅ Add new item
      final updatedItems = [event.newItem, ...?updatedMap[estimateId]];
      updatedMap[estimateId] = updatedItems;
      emit(state.copyWith(itemsPerInvoice: updatedMap));
    });

    on<EditItemEvent>((event, emit) {
      final currentItems = state.itemsPerInvoice[event.estimateInvoiceId] ?? [];

      final updatedList = currentItems.map((item) {
        if (item.id.toString() == event.id.toString()) {
          return event.updatedItem;
        }
        return item;
      }).toList();

      final updatedMap =
          Map<int, List<InvoicesItems>>.from(state.itemsPerInvoice);
      updatedMap[event.estimateInvoiceId] = updatedList;

      emit(state.copyWith(itemsPerInvoice: updatedMap));
    });

    on<RemoveItemEvent>((event, emit) {
      final currentItems = state.itemsPerInvoice[event.estimateInvoiceId] ?? [];

      // Remove the item with the matching itemId
      final updatedList =
          currentItems.where((item) => item.id != event.itemId).toList();

      final updatedMap =
          Map<int, List<InvoicesItems>>.from(state.itemsPerInvoice);
      updatedMap[event.estimateInvoiceId] = updatedList;

      // If the list is empty, optionally remove the estimateId key from the map
      if (updatedList.isEmpty) {
        updatedMap.remove(event.estimateInvoiceId);
      }

      emit(state.copyWith(itemsPerInvoice: updatedMap));
    });
  }
}
