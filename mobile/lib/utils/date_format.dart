import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

final logger = Logger();

String formatDateFromApi(String date, BuildContext context) {
  final DateTime parsedDate = DateTime.parse(date);
  final DateFormat formatter = DateFormat('MMM dd, yyyy');
  return formatter.format(parsedDate);
}

DateTime parseDateStringFromApi(String date) {
  return DateTime.parse(date);
}

String dateFormatConfirmed(DateTime date, BuildContext context) {
  final DateFormat formatter = DateFormat('MMM dd, yyyy');
  return formatter.format(date);
}

// ✅ Helper method for safe date parsing
DateTime? _parseDate(dynamic dateValue) {
  if (dateValue == null) return null;

  try {
    if (dateValue is String) {
      if (dateValue.isEmpty) return null;
      return DateTime.parse(dateValue);
    } else if (dateValue is DateTime) {
      return dateValue;
    }
    return null;
  } catch (e) {
    if (kDebugMode) {
      logger.d("⚠️ Failed to parse date: $dateValue - Error: $e");
    }
    return null;
  }
}

class DateParser {
  /// Parse date from various formats, returns null if invalid
  static DateTime? parse(dynamic dateValue) {
    if (dateValue == null) {
      return null;
    }

    try {
      if (dateValue is String) {
        if (dateValue.isEmpty || dateValue.toLowerCase() == 'null') {
          return null;
        }

        // Try ISO 8601 format first
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      } else if (dateValue is int) {
        // Unix timestamp in milliseconds
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }

      if (kDebugMode) {

        logger.d("⚠️ Unexpected date type: ${dateValue.runtimeType}");

      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        logger.d("⚠️ Failed to parse date: '$dateValue' - Error: $e");
      }
      return null;
    }
  }

  /// Format date to display string
  static String? format(DateTime? date, {String format = 'yyyy-MM-dd'}) {
    if (date == null) return null;
    return DateFormat(format).format(date);
  }

  /// Parse and format in one go
  static String? parseAndFormat(
    dynamic dateValue, {
    String format = 'yyyy-MM-dd',
  }) {
    final date = parse(dateValue);
    return DateParser.format(date, format: format);
  }
}
