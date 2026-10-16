import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:ibex/bloc/setting/settings_event.dart';
import 'package:ibex/data/repositories/Setting/setting_repo.dart';
import '../../data/model/settings/timezone_model.dart';
import '../../utils/widgets/toast_widget.dart';
import 'settings_state.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  String? currencySymbol;
  String? currencyPosition;
  String? currencyFormat;
  String? decimalPoints;
  String? dateformat;
  String? comapanyTitle;
  String? currencyFullForm;
  String? currencyCode;
  String? decimalPointsInCurrency;
  String? timeZone;
  String? timeFormat;
  String? fullLogo;
  String? halfLogo;
  String? favicon;
  int? allowSignup;
  String? maxAllowedUplaodSize;
  String? maxAttempts;
  String? lockTime;
  String? allowedFileTypes;
  String? siteUrl;
  String? maxFiles;
  int? upcomingAnniversary;
  int? membersOnLeave;
  int? upcomingBirthdays;
  String? email;
  String? phone;
  String? address;
  String? city;
  String? stateOfComapny;
  String? country;
  String? website;
  String? zipcode;
  String? vatNumber;
  String? companyEmail;
  String? emailPasswordSetting;
  String? smtpHost;
  String? smtpPort;
  String? emailContentType;
  String? smtpEncryption;
  String? baseUrl;
  String? mediaStorageType;
  String? s3Key;
  String? s3Secret;
  String? s3Region;
  String? s3Bucket;
  String? whatsappAccessToken;
  String? whatsappPhoneNumberId;
  String? authorization;
  String? bodyFrom;
  String? bodyTo;
  String? body;
  String? messagingAuthorization;
  Map<String, String>? headerData;
  Map<String, String>? bodyFormData;
  Map<String, String>? paramsData;
  List<Map<String, String>> headerDataList = [];
  List<Map<String, String>> bodyFormDataList = [];
  List<TimeZoneInfoModel> timeZoneList = [];
  List<Map<String, String>> paramDataList = [];
  String? mediaStorage;
  String? method;
  String? slackBotToken;
  SettingsBloc() : super(SettingsInitial()) {
    on<SettingsList>(_getListOfSettings);
    on<UpdateSettingsSmsHeader>(_onUpdateSettingsSmsHeader);
    on<UpdateSettingsWhatsApp>(_onUpdateSettingsWhatsApp);
    on<UpdateSettingsSlack>(_onUpdateSettingsSlack);
    on<UpdateSettingsMediaStorage>(_onUpdateSettingsMediaStorage);
    on<UpdateGeneralSettings>(_onUpdateGeneralSettings);
    on<UpdateSettingsSecurity>(_onUpdateSettingsSecurity);
    on<UpdateSettingsCompanyInfo>(_onUpdateSettingsCompanyInfo);
    on<UpdateSettingsEmail>(_onUpdateSettingsEmail);
  }
  void _onUpdateSettingsCompanyInfo(
    UpdateSettingsCompanyInfo event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsSuccess) {
      emit(HeaderSettingEditSuccessLoading());
      try {
        Map<String, dynamic> result =
            await SettingRepo().companyInformationUpdate(
          email: event.companyEmail,
          phoneNumber: event.companyPhone,
          vatNumber: event.companyVat,
          address: event.companyAddress,
          city: event.companyCity,
          state: event.companyState,
          country: event.companyCountry,
          zipCode: event.companyZip,
        );

        if (!result.containsKey('error')) {
          emit(UpdateCompanyInfoSetting()); // Emit success state
        } else {
          emit(ComapnyInformationSettingsEditError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating security settings: $e');
        }
        emit(
          SettingsError('An error occurred while updating security settings'),
        );
      }
    }
  }

  void _onUpdateSettingsEmail(
    UpdateSettingsEmail event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsSuccess) {
      emit(UpdateEmailSettingLoadingSuccess());
      try {
        Map<String, dynamic> result = await SettingRepo().emailUpdate(
          email: event.email,
          password: event.password,
          smtpEncyption: event.smtpEncryption,
          smtpPort: event.smtpPort,
          smtpHost: event.smtpHost,
          emailContentType: event.emailContentType,
        );

        if (!result.containsKey('error')) {
          emit(UpdateEmailSettingSuccess()); // Emit success state
        } else {
          emit(UpdateEmailSettingError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating security settings: $e');
        }
        emit(
          SettingsError('An error occurred while updating security settings'),
        );
      }
    }
  }

  void _onUpdateSettingsSecurity(
    UpdateSettingsSecurity event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsSuccess) {
      emit(HeaderSettingEditSuccessLoading());
      try {
        Map<String, dynamic> result = await SettingRepo().securitySettingUpdate(
          maxAttempt: event.maxAttempt,
          lockTime: event.lockTime,
          allowMaxUploadSize: event.allowMaxUploadSize,
          maxFilesAllowed: event.maxFilesAllowed,
          allowedFileType: event.allowedFileType,
          isAllowedSignUP: event.isAllowedSignUP,
        );

        if (!result.containsKey('error')) {
          emit(UpdateSecuritySetting()); // Emit success state
        } else {
          emit(SecuritySettingsEditError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating security settings: $e');
        }
        emit(
          SecuritySettingsEditError(
            'An error occurred while updating security settings',
          ),
        );
      }
    }
  }

  void _onUpdateGeneralSettings(
    UpdateGeneralSettings event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsSuccess) {
      emit(HeaderSettingEditSuccessLoading());
      try {
        Map<String, dynamic> result = await SettingRepo().generalSettingUpdate(
          title: event.title,
          siteUrl: event.siteUrl,
          fullLogo: event.fullLogo,
          favicon: event.favicon,
          currencyFullForm: event.currencyFullForm,
          currencySymbol: event.currencySymbol,
          timezone: event.timezone,
          currencyCode: event.currencyCode,
          currencySymbolPosition: event.currencySymbolPosition,
          currencyFormat: event.currencyFormat,
          decimalPoints: event.decimalPoints,
          dateFormat: event.dateFormat,
          timeFormat: event.timeFormat,
          birthdaySec: event.birthdaySec,
          workanniversarySec: event.workAnniversarySec,
          leaveReqSec: event.leaveReqSec,
        );

        if (!result.containsKey('error')) {
          emit(UpdateGeneralSetting());
        } else {
          emit(GeneralSettingsEditError(result['message']));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating Task: $e');
        }
        emit(
          GeneralSettingsEditError('An error occurred while updating settings'),
        );
      }
    }
  }

  void _onUpdateSettingsSmsHeader(
    UpdateSettingsSmsHeader event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsSuccess) {
      emit(HeaderSettingEditSuccessLoading());
      try {
        Map<String, dynamic> result = await SettingRepo().settingUpdate(
          event.smsModel,
        );
        if (!result.containsKey('error')) {
          emit(SettingsHeaderUpdated(smsModel: event.smsModel));
        }
        if (result.containsKey('errors')) {
          emit((SettingHeaderEditError(result['message'])));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating Task: $e');
        }
        // Optionally, handle the error state, e.g. emit an error state
      }
    }
  }

  void _onUpdateSettingsWhatsApp(
    UpdateSettingsWhatsApp event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsSuccess) {
      emit(WhatsappSettingEditSuccessLoading());
      try {
        Map<String, dynamic> result = await SettingRepo().whatsAppsettingUpdate(
          event.accessToken,
          event.phoneNumId,
        );
        if (!result.containsKey('error')) {
          emit(SettingsWhatsAppUpdated());
        }
        if (result.containsKey('errors')) {
          emit((SettingWhatsappEditError(result['message'])));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating Task: $e');
        }
        // Optionally, handle the error state, e.g. emit an error state
      }
    }
  }

  void _onUpdateSettingsSlack(
    UpdateSettingsSlack event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsSuccess) {
      emit(SlackSettingEditSuccessLoading());
      try {
        Map<String, dynamic> result = await SettingRepo().slackSettingUpdate(
          event.slackBotToken,
        );
        if (!result.containsKey('error')) {
          emit(SettingsSlackUpdated());
        }
        if (result.containsKey('errors')) {
          emit((SettingSlackEditError(result['message'])));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating Task: $e');
        }
        // Optionally, handle the error state, e.g. emit an error state
      }
    }
  }

  void _onUpdateSettingsMediaStorage(
    UpdateSettingsMediaStorage event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsSuccess) {
      emit(MediaStorageSettingEditSuccessLoading());
      try {
        Map<String, dynamic> result =
            await SettingRepo().mediaStorageSettingUpdate(
          storageType: event.storage,
          key: event.s3AccessKey,
          secret: event.s3SecretKey,
          region: event.s3RegionKey,
          bucket: event.s3BucketKey,
        );
        if (!result.containsKey('error')) {
          emit(SettingsMediaStorageUpdated());
        }
        if (result.containsKey('errors')) {
          emit((SettingMediaStorageEditError(result['message'])));
          flutterToastCustom(msg: result['message']);
        }
      } catch (e) {
        if (kDebugMode) {
          logger.d('Error while updating Task: $e');
        }
        // Optionally, handle the error state, e.g. emit an error state
      }
    }
  }

  Future<void> _getListOfSettings(
    SettingsList event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(SettingsLoading());

      int parseToInt(dynamic value) {
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      var result = await SettingRepo().setting(event.endPoints);

      if (!result.containsKey('errors')) {
        // Find the item with the matching variable name
        List<dynamic> dataList = result['data'] ?? [];
        Map<String, dynamic>? settingsData;

        for (var item in dataList) {
          if (item['variable'] == event.endPoints) {
            // Parse the JSON string in the value field
            try {
              settingsData = jsonDecode(item['value']);
            } catch (e) {
              if (kDebugMode) {
                logger.d("Error parsing settings JSON: $e");
              }
            }
            break;
          }
        }

        if (settingsData != null) {
          switch (event.endPoints) {
            case 'general_settings':
              comapanyTitle = settingsData['company_title'] ?? "";
              currencyFullForm = settingsData['currency_full_form'] ?? "";
              currencySymbol = settingsData['currency_symbol'] ?? "";
              currencyCode = settingsData['currency_code'] ?? "";
              dateformat = settingsData['date_format'] ?? "";
              fullLogo = settingsData['full_logo'] ?? "";
              halfLogo = settingsData['half_logo'] ?? "";
              favicon = settingsData['favicon'] ?? "";
              allowedFileTypes = settingsData['allowed_file_types'] ?? "";

              maxAttempts = settingsData['max_attempts']?.toString() ?? "";
              lockTime = settingsData['lock_time']?.toString() ?? "";
              maxFiles = settingsData['max_files']?.toString() ?? "";
              maxAllowedUplaodSize =
                  settingsData['allowed_max_upload_size']?.toString() ?? "";

              allowSignup = settingsData['allowSignup'];
              if (allowSignup is! int) {
                allowSignup = int.tryParse(allowSignup.toString()) ?? 0;
              }

              decimalPoints = settingsData['decimal_points']?.toString() ?? "";
              currencyPosition = settingsData['currency_symbol_position'] ?? "";
              currencyFormat = settingsData['currency_format'] ?? "";
              timeFormat = settingsData['time_format'] ?? "";
              siteUrl = settingsData['site_url'] ?? "";
              timeZone = settingsData['timezone'] ?? "";
              decimalPointsInCurrency =
                  settingsData['decimal_points_in_currency'] ?? "";

              upcomingBirthdays = parseToInt(settingsData['upcomingBirthdays']);
              upcomingAnniversary = parseToInt(
                settingsData['upcomingWorkAnniversaries'],
              );
              membersOnLeave = parseToInt(settingsData['membersOnLeave']);

              timeZoneList = (settingsData['timezones'] as List?)
                      ?.map((e) => TimeZoneInfoModel.fromList(e))
                      .toList() ??
                  [];

              break;

            case 'company_information':
              email = settingsData['companyEmail'] ?? "";
              phone = settingsData['companyPhone'] ?? "";
              address = settingsData['companyAddress'] ?? "";
              city = settingsData['companyCity'] ?? "";
              stateOfComapny = settingsData['companyState'] ?? "";
              country = settingsData['companyCountry'] ?? "";
              zipcode = settingsData['companyZip'] ?? "";
              website = settingsData['companyWebsite'] ?? "";
              vatNumber = settingsData['companyVatNumber'] ?? "";
              break;

            case 'email_settings':
              companyEmail = settingsData['email'] ?? "";
              emailPasswordSetting = settingsData['password'] ?? "";
              smtpHost = settingsData['smtp_host'] ?? "";
              smtpPort = settingsData['smtp_port'] ?? "";
              emailContentType = settingsData['email_content_type'] ?? "";
              smtpEncryption = settingsData['smtp_encryption'] ?? "";
              break;

            case 'sms_gateway_settings':
              baseUrl = settingsData['base_url'] ?? "";
              if (settingsData['header_data'] != null) {
                Map<String, dynamic> rawHeaderData =
                    settingsData['header_data'];
                headerDataList = rawHeaderData.entries
                    .map((entry) => {entry.key: entry.value.toString()})
                    .toList()
                    .cast<Map<String, String>>();
              }
              if (settingsData['body_formdata'] != null) {
                Map<String, dynamic> rawBodyData =
                    settingsData['body_formdata'];
                bodyFormDataList = rawBodyData.entries
                    .map((entry) => {entry.key: entry.value.toString()})
                    .toList()
                    .cast<Map<String, String>>();
              }
              if (settingsData['params_data'] != null) {
                Map<String, dynamic> rawParamsData =
                    settingsData['params_data'];
                paramDataList = rawParamsData.entries
                    .map((entry) => {entry.key: entry.value.toString()})
                    .toList()
                    .cast<Map<String, String>>();
              }
              messagingAuthorization =
                  settingsData['header_data']?['Authorization'] ?? "";
              method = settingsData['sms_gateway_method'] ?? "";
              break;

            case 'media_storage_settings':
              mediaStorageType = settingsData['media_storage_type'] ?? "";
              s3Key = settingsData['s3_key'] ?? "";
              s3Secret = settingsData['s3_secret'] ?? "";
              s3Region = settingsData['s3_region'] ?? "";
              s3Bucket = settingsData['s3_bucket'] ?? "";
              break;

            case 'whatsapp_settings':
              whatsappAccessToken = settingsData['access_token'] ?? "";
              whatsappPhoneNumberId = settingsData['phone_number_id'] ?? "";
              break;

            case 'slack_settings':
              slackBotToken = settingsData['bot_token'] ?? "";
              break;

            default:
              if (kDebugMode) {
                logger.d("Unknown settings type: ${event.endPoints}");
              }
          }

          emit(SettingsSuccess());
        } else {
          emit(SettingsError("Settings not found for ${event.endPoints}"));
        }
      } else {
        emit(SettingsError(result['message'] ?? "Error loading settings"));
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("Error in _getListOfSettings: $e");
      }
      emit(SettingsError(e.toString()));
    }
  }
}
