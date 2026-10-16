import 'dart:async';
import 'package:hive/hive.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ibex/bloc/user_profile/user_profile_event.dart';
import 'package:ibex/bloc/user_profile/user_profile_state.dart';
import 'package:ibex/config/constants.dart';
import '../../config/strings.dart';
import '../../data/model/user_profile/user_profile.dart';
import '../../data/repositories/Profile/profile_repo.dart';
import '../../api_helper/api.dart';
import '../../utils/widgets/toast_widget.dart';
import '../../utils/user_id_mapper.dart';
import '../../utils/role_id_mapper.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  String? profilePic;
  int? userId;
  String? firstname;
  String? lastName;
  String? email;
  String? role;
  int? roleId;
  String? address;
  String? city;
  String? phone;
  String? country;
  String? countryCode;
  String? password;
  String? conPassword;
  String? countryIsoCode;
  UserProfileBloc() : super(UserProfileInitial()) {
    on<ProfileList>(_getProfileList);
    on<ProfileDetailsUpdateList>(_onUpdateProfile);
    on<ProfileListGet>(_getProfileListGet);
  }
  String? get selectedImage => profilePic;
  Future<void> _getProfileList(
    ProfileList event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      var box = await Hive.openBox(userBox);
      var id = box.get('user_id');

      List<ProfileModel> profile = [];
      Map<String, dynamic> result = await ProfileRepo().getProfile(
        token: true,
        id: id.toString(),
      );

      profile = List<ProfileModel>.from(
        result['data'].map((projectData) => ProfileModel.fromJson(projectData)),
      );
      // String photo =  profile.first.photo!;
      //
      //  box.put("photo", photo);
      // var  Photo=  await box.get("photo");
      for (var photo in profile) {
        profilePic = photo.profile;
        var box = await Hive.openBox(userBox);
        await box.put('profilepic', profilePic);
      }
      if (!result.containsKey('error')) {
        emit(UserProfileSuccess(profile));
      }
      if (result.containsKey('errors')) {
        emit((UserProfileError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((UserProfileError("Error: $e")));
    }
  }

  Future<void> _getProfileListGet(
    ProfileListGet event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      emit(UserProfileLoading());

      List<ProfileModel> profile = [];
      Map<String, dynamic> result = await ProfileRepo().getUserProfileDetails();

      // Handle userId - convert UUID string to int
      var userIdValue = result['data']['id'];
      if (userIdValue is String) {
        userId = UserIdMapper().getIntId(userIdValue);
      } else if (userIdValue is int) {
        userId = userIdValue;
      }

      firstname = result['data']['first_name'];
      lastName = result['data']['last_name'];
      email = result['data']['email'];
      // Keep existing address and city if server doesn't return them
      if (result['data'].containsKey('address') &&
          result['data']['address'] != null) {
        address = result['data']['address'];
      }
      if (result['data'].containsKey('city') &&
          result['data']['city'] != null) {
        city = result['data']['city'];
      }
      role = "member";

      // Handle role - convert UUID string to int if needed
      var roleValue = result['data']['role'];
      if (roleValue is String) {
        if (roleValue.contains('-')) {
          roleId = RoleIdMapper().getIntId(roleValue);
        } else {
          roleId = 0; // Default for non-UUID role names
        }
      }

      // Handle avatar - build full URL if UUID is provided
      var avatarValue = result['data']['avatar'];
      if (avatarValue != null && avatarValue is String) {
        // Check if it's a UUID (contains hyphens and doesn't start with http)
        if (avatarValue.contains('-') && !avatarValue.startsWith('http')) {
          profilePic = '$activePictureUrl/$avatarValue';
        } else {
          // Already a full URL or other format
          profilePic = avatarValue;
        }
      } else {
        profilePic = null;
      }

      countryIsoCode = result['data']['location_id'].toString();
      countryCode = result['data']['location'];
      phone = result['data']['phone'] ?? "phoneNumber";
      password = result['data']['password'];
      conPassword = result['data']['password_confirmation'] ?? "";
      if (result.containsKey('errors')) {
        emit((UserProfileError(result['message'])));
        flutterToastCustom(msg: result['message']);
        return;
      } else if (result.containsKey('data')) {
        // print("Role - profile: $profile ");

        emit(UserProfileSuccess(profile));
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((UserProfileError("Error: $e")));
    }
  }

  void _onUpdateProfile(
    ProfileDetailsUpdateList event,
    Emitter<UserProfileState> emit,
  ) async {
    if (state is UserProfileSuccess) {
      emit(UserProfileLoading());
      // print("_onUpdateProfile ${event.firstname}");
      // print("_onUpdateProfile ${event.lastname}");
      // print("_onUpdateProfile ${event.email}");
      // print("_onUpdateProfile ${event.phone}");

      try {
        Map<String, dynamic> result = await ProfileRepo().updateProfileDeatils(
          firstname: event.firstname,
          lastname: event.lastname,
          email: event.email,
          address: event.address ?? '',
          countryCode: event.countryCode ?? '',
          countryIsoCode: event.countryIsoCode ?? '',
          phone: event.phone ?? '',
          password: event.password,
          conPassword: event.conPassword,
          city: event.city ?? '',
        );
        if (!result.containsKey('errors')) {
          // Update bloc instance variables with new values
          firstname = event.firstname;
          lastName = event.lastname;
          email = event.email;
          roleId = event.role;
          address = event.address;
          city = event.city;
          phone = event.phone;
          countryCode = event.countryCode;
          countryIsoCode = event.countryIsoCode;
          if (event.password != null && event.password!.isNotEmpty) {
            password = event.password;
          }
          if (event.conPassword != null && event.conPassword!.isNotEmpty) {
            conPassword = event.conPassword;
          }

          emit(UserDetailUpdateSuccess());
          add(ProfileListGet());
        }
        if (result.containsKey('errors')) {
          emit((UserDetailUpdateError(result['message'])));

          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating profile: $e');
        }
        // Optionally, handle the error state, e.g., emit an error state
      }
    }
  }
}
