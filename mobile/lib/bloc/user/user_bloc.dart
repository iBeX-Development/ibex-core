import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/user/user_event.dart';
import 'package:ibex/bloc/user/user_state.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../config/end_points.dart';
import '../../config/strings.dart';
import '../../data/localStorage/hive.dart';
import '../../data/model/user_model.dart';
import '../../data/repositories/user/user_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class UserBloc extends Bloc<UserEvent, UserState> {
  int _offset = 0; // Start with the initial offset
  final int _limit = 15;
  bool _hasReachedMax = false;
  bool _isLoading = false;
  Map<String, dynamic> _filter = {};

  UserBloc() : super(UserInitial()) {
    on<UserList>(_getUserList);
    on<SelectedUser>(_onSelectUser);
    on<UserLoadMore>(_onLoadMore);
    on<ToggleUserSelection>(_onToggleUserSelection);
    on<UsersCreated>(_onCreateUser);
    on<UpdateUsers>(_onUpdateUser);
    on<DeleteUsers>(_onDeleteUser);
    on<SearchUsers>(_onSearchUsers);
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<UserState> emit,
  ) async {
    try {
      if (_isLoading) return; // Avoid triggering search when already loading

      // Set the loading state only for search
      _isLoading = true;
      emit((state as UserPaginated).copyWith(isLoading: true));

      List<User> users = [];
      _offset = 0;
      _hasReachedMax = false;

      Map<String, dynamic> result = await UserRepo().getUsers(
        limit: _limit,
        offset: _offset,
        search: event.searchQuery,
        token: true,
      );

      users = List<User>.from(
        (result['data'] ?? []).map((userData) => User.fromJson(userData)),
      );

      _offset += _limit;
      // Since API doesn't provide total, detect end by checking if we got fewer items than requested
      bool hasReachedMax = users.length < _limit;
      // print(
      //     '_onSearchUsers: users.length=${users.length}, _limit=$_limit, hasReachedMax=$hasReachedMax');
      if (!result.containsKey('error')) {
        emit(
          (state as UserPaginated).copyWith(
            user: users,
            hasReachedMax: hasReachedMax,
            isLoading: false, // Reset loading state for search
          ),
        );
      } else if (result.containsKey('errors')) {
        emit(UserError(result['message'] ?? 'Unknown error occurred'));
      }
    } catch (e) {
      emit(UserError("Error: $e"));
    } finally {
      _isLoading = false; // Reset loading state after search is complete
    }
  }

  Future<void> _getUserList(UserList event, Emitter<UserState> emit) async {
    try {
      _offset = 0; // 🔁 Reset offset for fresh load
      _hasReachedMax = false;
      _isLoading = true;
      _filter = event.filter ?? {};

      emit(UserLoading());

      Map<String, dynamic> result = await UserRepo().getUsers(
        token: true,
        limit: _limit,
        offset: _offset,
        filter: _filter,
      );

      if (!result.containsKey('error')) {
        List<User> users = List<User>.from(
          (result['data'] ?? []).map((userData) => User.fromJson(userData)),
        );

        _offset =
            users.length; // 🔁 Set to number of users fetched (can be < _limit)
        // Since API doesn't provide total, detect end by checking if we got fewer items than requested
        _hasReachedMax = users.length < _limit;

        // for (int i = 0; i < users.length; i++) {
        //   print(
        //       "User $i: id=${users[i].id}, firstName=${users[i].firstName}, lastName=${users[i].lastName}, email=${users[i].email}");
        // }
        emit(
          UserPaginated(
            user: users,
            hasReachedMax: _hasReachedMax,
            isLoading: false,
          ),
        );
      } else {
        emit(UserError(result['message'] ?? 'Unknown error occurred'));
        flutterToastCustom(msg: result['message'] ?? 'Unknown error occurred');
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d("❌ ApiException in _getUserList: $e");
      }
      emit(UserError("Error: $e"));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _onLoadMore(UserLoadMore event, Emitter<UserState> emit) async {
    if (state is! UserPaginated || _hasReachedMax || _isLoading) return;

    _isLoading = true;

    emit((state as UserPaginated).copyWith(isLoading: true));

    try {
      final currentState = state as UserPaginated;
      final List<User> currentUsers = List<User>.from(currentState.user);

      Map<String, dynamic> result = await UserRepo().getUsers(
        token: true,
        limit: _limit,
        offset: _offset,
        search: event.search,
      );

      if (!result.containsKey('error')) {
        List<User> additionalUsers = List<User>.from(
          (result['data'] ?? []).map((userData) => User.fromJson(userData)),
        );

        if (additionalUsers.isEmpty) {
          _hasReachedMax = true;
          if (kDebugMode) {
            logger.d("🔚 No more users to load. Marking hasReachedMax = true");
          }
        } else {
          currentUsers.addAll(additionalUsers);
          _offset += additionalUsers
              .length; // ✅ Add actual fetched count (safer than fixed +10)

          // Since API doesn't provide total, detect end by checking if we got fewer items than requested
          if (additionalUsers.length < _limit) {
            _hasReachedMax = true;
          }
        }

        emit(
          UserPaginated(
            user: currentUsers,
            hasReachedMax: _hasReachedMax,
            isLoading: false,
          ),
        );
      } else {
        emit(UserError(result['message'] ?? 'Unknown error occurred'));
        flutterToastCustom(msg: result['message'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Exception in _onLoadMore: $e");
      }
      emit(UserError("Error: $e"));
    } finally {
      _isLoading = false;
    }
  }

  void _onSelectUser(SelectedUser event, Emitter<UserState> emit) {
    if (state is UserSuccess) {
      final currentState = state as UserSuccess;

      final selectedIndices = List<int>.from(currentState.selectedIndices);
      final selectedUsernames = List<String>.from(
        currentState.selectedUsernames,
      );

      if (selectedIndices.contains(event.selectedIndex)) {
        selectedIndices.remove(event.selectedIndex);
        selectedUsernames.remove(event.selectedTitle);
      } else {
        selectedIndices.add(event.selectedIndex);
        selectedUsernames.add(event.selectedTitle);
      }
      emit(
        UserSuccess(
          user: currentState.user,
          selectedIndices: selectedIndices,
          selectedUsernames: selectedUsernames,
          isLoadingMore: currentState.isLoadingMore,
        ),
      );
    }
  }

  void _onToggleUserSelection(
    ToggleUserSelection event,
    Emitter<UserState> emit,
  ) {
    if (state is UserSuccess) {
      final currentState = state as UserSuccess;

      // Create local copies of selected userIds and usernames to avoid mutation issues
      final updatedSelectedUserIds = List<int>.from(
        currentState.selectedIndices,
      );
      final updatedSelectedUsernames = List<String>.from(
        currentState.selectedUsernames,
      );

      // Check if the userId is already selected
      final isSelected = updatedSelectedUserIds.contains(event.userId);
      if (isSelected) {
        // If selected, find the index of userId and remove it along with the corresponding username
        final removeIndex = updatedSelectedUserIds.indexOf(event.userId);
        updatedSelectedUserIds.removeAt(removeIndex);
        updatedSelectedUsernames.removeAt(removeIndex);
      } else {
        // If not selected, add the userId and corresponding username
        updatedSelectedUserIds.add(event.userId);
        updatedSelectedUsernames.add(event.userName);
      }

      // Emit the updated state with the toggled selection
      emit(
        UserSuccess(
          user: currentState.user,
          selectedIndices: updatedSelectedUserIds,
          selectedUsernames: updatedSelectedUsernames,
          isLoadingMore: currentState.isLoadingMore,
        ),
      );

      // Debugging log for checking the updated usernames
    }
  }

  void _onCreateUser(UsersCreated event, Emitter<UserState> emit) async {
    try {
      emit(UserSuccessCreateLoading());

      FormData formData = FormData.fromMap({
        "id": event.userList.id,
        "first_name": event.userList.firstName,
        "last_name": event.userList.lastName,
        "role": event.userList.role,
        "role_id": event.userList.role,
        // "company":user.company,
        "email": event.userList.email,
        "phone": event.userList.phone,
        "country_code":
            event.userList.phone != null ? event.userList.countryCode : "",
        // "country_iso_code":user.countryIsoCode,
        "password": event.userList.password,
        "password_confirmation": event.userList.passwordConfirmation,
        "type": event.userList.type,
        "address": event.userList.address,
        "dob": event.userList.dob,
        "doj": event.userList.doj,
        "city": event.userList.type,
        "state": event.userList.state,
        "country": event.userList.country,
        "zip": event.userList.zip,
        if (event.image != null)
          'profile': await MultipartFile.fromFile(event.image?.path ?? ''),

        "status": event.userList.status,
        "created_at": event.userList.createdAt,
        "updated_at": event.userList.updatedAt,
        "assigned": event.userList.assigned,
        "require_ev": 0,
      });
      var token = await HiveStorage.getToken();
      var userbox = await Hive.openBox(userBox);
      var workspace = userbox.get(workSpaceId);

      // for (var field in formData.fields) {
      //   print('${field.key}: ${field.value}');
      // }

      final response = await Dio().post(
        createUserUrl,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Replace with actual token if needed
            'Content-Type': 'application/json',
            // Replace with actual token if needed
            'Accept': 'application/json',
            // Replace with actual token if needed
            'workspace-id': '$workspace',
            // Replace with actual token if needed
          },
        ),
      );

      // Ensure result['data'] is a List before mapping
      var result = response.data;

      if (!result.containsKey('error')) {
        emit(UserCreateSuccess());
        // add(UserList());
      } else if (result.containsKey('errors')) {
        emit(UserCreateError(result['message'] ?? 'Unknown error occurred'));
        flutterToastCustom(msg: result['message'] ?? 'Unknown error occurred');
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit(UserError("Error: $e"));
      add(UserList());
    }
  }

  void _onUpdateUser(UpdateUsers event, Emitter<UserState> emit) async {
    try {
      List<User> updatedUser = [];
      emit(UserSuccessEditLoading());
      // Assuming `updateUser` is a method in your `UserRepo` to handle user updates.
      Map<String, dynamic> result = await UserRepo().updateUser(
        user: event.user,
      );
      // updatedUser = List<User>.from(result['data']
      //     .map((projectData) => User.fromJson(projectData)));
      if (!result.containsKey('error')) {
        emit(UserEditSuccess());
        // add(UserList());
      }
      if (result.containsKey('errors')) {
        emit((UserEditError(result['message'] ?? 'Unknown error occurred')));
        flutterToastCustom(msg: result['message'] ?? 'Unknown error occurred');
        // add(UserList());
      }
      emit(UserSuccess(user: updatedUser)); // Emit the updated user
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit(UserError("Error: $e"));
    }
  }

  void _onDeleteUser(DeleteUsers event, Emitter<UserState> emit) async {
    final user = event.userId;
    try {
      Map<String, dynamic> result = await UserRepo().getDeleteUser(
        id: user.toString(),
        token: true,
      );

      if ((result['data'] ?? {})['error'] == false) {
        emit(UserDeleteSuccess());
        add(UserList());
      }

      if ((result['data'] ?? {})['error'] == true) {
        emit((UserDeleteError(result['message'] ?? 'Unknown error occurred')));
        flutterToastCustom(msg: result['message'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      emit((UserError("Error: $e")));
    }
    // }
  }
}
