import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ibex/bloc/setting/settings_bloc.dart';
import 'package:ibex/config/colors.dart';

import '../src/generated/i18n/app_localizations.dart';
import '../utils/widgets/toast_widget.dart';
import 'package:logger/logger.dart';

final logger = Logger();

const String appName = 'iBex';
// const String baseUrl = '$url/api/';
// const String baseUrl = 'http://localhost:8008/api/'; // For iOS Simulator
// const String baseUrl = 'http://10.0.2.2:8008/api/'; // For localhost
const String baseUrl = 'https://api.ibex.mn/';
const String pictureUrl = 'https://api.ibex.mn/assets';

const String baseSmartUrl = 'https://smartgps-admin.ibex.mn/';
const String pictureSmartUrl = 'https://smartgps-admin.ibex.mn/assets';

/// Mutable active base URL — changes based on logged-in user's email domain.
String activeBaseUrl = baseUrl;
String activePictureUrl = pictureUrl;

/// Call this with the user's email after login (or on app startup) to switch the API base URL.
void setBaseUrlByEmail(String email) {
  if (email.toLowerCase().endsWith('smartgps@gmail.com')) {
    activeBaseUrl = baseSmartUrl;
    activePictureUrl = pictureSmartUrl;
  } else {
    activeBaseUrl = baseUrl;
    activePictureUrl = pictureUrl;
  }
}

const String url = "";
const String packageName = 'Package Name';
String defaultLanguage = 'mn';
String defaultCountryCode = '+976';
bool defaultBiometric = false;
String defaultCountry = 'MN';
String defaultZip = '210646';

const String googleCalendarId = '';
const String googleApiKey = '';

final Set<String> rtlLanguages = {
  'ar', // Arabic
  'arc', // Aramaic
  'az', // Azeri (Azerbaijani)
  'dv', // Dhivehi (Maldivian)
  'he', // Hebrew
  'ku', // Kurdish (Sorani)
  'fa', // Persian (Farsi)
  'ur', // Urdu
  'mn', // Mongolian
};

String formatDateFromApi(String dateStr, BuildContext context) {
  // Fetch the current date format from SettingsBloc, default to "YYYY-MM-DD"
  String formatVal = context.read<SettingsBloc>().dateformat ?? "YYYY-MM-DD";

  // A map to handle the format conversion from the "settings" format to the required format

  Map<String, String> formatMapping = {
    "DD-MM-YYYY|d-m-Y": "dd-MM-yyyy", // 24-12-2024
    "D-M-YY|j-n-y": "d-M-yy", // 24-12-24
    "MM-DD-YYYY|m-d-Y": "MM-dd-yyyy", // 12-24-2024
    "M-D-YY|n-j-y": "M-d-yy", // 12-24-24
    "YYYY-MM-DD|Y-m-d": "yyyy-MM-dd", // 2024-12-24
    "YY-M-D|Y-n-j": "yy-M-d", // 24-12-24
    "MMMM DD, YYYY|F d, Y": "MMMM dd, yyyy", // December 24, 2024
    "MMM DD, YYYY|M d, Y": "MMM dd, yyyy", // Dec 24, 2024
    "DD-MMM-YYYY|d-M-Y": "dd-MMM-yyyy", // 24-Dec-2024
    "DD MMM, YYYY|d M, Y": "dd MMM, yyyy", // 24 Dec, 2024
    "YYYY-MMM-DD|Y-M-d": "yyyy-MMM-dd", // 2024-Dec-24
    "YYYY, MMM DD|Y, M d": "yyyy, MMM dd", // 2024, Dec 24
  };

  // Check if the format contains '|' and adjust the format value
  if (formatMapping.containsKey(formatVal)) {
    formatVal = formatMapping[formatVal]!;
  } else {
    // Default format if no matching case
    formatVal = "YYYY-MM-DD";
  }

  // Parse the input date string into a DateTime object
  DateTime date;
  try {
    date = DateTime.parse(dateStr); // '2024-12-25'
  } catch (e) {
    return ''; // Return empty if parsing fails
  }

  // Define the variable to hold the formatted date
  String formattedDate = '';

  // Apply the format to the DateTime object
  try {
    formattedDate = DateFormat(formatVal).format(date);
  } catch (e) {
    return ''; // Return empty if formatting fails
  }

  return formattedDate;
}

DateTime? formatDateFromApiAsDate(String dateStr, BuildContext context) {
  String formatVal = context.read<SettingsBloc>().dateformat ?? "YYYY-MM-DD";

  Map<String, String> formatMapping = {
    "DD-MM-YYYY|d-m-Y": "dd-MM-yyyy",
    "D-M-YY|j-n-y": "d-M-yy",
    "MM-DD-YYYY|m-d-Y": "MM-dd-yyyy",
    "M-D-YY|n-j-y": "M-d-yy",
    "YYYY-MM-DD|Y-m-d": "yyyy-MM-dd",
    "YY-M-D|Y-n-j": "yy-M-d",
    "MMMM DD, YYYY|F d, Y": "MMMM dd, yyyy",
    "MMM DD, YYYY|M d, Y": "MMM dd, yyyy",
    "DD-MMM-YYYY|d-M-Y": "dd-MMM-yyyy",
    "DD MMM, YYYY|d M, Y": "dd MMM, yyyy",
    "YYYY-MMM-DD|Y-M-d": "yyyy-MMM-dd",
    "YYYY, MMM DD|Y, M d": "yyyy, MMM dd",
  };

  if (formatMapping.containsKey(formatVal)) {
    formatVal = formatMapping[formatVal]!;
  } else {
    formatVal = "yyyy-MM-dd"; // Default format
  }

  try {
    return DateFormat(formatVal).parse(dateStr);
  } catch (e) {
    if (kDebugMode) {
      logger.d("Error parsing date: $dateStr, Error: $e");
    }
    return null;
  }
}

void validateInput(String? value, BuildContext context) {
  if (value != null && value.isNotEmpty) {
    try {
      final doubleValue = double.parse(value);
      if (doubleValue < 0) {
        flutterToastCustom(
          msg: AppLocalizations.of(context)!.negativeValueNotAllowed,
          color: AppColors.red, // Use red for errors
        );
      }
    } catch (e) {
      flutterToastCustom(
        msg: AppLocalizations.of(context)!.invalidNumberFormat,
        color: AppColors.red, // Use red for errors
      );
    }
  }
}

String dateFormatConfirmedToApi(DateTime inputDate) {
  // Format the DateTime object into YYYY-MM-DD format
  DateFormat outputFormat = DateFormat('yyyy-MM-dd');

  return outputFormat.format(inputDate);
}

String dateFormatConfirmed(DateTime inputDate, BuildContext? context) {
  String formatVal = context!.read<SettingsBloc>().dateformat ?? "YYYY-MM-DD";

  // A map to handle the format conversion from the "settings" format to the required format
  Map<String, String> formatMapping = {
    "DD-MM-YYYY|d-m-Y": "dd-MM-yyyy",
    "D-M-YY|j-n-y": "d-M-yy",
    "MM-DD-YYYY|m-d-Y": "MM-dd-yyyy",
    "M-D-YY|n-j-y": "M-d-yy",
    "YYYY-MM-DD|Y-m-d": "yyyy-MM-dd",
    "YY-M-D|Y-n-j": "yy-M-d",
    "MMMM DD, YYYY|F d, Y": "MMMM dd, yyyy",
    "MMM DD, YYYY|M d, Y": "MMM dd, yyyy",
    "DD-MMM-YYYY|d-M-Y": "dd-MMM-yyyy",
    "DD MMM, YYYY|d M, Y": "dd MMM, yyyy",
    "YYYY-MMM-DD|Y-M-d": "yyyy-MMM-dd",
    "YYYY, MMM DD|Y, M d": "yyyy, MMM dd",
  };

  // Check if the format contains '|' and adjust the format value
  if (formatMapping.containsKey(formatVal)) {
    formatVal = formatMapping[formatVal]!;
  } else {
    // Default format if no matching case
    formatVal = "yyyy-MM-dd";
  }
  // Format the DateTime object into YYYY-MM-DD format
  DateFormat outputFormat = DateFormat(formatVal);
  return outputFormat.format(inputDate);
}

DateTime parseDateStringFromApi(String dateString) {
  // print("DATE STRING ${dateString}");

  try {
    // Parse the date string in 'yyyy-MM-dd' format
    DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(dateString);

    // Create a new DateTime with the same year, month, and day but no time
    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
  } catch (e) {
    // Handle error if the date is invalid

    // Return the current date with time set to midnight (no time component)
    return DateTime.now().toLocal().subtract(
          Duration(
            hours: DateTime.now().hour,
            minutes: DateTime.now().minute,
            seconds: DateTime.now().second,
            milliseconds: DateTime.now().millisecond,
          ),
        );
  }
}

TimeOfDay convertToTimeOfDay(String timeString) {
  // Parse the time string using DateFormat
  final format = DateFormat("HH:mm");
  final parsedTime = format.parse(timeString);

  // Return a TimeOfDay object using the hours and minutes from parsedTime
  return TimeOfDay(hour: parsedTime.hour, minute: parsedTime.minute);
}

String datechange(String givenDate) {
  DateFormat inputFormat = DateFormat('yyyy-MM-dd');
  DateFormat outputFormat = DateFormat('MMM dd, yyyy');
  DateTime date = inputFormat.parse(givenDate);
  String formattedDateString = outputFormat.format(date);

  return formattedDateString; // Output: 22 August 2024
}

String changeTimeFormat(String timeFrom) {
  String time = timeFrom;
  DateTime dateTime = DateTime.parse(
    "2024-01-01 $time",
  ); // Use a fixed date for parsing
  String formattedTime = DateFormat('hh:mm').format(dateTime);
  return formattedTime;
}

String parseDateTimeFormat(String? dateTimeString) {
  if (dateTimeString == null || dateTimeString.isEmpty) {
    return '';
  }
  String formattedDateTime = DateFormat(
    'yyyy-MM-dd HH:mm',
  ).format(DateTime.parse(dateTimeString));
  return formattedDateTime.toString();
}

Map<String, dynamic> convertStringToMap(String inputString) {
  // Removing the outer curly braces
  inputString = inputString.substring(1, inputString.length - 1);

  // Splitting the string by the first occurrence of ', item:' to separate 'type' and 'item'
  List<String> keyValuePairs = inputString.split(', item:').cast<String>();

  // Parsing the type key-value pair
  String typePair = keyValuePairs[0].trim();
  List<String> typeKeyValue = typePair.split(': ').cast<String>();
  String typeKey = typeKeyValue[0].trim();
  String typeValue = typeKeyValue[1].trim();

  // Creating the map and handling 'type'
  Map<String, dynamic> resultMap = {};
  resultMap[typeKey] = typeValue == "null" ? null : typeValue;

  // Parsing the 'item' value which may contain a JSON object
  String itemValue = keyValuePairs[1].trim();

  // Check if 'item' contains a valid JSON object
  if (itemValue.startsWith("{") && itemValue.endsWith("}")) {
    resultMap['item'] = jsonDecode(itemValue); // Decoding JSON
  } else {
    // If not a JSON object, handle as a regular string
    resultMap['item'] = itemValue.replaceAll('"', '');
  }

  return resultMap;
}

String getOrdinalSuffix(int number) {
  if (number >= 11 && number <= 13) {
    return "ᵗʰ"; // Special case for 11th, 12th, 13th
  }
  switch (number % 10) {
    case 1:
      return "ˢᵗ"; // 1st -> ¹ˢᵗ
    case 2:
      return "ⁿᵈ"; // 2nd -> ²ⁿᵈ
    case 3:
      return "ʳᵈ"; // 3rd -> ³ʳᵈ
    default:
      return "ᵗʰ"; // All others -> ᵗʰ
  }
}

Future<void> requestForPermission() async {
  await Permission.microphone.request();
}

void listenForPermissions() async {
  final status = await Permission.microphone.status;
  switch (status) {
    case PermissionStatus.denied:
      requestForPermission();
      break;
    case PermissionStatus.granted:
      break;
    case PermissionStatus.limited:
      break;
    case PermissionStatus.permanentlyDenied:
      break;
    case PermissionStatus.restricted:
      break;
    case PermissionStatus.provisional: // Handle the provisional case
      break;
  }
}

Color hexToColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "").replaceAll("0X", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor"; // Add full opacity if missing
  }

  return Color(int.parse("0x$hexColor")); // Ensure proper hex format
}

String getGreeting(BuildContext context) {
  int hour = DateTime.now().hour;
  if (hour < 12) {
    return AppLocalizations.of(context)!.morning;
  }
  if (hour < 17) {
    return AppLocalizations.of(context)!.afternoon;
  }
  return AppLocalizations.of(context)!.evening;
}

String getGreetingEmoji() {
  int hour = DateTime.now().hour;
  if (hour < 12) {
    return "☀️";
  }
  if (hour < 17) {
    return "🌞";
  }
  return "🌙";
}

List<Map<String, dynamic>> getContstantPriorities() {
  return [
    {
      'text': 'Low',
      'label': 'Low',
      'value': 1,
      'icon': 'iconoir:priority-down-solid',
      'iconColor': '#8363ee',
      'media': '/img/icons/priority/low.svg',
      'defaultColor': '#facc15',
    },
    {
      'text': 'High',
      'label': 'High',
      'value': 2,
      'icon': 'iconoir:priority-high-solid',
      'iconColor': '#e37f0d',
      'media': '/img/icons/priority/high.svg',
      'defaultColor': '#f43f5e',
    },
    {
      'text': 'Medium',
      'label': 'Medium',
      'value': 3,
      'icon': 'iconoir:priority-medium-solid',
      'iconColor': '#efd548',
      'media': '/img/icons/priority/medium.svg',
      'defaultColor': '#f97316',
    },
    {
      'text': 'Urgent',
      'label': 'Urgent',
      'value': 4,
      'icon': 'mingcute:emergency-flashers-fill',
      'iconColor': '#f43f5e',
      'media': '/img/icons/priority/urgent.svg',
      'defaultColor': '#a855f7',
    },
  ];
}
