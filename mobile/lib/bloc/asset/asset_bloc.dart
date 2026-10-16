import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/asset/asset_event.dart';
import 'package:ibex/bloc/asset/asset_state.dart';
import 'package:ibex/data/localStorage/hive.dart';
import 'package:ibex/data/model/asset/asset_model.dart';
import '../../data/repositories/asset/asset_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import '../../utils/user_id_mapper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AssetBloc extends Bloc<AssetEvent, AssetState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 20;
  int? defaultAssetID;
  bool _isLoading = false;
  bool _hasReachedMax = false;
  int? assetspcaId;
  String? assetspcaTitle;
  bool? assetspcaIsSelected;
  int? totalAsset;
  List<int> assetIdList = [];

  AssetBloc() : super(AssetInitial()) {
    on<AssetList>(_getAssetList);
    on<AssetRemove>(_getRemoveFromAsset);
    on<RemoveUSerFromAsset>(_onRemoveUSerFromAsset);
    on<SelectedAsset>(_getSelectedAsset);
    on<LoadMoreAsset>(_onLoadMoreAsset);
    on<AddAsset>(_onAddAsset);
    on<UpdateAsset>(_onAssetupdate);
    on<SearchAsset>(_onSearchAsset);
    on<CreateRemoveAsset>(_onSetAsset);
    on<ToggleAssetSelection>(_onToggleAssetSelection);
  }
  @override
  void onTransition(Transition<AssetEvent, AssetState> transition) {
    super.onTransition(transition);
  }

  Future<void> _onAddAsset(AddAsset event, Emitter<AssetState> emit) async {
    if (state is AssetPaginated) {
      final asset = event.asset;
      final name = asset.name;
      // final userID = asset.userIds;
      // final clientID = asset.clientIds;
      // final teamLeaderIds = asset.teamLeaderIds;

      try {
        emit(AssetCreateSuccessLoading());
        Map<String, dynamic> result = await AssetRepo().createAsset(
          asset: AssetModel(name: name),
        );

        if (!result.containsKey('error')) {
          emit(AssetCreateSuccess());
        }
        if (result.containsKey('errors')) {
          emit((AssetCreateError(result['message'])));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        logger.e('Error while creating Meeting: $e');
        // Optionally, handle the error state
      }
    }
  }

  void _onToggleAssetSelection(
    ToggleAssetSelection event,
    Emitter<AssetState> emit,
  ) {
    if (state is AssetSuccess) {
      final currentState = state as AssetSuccess;

      // Create local copies of selected userIds and usernames to avoid mutation issues
      // final updatedSelectedUserIds = List<int>.from(
      //   currentState.selectedIndices,
      // );
      // final updatedSelectedUsernames = List<String>.from(
      //   currentState.selectedUsernames,
      // );

      // // Check if the userId is already selected
      // final isSelected = updatedSelectedUserIds.contains(event.userId);
      // if (isSelected) {
      //   // If selected, find the index of userId and remove it along with the corresponding username
      //   final removeIndex = updatedSelectedUserIds.indexOf(event.userId);
      //   updatedSelectedUserIds.removeAt(removeIndex);
      //   updatedSelectedUsernames.removeAt(removeIndex);
      // } else {
      //   // If not selected, add the userId and corresponding username
      //   updatedSelectedUserIds.add(event.userId);
      //   updatedSelectedUsernames.add(event.userName);
      // }

      // // Emit the updated state with the toggled selection
      // emit(
      //   AssetSuccess(
      //     user: currentState.user,
      //     selectedIndices: updatedSelectedUserIds,
      //     selectedUsernames: updatedSelectedUsernames,
      //     isLoadingMore: currentState.isLoadingMore,
      //   ),
      // );

      // Debugging log for checking the updated usernames
    }
  }

  void _onAssetupdate(UpdateAsset event, Emitter<AssetState> emit) async {
    if (state is AssetPaginated) {
      final asset = event.asset;
      final id = asset.id;
      final name = asset.name;
      final location = asset.location;

      emit(AssetEditSuccessLoading());

      try {
        Map<String, dynamic> result = await AssetRepo().updateAsset(
          id: id!,
          location: location!,
          name: event.name!,
          description: event.description,
          imageId: event.imageId,
        );

        if (!result.containsKey('error')) {
          emit(AssetEditSuccess());
          String successMsg = event.isTeamUpdate
              ? 'Team updated successfully'
              : 'Asset updated successfully';
          flutterToastCustom(msg: successMsg, color: Colors.green);
        } else if (result.containsKey('errors')) {
          emit(AssetEditError(result['message'] ?? 'Update failed'));
          flutterToastCustom(msg: result['message'] ?? 'Update failed');
        }
      } catch (e) {
        logger.e('Error while updating: $e');
        String errorMsg = event.isTeamUpdate
            ? 'Error updating team: ${e.toString()}'
            : 'Error updating asset: ${e.toString()}';
        emit(AssetEditError(errorMsg));
        flutterToastCustom(msg: errorMsg);
      }
    }
  }

  Future<void> _getAssetList(AssetList event, Emitter<AssetState> emit) async {
    if (_isLoading) {
      return;
    }

    try {
      _isLoading = true;
      _offset = 0;
      _hasReachedMax = false;

      emit(AssetLoading());

      int currentUserId = await HiveStorage.getUserId();
      String currentUserUuid = UserIdMapper().getUuid(currentUserId) ?? '';

      Map<String, dynamic> result = await AssetRepo().assetList(
        offset: _offset,
        limit: _limit,
        fields: "*",
      );

      // ✅ Check for error in response
      if (result.containsKey('error') && result['error'] == true) {
        _isLoading = false;
        _hasReachedMax = true;
        emit(AssetError(result['message'] ?? 'Unknown error'));
        return;
      }

      if (result['data'] != null) {
        List<AssetModel> asset = [];

        for (var projectData in result['data']) {
          try {
            asset.add(AssetModel.fromJson(projectData));
          } catch (e) {
            logger.e("❌ Error parsing asset item: $e");
            // logger.e("❌ Problematic data: $projectData");
            continue;
          }
        }

        // ✅ Get total count from meta
        int? totalCount = result['meta']?['filter_count'];

        // ✅ Calculate hasReachedMax
        if (totalCount != null && totalCount > 0) {
          _hasReachedMax = asset.length >= totalCount;
        } else {
          _hasReachedMax = asset.length < _limit;
        }

        totalAsset = asset.length;
        _offset = asset.length;
        _isLoading = false;

        emit(
          AssetPaginated(
            asset: asset,
            hasReachedMax: _hasReachedMax,
            isLoading: false,
          ),
        );

        // ✅ Verify emitted state
        if (state is AssetPaginated) {
          final s = state as AssetPaginated;
        }
      } else {
        _isLoading = false;
        _hasReachedMax = true;

        emit(AssetPaginated(asset: [], hasReachedMax: true, isLoading: false));
      }

      if (result.containsKey('errors')) {
        _isLoading = false;
        emit(AssetError("${result['message']}"));
      }
    } on ApiException catch (e) {
      logger.e("❌ ApiException: $e");
      logger.e("❌ Stack trace: ${StackTrace.current}");
      _isLoading = false;
      _hasReachedMax = true;
      emit(AssetError("$e"));
    } catch (e, stackTrace) {
      logger.e("❌ Unexpected error: $e");
      logger.e("❌ Stack trace: $stackTrace");
      _isLoading = false;
      _hasReachedMax = true;
      emit(AssetError("$e"));
    } finally {
      if (kDebugMode) {
        logger.i('finally - : $_isLoading, _hasReachedMax: $_hasReachedMax');
      }
    }
  }

  Future<void> _onLoadMoreAsset(
    LoadMoreAsset event,
    Emitter<AssetState> emit,
  ) async {
    final currentState = state;

    if (_isLoading) {
      return;
    }

    if (_hasReachedMax) {
      return;
    }

    if (currentState is! AssetPaginated) {
      return;
    }

    try {
      _isLoading = true;

      // ✅ Emit loading state
      emit(
        AssetPaginated(
          asset: currentState.asset,
          hasReachedMax: false,
          isLoading: true,
        ),
      );

      Map<String, dynamic> result = await AssetRepo().assetList(
        offset: _offset,
        limit: _limit,
        fields: "*",
        search: event.searchQuery,
      );

      if (result['data'] != null) {
        List<AssetModel> newAssets = [];

        for (var assetData in result['data']) {
          try {
            newAssets.add(AssetModel.fromJson(assetData));
          } catch (e) {
            logger.e("❌ Error parsing asset item: $e");
            continue;
          }
        }

        // ✅ Combine with existing assets
        final allAssets = [...currentState.asset, ...newAssets];

        // ✅ Check if we've reached the end
        int? totalCount = result['meta']?['filter_count'] ??
            result['meta']?['total_count'] ??
            result['total_count'] ??
            result['total'] ??
            result['count'];

        // if (totalCount != null && totalCount > newAssets.length) {
        //   // There's definitely more data
        //   _hasReachedMax = false;
        //   print(
        //       '🔥 totalCount ($totalCount) > asset.length (${newAssets.length}): hasReachedMax = false');
        // } else if (newAssets.length < _limit) {
        //   // Got less than limit, no more data
        //   _hasReachedMax = true;
        //   print(
        //       '🔥 asset.length (${newAssets.length}) < limit ($_limit): hasReachedMax = true');
        // } else {
        //   // Assume there might be more data
        //   _hasReachedMax = false;
        //   print('🔥 Assuming more data available: hasReachedMax = false');
        // }

        if (totalCount != null) {
          _hasReachedMax = allAssets.length >= totalCount;
        } else {
          _hasReachedMax = newAssets.length < _limit;
        }

        _offset = allAssets.length;
        _isLoading = false;

        emit(
          AssetPaginated(
            asset: allAssets,
            hasReachedMax: _hasReachedMax,
            isLoading: false,
          ),
        );
      } else {
        _isLoading = false;
        emit(
          AssetPaginated(
            asset: currentState.asset,
            hasReachedMax: true,
            isLoading: false,
          ),
        );
      }
    } catch (e) {
      logger.e('❌ Error loading more assets: $e');
      _isLoading = false;
      emit(
        AssetPaginated(
          asset: currentState.asset,
          hasReachedMax: true,
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onSearchAsset(
    SearchAsset event,
    Emitter<AssetState> emit,
  ) async {
    final currentState = state;

    if (event.searchQuery.isEmpty) {
      // ✅ Reset to initial state
      _offset = 0;
      _hasReachedMax = false;
      _isLoading = false;
      add(AssetList());
      return;
    }

    // ✅ Don't emit AssetLoading, keep current assets visible
    if (currentState is! AssetPaginated) {
      if (kDebugMode) {
        logger.w('⚠️ Current state is not AssetPaginated, fetching initial list');
      }
      add(AssetList());
      return;
    }

    try {
      _isLoading = true;

      // ✅ Emit loading state but keep existing assets
      emit(
        AssetPaginated(
          asset: currentState.asset,
          hasReachedMax: false,
          isLoading: true,
        ),
      );

      Map<String, dynamic> result = await AssetRepo().assetList(
        offset: 0,
        limit: _limit,
        fields: "*",
        search: event.searchQuery,
      );

      if (result['data'] != null) {
        List<AssetModel> assets = [];

        for (var assetData in result['data']) {
          try {
            assets.add(AssetModel.fromJson(assetData));
          } catch (e) {
            logger.e("❌ Error parsing asset item: $e");
            continue;
          }
        }

        int? totalCount = result['meta']?['filter_count'];

        if (totalCount != null && totalCount > assets.length) {
          _hasReachedMax = false;
        } else if (assets.length < _limit) {
          _hasReachedMax = true;
        } else {
          _hasReachedMax = false;
        }

        _offset = assets.length;
        _isLoading = false;

        emit(
          AssetPaginated(
            asset: assets,
            hasReachedMax: _hasReachedMax,
            isLoading: false,
          ),
        );
      } else {
        _isLoading = false;
        emit(AssetPaginated(asset: [], hasReachedMax: true, isLoading: false));
      }
    } catch (e) {
      logger.e('❌ Error searching assets: $e');
      _isLoading = false;
      emit(AssetError(e.toString()));
    }
  }

  Future<void> _onSetAsset(
    CreateRemoveAsset event,
    Emitter<AssetState> emit,
  ) async {
    try {
      int id = event.id;
      await AssetRepo().getAssetPrimary(
        id: id,
        defaultPrimary: event.defaultPrimary,
      );
      assetspcaId = event.id;
      emit(CreatePrimaryAssetSuccess(id));
      add(AssetList());
    } on ApiException catch (e) {
      emit(AssetError("Error: $e"));
    }
  }

  Future<void> _getRemoveFromAsset(
    AssetRemove event,
    Emitter<AssetState> emit,
  ) async {
    final assetspcaId = event.id;
    try {
      await AssetRepo().assetRemove(id: assetspcaId);
      emit(AssetDeleteSuccess());
    } catch (e) {
      logger.e('❌ Error removing asset: $e');
      emit(AssetError(e.toString()));
    }
  }

  Future<void> _onRemoveUSerFromAsset(
    RemoveUSerFromAsset event,
    Emitter<AssetState> emit,
  ) async {
    final assetspcaId = event.id;
    try {
      await AssetRepo().assetRemove(id: assetspcaId);
    } catch (e) {
      emit(AssetError(e.toString()));
    }
  }

  Future<void> _getSelectedAsset(
    SelectedAsset event,
    Emitter<AssetState> emit,
  ) async {
    try {
      assetspcaId = event.id;
      assetspcaTitle = event.title;
      assetspcaIsSelected = event.isSelected;
    } catch (e) {
      logger.e('❌ Error selecting asset: $e');
      emit(AssetError(e.toString()));
    }
  }

  bool _isFetching = false; // Add a flag to prevent concurrent executions
}
