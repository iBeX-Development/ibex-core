import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Singleton class to map UUID strings to integers and vice versa
/// This allows using List<int> throughout the codebase while backend uses UUID strings
class UserIdMapper {
  static final UserIdMapper _instance = UserIdMapper._internal();
  factory UserIdMapper() => _instance;
  UserIdMapper._internal();

  // Maps UUID string to int
  final Map<String, int> _uuidToInt = {};
  // Maps int to UUID string
  final Map<int, String> _intToUuid = {};

  int _counter = 1;
  bool _isInitialized = false;

  /// Initialize the mapper by loading saved mappings from Hive
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final box = await Hive.openBox('userIdMapping');

      // Load counter
      _counter = box.get('counter', defaultValue: 1);

      // Load mappings
      final Map<dynamic, dynamic>? savedMappings = box.get('mappings');
      if (savedMappings != null) {
        savedMappings.forEach((key, value) {
          if (key is String && value is int) {
            _uuidToInt[key] = value;
            _intToUuid[value] = key;
          }
        });
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        logger.d('Error initializing UserIdMapper: $e');
      }
      _isInitialized = true; // Continue anyway
    }
  }

  /// Convert UUID string to int
  /// If UUID is not yet mapped, creates a new mapping
  int getIntId(String uuid) {
    if (_uuidToInt.containsKey(uuid)) {
      return _uuidToInt[uuid]!;
    }

    // Create new mapping
    final newId = _counter++;
    _uuidToInt[uuid] = newId;
    _intToUuid[newId] = uuid;

    // Save to Hive
    _saveMappings();
    // print("🔹 Mapped new user: $uuid -> $newId");
    return newId;
  }

  /// Convert int to UUID string
  /// Returns null if mapping doesn't exist
  String? getUuid(int id) {
    return _intToUuid[id];
  }

  /// Get int ID if exists, otherwise return null
  int? getIntIdIfExists(String uuid) {
    return _uuidToInt[uuid];
  }

  /// Check if UUID is already mapped
  bool hasUuid(String uuid) {
    return _uuidToInt.containsKey(uuid);
  }

  /// Check if int ID is already mapped
  bool hasIntId(int id) {
    return _intToUuid.containsKey(id);
  }

  /// Convert List<String> UUIDs to List<int>
  List<int> convertUuidsToInts(List<String> uuids) {
    return uuids.map((uuid) => getIntId(uuid)).toList();
  }

  /// Convert List<int> to List<String> UUIDs
  List<String> convertIntsToUuids(List<int> ids) {
    return ids
        .map((id) => getUuid(id))
        .where((uuid) => uuid != null)
        .cast<String>()
        .toList();
  }

  /// Save mappings to Hive
  Future<void> _saveMappings() async {
    try {
      final box = await Hive.openBox('userIdMapping');
      await box.put('counter', _counter);
      await box.put('mappings', _uuidToInt);
    } catch (e) {
      if (kDebugMode) {
        logger.d('Error saving UserIdMapper mappings: $e');
      }
    }
  }

  /// Clear all mappings (for testing/debugging)
  Future<void> clearMappings() async {
    _uuidToInt.clear();
    _intToUuid.clear();
    _counter = 1;

    try {
      final box = await Hive.openBox('userIdMapping');
      await box.clear();
    } catch (e) {
      if (kDebugMode) {
        logger.d('Error clearing UserIdMapper mappings: $e');
      }
    }
  }

  /// Get current mapping statistics
  Map<String, dynamic> getStats() {
    return {
      'totalMappings': _uuidToInt.length,
      'nextId': _counter,
      'isInitialized': _isInitialized,
    };
  }
}
