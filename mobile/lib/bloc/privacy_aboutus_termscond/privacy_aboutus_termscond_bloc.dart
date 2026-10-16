import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/Setting/setting_repo.dart';

import '../../utils/widgets/toast_widget.dart';
import 'privacy_aboutus_termscond_event.dart';
import 'privacy_aboutus_termscond_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class PrivacyAboutusTermsCondBloc
    extends Bloc<ActivityLogEvent, PrivacyAboutusTermsCondState> {
  PrivacyAboutusTermsCondBloc() : super(PriInitial()) {
    on<PrivacyPolicy>(_onUpdatePrivacyPolicy);
    on<GetPrivacyPolicy>(_getPrivacyPolicy);
    on<GetAboutUs>(_getAbouUs);
    on<AbouUs>(_onUpdateAbouUs);
    on<TermsAndCondition>(_onUpdateTermsAndCondition);
    on<GetTermsAndCondition>(_getTermsAndCondition);
  }

  Future<void> _onUpdatePrivacyPolicy(
      PrivacyPolicy event, Emitter<PrivacyAboutusTermsCondState> emit) async {
    try {
      emit(PriLoading());
      Map<String, dynamic> result = await SettingRepo().privacyPolicyUpdate(
          privacyPolicy: event.privacyPolicyText, from: "privacypolicy");

      if (!result.containsKey('errors')) {
        emit(PrivacyUpdatedSuccess(result['data']['value']));
      }
      if (result.containsKey('errors')) {
        emit((PrivacyUpdatedError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((PrivacyUpdatedError("Error: $e")));
    }
  }

  Future<void> _getPrivacyPolicy(GetPrivacyPolicy event,
      Emitter<PrivacyAboutusTermsCondState> emit) async {
    try {
      String privacypolicy = "";
      emit(PriLoading());
      Map<String, dynamic> result = await SettingRepo().privacyPolicy();
      // print(";privacyPolicy $result");
      // .containsKey('error'
      if (!result.containsKey('errors')) {
        // Find the privacy_policy item in the data array
        List<dynamic> dataList = result['data'] ?? [];
        for (var item in dataList) {
          if (item['variable'] == 'privacy_policy') {
            // Parse the JSON string in the value field
            try {
              var valueJson = jsonDecode(item['value']);
              privacypolicy = valueJson['privacy_policy'] ?? "";
            } catch (e) {
              privacypolicy = item['value'] ?? "";
            }
            break;
          }
        }
        emit(PrivacyPolicyValue(privacypolicy));
      }
      if (result.containsKey('errors')) {
        emit((PrivacyUpdatedError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((CommonError("Error: $e")));
    }
  }

  Future<void> _getTermsAndCondition(GetTermsAndCondition event,
      Emitter<PrivacyAboutusTermsCondState> emit) async {
    try {
      String termsAndConditions = "";
      emit(PriLoading());
      Map<String, dynamic> result = await SettingRepo().termsAndConditions();
      // print("termsAndConditions $result");
      if (!result.containsKey('errors')) {
        // Find the terms_conditions item in the data array
        List<dynamic> dataList = result['data'] ?? [];
        for (var item in dataList) {
          if (item['variable'] == 'terms_conditions') {
            // Parse the JSON string in the value field
            try {
              var valueJson = jsonDecode(item['value']);
              termsAndConditions = valueJson['terms_conditions'] ?? "";
            } catch (e) {
              termsAndConditions = item['value'] ?? "";
            }
            break;
          }
        }
        emit(TermsAndConditionValue(termsAndConditions));
      }
      if (result.containsKey('errors')) {
        emit((TermsAndConditionError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((CommonError("Error: $e")));
    }
  }

  Future<void> _getAbouUs(
      GetAboutUs event, Emitter<PrivacyAboutusTermsCondState> emit) async {
    try {
      String aboutUs = "";
      emit(PriLoading());
      Map<String, dynamic> result = await SettingRepo().aboutUs();
      // print("aboutUs $result");
      if (!result.containsKey('errors')) {
        // Find the about_us item in the data array
        List<dynamic> dataList = result['data'] ?? [];
        for (var item in dataList) {
          if (item['variable'] == 'about_us') {
            // Parse the JSON string in the value field
            try {
              var valueJson = jsonDecode(item['value']);
              aboutUs = valueJson['about_us'] ?? "";
            } catch (e) {
              aboutUs = item['value'] ?? "";
            }
            break;
          }
        }
        emit(AboutUsValue(aboutUs));
      }
      if (result.containsKey('errors')) {
        emit((AboutUsError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((CommonError("Error: $e")));
    }
  }

  Future<void> _onUpdateAbouUs(
      AbouUs event, Emitter<PrivacyAboutusTermsCondState> emit) async {
    try {
      emit(PriLoading());
      Map<String, dynamic> result = await SettingRepo().privacyPolicyUpdate(
          privacyPolicy: event.abouUsText, from: "aboutus");

      if (!result.containsKey('errors')) {
        emit(AboutUsUpdatedSuccess(result['data']['value']));
      }
      if (result.containsKey('errors')) {
        emit((PrivacyUpdatedError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((PrivacyUpdatedError("Error: $e")));
    }
  }

  Future<void> _onUpdateTermsAndCondition(TermsAndCondition event,
      Emitter<PrivacyAboutusTermsCondState> emit) async {
    try {
      emit(PriLoading());
      Map<String, dynamic> result = await SettingRepo().privacyPolicyUpdate(
          privacyPolicy: event.termsAndConditionText, from: "terms");

      if (!result.containsKey('errors')) {
        emit(TermsAndConditionsUpdatedSuccess(result['data']['value']));
      }
      if (result.containsKey('errors')) {
        emit((PrivacyUpdatedError(result['message'])));
        flutterToastCustom(msg: result['message']);
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d(e);
      }
      emit((PrivacyUpdatedError("Error: $e")));
    }
  }
}
