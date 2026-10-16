import '../data/localStorage/hive.dart';

Future<Map<String, String>?> get headers async {
  final String? token = await HiveStorage.getToken();
  final int? workspaceId = await HiveStorage.getWorkspaceId();

  if (token != null && token.trim().isNotEmpty) {
    final headers = {
      "Accept": "application/json",
      'Authorization': 'Bearer $token',
      // Temporarily comment out workspace-id to test if it's causing FORBIDDEN error
      // 'workspace-id': workspaceId.toString(),
    };
    // print("📤 Request Headers: $headers");
    return headers;
  }
  return null;
}

Future<Map<String, String>?> get headerForChat async {
  final String? token = await HiveStorage.getToken();
  final int? workspaceId = await HiveStorage.getWorkspaceId();
  // print("Token: $token");
  if (token != null && token.trim().isNotEmpty) {
    return {
      "Accept": "application/json",
      'Authorization': 'Bearer $token',
      'workspace-id': workspaceId.toString(),
      'user-agent': 'Dart/3.6 (dart:io)',
      'accept': 'application/json',
      'accept-encoding': 'gzip',
      'host': 'dev-ibex.taskhub.company',
    };
  }
  return null;
}
