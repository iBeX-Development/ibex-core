import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Singleton class for mapping between UUID role strings and integer role IDs
/// Provides bidirectional conversion and persistence using Hive
class RoleIdMapper {
  static final RoleIdMapper _instance = RoleIdMapper._internal();

  factory RoleIdMapper() {
    return _instance;
  }

  RoleIdMapper._internal();

  // Maps to store the bidirectional relationship
  final Map<String, int> _uuidToInt = {};
  final Map<int, String> _intToUuid = {};

  int _counter = 1; // Start from 1 for role IDs

  /// Initialize the mapper by loading saved mappings from Hive
  Future<void> initialize() async {
    try {
      final box = await Hive.openBox('roleIdMapping');
      final savedMappings = box.get('mappings');

      if (savedMappings != null && savedMappings is Map) {
        _counter = box.get('counter', defaultValue: 1);

        // Restore mappings
        savedMappings.forEach((uuid, id) {
          if (uuid is String && id is int) {
            _uuidToInt[uuid] = id;
            _intToUuid[id] = uuid;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('⚠️  Error initializing RoleIdMapper: $e');
      }
    }
  }

  /// Convert UUID string to int role ID
  /// If the UUID hasn't been seen before, creates a new mapping
  int getIntId(String uuid) {
    if (_uuidToInt.containsKey(uuid)) {
      return _uuidToInt[uuid]!;
    }

    // Create new mapping
    final newId = _counter++;
    _uuidToInt[uuid] = newId;
    _intToUuid[newId] = uuid;

    // Save to persistence
    _saveMappings();

    return newId;
  }

  /// Convert int role ID back to UUID string
  /// Returns null if the ID hasn't been mapped
  String? getUuid(int id) {
    return _intToUuid[id];
  }

  /// Convert a list of UUID strings to int role IDs
  List<int> convertUuidsToInts(List<String> uuids) {
    return uuids.map((uuid) => getIntId(uuid)).toList();
  }

  /// Convert a list of int role IDs to UUID strings
  List<String> convertIntsToUuids(List<int> ids) {
    return ids
        .map((id) => getUuid(id))
        .where((uuid) => uuid != null)
        .cast<String>()
        .toList();
  }

  /// Save mappings to Hive for persistence
  Future<void> _saveMappings() async {
    try {
      final box = await Hive.openBox('roleIdMapping');
      await box.put('mappings', Map<String, int>.from(_uuidToInt));
      await box.put('counter', _counter);
    } catch (e) {
      if (kDebugMode) {
        logger.d('⚠️  Error saving role mappings: $e');
      }
    }
  }

  /// Clear all mappings (useful for testing or reset)
  Future<void> clear() async {
    _uuidToInt.clear();
    _intToUuid.clear();
    _counter = 1;

    try {
      final box = await Hive.openBox('roleIdMapping');
      await box.clear();
    } catch (e) {
      if (kDebugMode) {
        logger.d('⚠️  Error clearing role mappings: $e');
      }
    }
  }

  /// Get current mapping statistics
  Map<String, dynamic> getStats() {
    return {
      'totalMappings': _uuidToInt.length,
      'nextId': _counter,
      'mappings': Map<String, int>.from(_uuidToInt),
    };
  }
}
