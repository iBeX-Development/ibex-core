import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:ibex/bloc/profile_picture/profile_pic_event.dart';
import 'package:ibex/bloc/profile_picture/profile_pic_state.dart';

import '../../config/colors.dart';
import '../../config/strings.dart';
import '../../data/repositories/Profile/profile_repo.dart';
import '../../utils/widgets/toast_widget.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ProfilePicBloc extends Bloc<ProfilePicEvent, ProfilePicState> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage; // State variable to store the selected image file
  String? storedProfilePic;
  ProfilePicBloc() : super(ImagePickerInitial()) {
    on<PickImageFromGallery>(_onPickImageFromGallery);
    on<PickImageFromCamera>(_onPickImageFromCamera);
    on<ShowImage>(_onShowPic);

    _loadSavedImage();
  }

  // Getter to retrieve the saved image
  File? get selectedImage => _selectedImage;

  Future<void> _onPickImageFromGallery(
    PickImageFromGallery event,
    Emitter<ProfilePicState> emit,
  ) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    emit(ImagePickerLoading());
    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      await getImage(_selectedImage!.path);
      var box = await Hive.openBox(userBox);
      storedProfilePic = box.get('profilepic');
      var userbox = await Hive.openBox(userBox);
      var id = userbox.get("user_id");
      // var role = context.read<AuthBloc>().role;
      // getImage();
      Map<String, dynamic> result = await ProfileRepo().updateProfile(
        profile: _selectedImage!,
        type: "user",
        id: id,
      );
      if (kDebugMode) {
        logger.d("error: ${result['data']['error']}");
      }
      if (kDebugMode) {
        logger.d("message: ${result['data']['message']}");
      }
      if (result['data']['error'] == false) {
        emit(ImagePickerSuccess(_selectedImage!));
        Fluttertoast.showToast(
          msg: "updated successfully",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
        );
      } else if (result['data']['error'] == true) {
        // print("rftghuyjikol ${result['message']}");
        emit(ImagePickerFailure(' ${result['data']['message']}'));
        flutterToastCustom(msg: result['data']['message']);
      }
    } else {
      emit(ImagePickerFailure('No image selected'));
    }
  }

  Future<void> _onPickImageFromCamera(
    PickImageFromCamera event,
    Emitter<ProfilePicState> emit,
  ) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    emit(ImagePickerLoading());
    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      await getImage(selectedImage!.path);

      var userbox = await Hive.openBox(userBox);
      var id = userbox.get("user_id");
      Map<String, dynamic> result = await ProfileRepo().updateProfile(
        profile: _selectedImage!,
        type: "user",
        id: id,
      );

      if (result['data']['error'] == false) {
        emit(ImagePickerSuccess(_selectedImage!));
        Fluttertoast.showToast(
          msg: "updated successfully",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
        );
      } else if (result['data']['error'] == true) {
        logger.e("Update profile error: ${result['data']['message']}");
        emit(ImagePickerFailure(' ${result['data']['message']}'));
        flutterToastCustom(msg: result['data']['message']);
      }
      // Use the stored role instead of accessing context after async
      // await ProfileRepo().updateProfile(
      //     profile: _selectedImage!, type: "user", id: id
      // );

      // emit(ImagePickerSuccess(selectedImage!));
    } else {
      emit(ImagePickerFailure('No image selected'));
    }
  }

  Future<void> _onShowPic(
    ShowImage event,
    Emitter<ProfilePicState> emit,
  ) async {
    if (storedProfilePic != null) {
      File imageFile = File(storedProfilePic!); // Convert string to File
      if (await imageFile.exists()) {
        // Check if the file exists
        emit(ImagePickerSuccess(imageFile));
      } else {
        emit(ImagePickerFailure('File does not exist'));
      }
    } else {
      emit(ImagePickerFailure('No image stored'));
    }
  }

  Future<void> _loadSavedImage() async {
    var box = await Hive.openBox(userBox);
    final imagePath = await box.get('profilepic');
    if (kDebugMode) {
      logger.d("PROFILE Image $imagePath");
    }
    if (imagePath != null) {
      _selectedImage = File(imagePath);
      // add(LoadSavedImage());
      if (kDebugMode) {
        logger.d("Selected image: $_selectedImage");
      }
    }
  }

  Future<void> getImage(String profile) async {
    var box = await Hive.openBox(userBox);
    await box.put('profilepic', profile);
  }
}
