import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';
import '../../data/localStorage/hive.dart';
import '../../data/repositories/auth/auth_repo.dart';
import '../../routes/routes.dart';
import '../../utils/user_id_mapper.dart';

import 'auth_event.dart';
import 'auth_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  String email = "";
  String password = "";
  String conPassword = "";
  String workspaceTitleUpdated = "";

  String? custom;
  String? guard;
  String? role;
  int? locationId;
  List<int>? teamsIds;

  bool? hasAllDataAccess;
  int? userId;
  int? workspaceIdd;
  bool? isLeaveEditor;
  AuthBloc() : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignUp>(_onSignUp);
    on<WorkspaceUpdate>(_onWorkspaceChange);
    on<AuthSignIn>(_onSignIn);
    on<LoggedOut>(_onLoggedOut);
    on<AuthProgress>(_onAuthProgress);
    on<GetEmail>(_onGetEmail);
    on<GetPassword>(_onGetPassword);
  }

  void _onAuthProgress(AuthProgress event, Emitter<AuthState> emit) async {
    emit(AuthLoadInProgress());
  }

  void _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoadInProgress());
  }

  void _onWorkspaceChange(
    WorkspaceUpdate event,
    Emitter<AuthState> emit,
  ) async {
    workspaceTitleUpdated = event.workspaceTitle!;

    emit(WorkspaceUpdated(workspace: workspaceTitleUpdated));
  }

  void _onGetPassword(GetPassword event, Emitter<AuthState> emit) async {
    password = event.password;
  }

  void _onSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    try {
      var result = await AuthRepository().signUp(
        email: event.email!,
        password: event.password!,
        firstname: event.firstname!,
        lastname: event.lastname!,
        company: event.company!,
        role: event.role!,
        conpassword: event.confirmPass!,
        type: event.type!,
      );
      if (!result.containsKey('error')) {
        emit(AuthSignUpLoadSuccess(user: result));
      } else if (result.containsKey('errors')) {
        emit(AuthSignUpLoadFailure(message: ' ${result['message']}'));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      emit(AuthSignUpLoadFailure(message: e.toString()));
      flutterToastCustom(msg: e.toString());
    }
  }

  void _onSignIn(AuthSignIn event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoadSuccessLoading());

      var result = await AuthRepository().signIn(
        email: email,
        password: password,
      );

      // Check for errors response format
      if (result.containsKey('errors')) {
        // GraphQL error format
        String errorMessage = result['errors'][0]['message'] ?? 'Login failed';
        emit(AuthLoadFailure(message: errorMessage));
        flutterToastCustom(msg: errorMessage);
        return;
      }

      if (result.containsKey('message')) {
        String errorMessage = result['message'].toString();
        emit(AuthLoadFailure(message: errorMessage));
        flutterToastCustom(msg: errorMessage);
        return;
      }

      // Check for success response format
      if (result.containsKey('data') && result['data'] != null) {
        // New response format with access_token
        var data = result['data'];

        if (data.containsKey('access_token')) {
          // Store access token
          String accessToken = data['access_token'];
          HiveStorage.putToken(accessToken);

          var userInfo = await AuthRepository().getUserInfo();

          // Check if getUserInfo failed
          if (userInfo.containsKey('errors')) {
            String errorMessage =
                userInfo['errors'][0]['message'] ?? 'Failed to get user info';
            emit(AuthLoadFailure(message: errorMessage));
            return;
          }

          var userData = userInfo['data'] ?? userInfo;
          if (userData == null || userData.isEmpty) {
            emit(AuthLoadFailure(message: 'Failed to get user information'));
            return;
          }

          // ✅ Safely store user data
          try {
            await HiveStorage.setUserInfoDatas(userData);
            // logger.i("✅ User data stored successfully");
          } catch (e) {
            logger.e("❌ Error storing user data: $e");
            emit(AuthLoadFailure(message: 'Failed to store user data: $e'));
            return;
          }
          String? userIdUuid = userData['id'];
          var roleData = userData['role'];
          var locationData = userData['location_id'];

          // Handle role (might be object or string)
          if (roleData is Map) {
            role = roleData['id']?.toString();

            // Check admin_access to set role name
            int? adminAccess = roleData['admin_access'];
            String roleName = (adminAccess == 1) ? "admin" : "member";
            HiveStorage.setRoleName(roleName);
          } else {
            role = roleData?.toString();
            // If roleData is not a Map, default to member
            HiveStorage.setRoleName("member");
          }

          // Handle location_id
          if (locationData != null) {
            if (locationData is int) {
              locationId = locationData;
            } else if (locationData is String) {
              locationId = int.tryParse(locationData);
            }
          }

          // Convert UUID string to int using mapper
          if (userIdUuid != null) {
            userId = UserIdMapper().getIntId(userIdUuid);
          }

          // Store user info in Hive
          if (userId != null) HiveStorage.setUserId(userId!);
          if (role != null) HiveStorage.setRole(role!);
          if (locationId != null) HiveStorage.setLocationId(locationId!);

          // Extract and store my_teams IDs
          List<int> teamIds = [];
          if (userData['my_teams'] != null && userData['my_teams'] is List) {
            for (var team in userData['my_teams']) {
              if (team is Map && team['id'] != null) {
                teamIds.add(team['id']);
              } else if (team is int) {
                teamIds.add(team);
              }
            }
          }

          // ✅ Always set teams list (even if empty) to clear old data
          teamsIds = teamIds;
          await HiveStorage.setTeamsIdList(teamIds);

          // ✅ Events are dispatched in login_screen.dart after AuthLoadSuccess
          emit(AuthLoadSuccess(user: userData));

          try {
            String? token = Firebase.apps.isEmpty ? null : await FirebaseMessaging.instance.getToken();
            if (token != null) {
              HiveStorage.setFcm(token);
              AuthRepository().createFcmId(fcmId: token);
            }
          } catch (fcmError) {
            logger.e("FCM Error to save on server: $fcmError");
          }
        } else {
          emit(AuthLoadFailure(message: 'Invalid response format'));
        }
      } else if (!result.containsKey('error')) {
        // Old response format
        workspaceIdd = result['data']["workspace_id"];
        workspaceTitleUpdated = result['data']["workspace_title"];
        var userIdValue = result['data']['user_id'];

        // Handle both String UUID and int
        if (userIdValue is String) {
          userId = UserIdMapper().getIntId(userIdValue);
        } else if (userIdValue is int) {
          userId = userIdValue;
        }

        role = result['data']['role'];
        custom = result['token'];
        guard = result['data']['guard'];
        hasAllDataAccess = true;
        // hasAllDataAccess = result['data']['is_admin_or_has_all_data_access'];
        isLeaveEditor = result['data']['is_leave_editor'];

        if (userId != null) HiveStorage.setUserId(userId!);
        HiveStorage.setHasAllDataAccess(hasAllDataAccess!);
        HiveStorage.setRole(role!);
        HiveStorage.getAllDataAccess();
        HiveStorage.getRole();
        HiveStorage.putToken(custom!);
        HiveStorage.setWorkspaceId(workspaceIdd!);

        emit(AuthLoadSuccess(user: result));
      } else if (result.containsKey('errors')) {
        emit(AuthLoadFailure(message: ' ${result['message']}'));
      }
    } catch (e) {
      emit(AuthLoadFailure(message: " Error ${e.toString()}"));
    }
  }

  void _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    await AuthRepository.signOut().then((value) {
      router.go('/login');
    });
    emit(AuthInitial());
    event.onLoggedOutCompleted.call();
  }

  void _onGetEmail(GetEmail event, Emitter<AuthState> emit) async {
    email = event.email;
  }
}
