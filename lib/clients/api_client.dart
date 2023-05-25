import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:contacts_plus_plus/models/authentication_data.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../config.dart';

class ApiClient {
  static const String totpKey = "TOTP";
  static const String userIdKey = "userId";
  static const String machineIdKey = "machineId";
  static const String tokenKey = "token";
  static const String passwordKey = "password";

  ApiClient({required AuthenticationData authenticationData}) : _authenticationData = authenticationData;

  final AuthenticationData _authenticationData;
  final Logger _logger = Logger("API");

  AuthenticationData get authenticationData => _authenticationData;
  String get userId => _authenticationData.userId;
  bool get isAuthenticated => _authenticationData.isAuthenticated;

  static Future<AuthenticationData> tryLogin({
    required String username,
    required String password,
    bool rememberMe=true,
    bool rememberPass=true,
    String? oneTimePad,
  }) async {
    final body = {
      (username.contains("@") ? "email" : "username"): username.trim(),
      "password": password,
      "rememberMe": rememberMe,
      "secretMachineId": const Uuid().v4(),
    };
    final response = await http.post(
        buildFullUri("/UserSessions"),
        headers: {
          "Content-Type": "application/json",
          if (oneTimePad != null) totpKey : oneTimePad,
        },
        body: jsonEncode(body),
    );
    if (response.statusCode == 403 && response.body == totpKey) {
      throw totpKey;
    }
    if (response.statusCode == 400) {
      throw "Invalid Credentials";
    } 
    checkResponseCode(response);

    final authData = AuthenticationData.fromMap(jsonDecode(response.body));
    if (authData.isAuthenticated) {
      const FlutterSecureStorage storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      await storage.write(key: userIdKey, value: authData.userId);
      await storage.write(key: machineIdKey, value: authData.secretMachineId);
      await storage.write(key: tokenKey, value: authData.token);
      if (rememberPass) await storage.write(key: passwordKey, value: password);
    }
    return authData;
  }

  static Future<AuthenticationData> tryCachedLogin() async {
    const FlutterSecureStorage storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    String? userId = await storage.read(key: userIdKey);
    String? machineId = await storage.read(key: machineIdKey);
    String? token = await storage.read(key: tokenKey);
    String? password = await storage.read(key: passwordKey);

    if (userId == null || machineId == null) {
      return AuthenticationData.unauthenticated();
    }

    if (token != null) {
      final response = await http.patch(buildFullUri("/userSessions"), headers: {
        "Authorization": "neos $userId:$token"
      });
      if (response.statusCode == 200) {
        return AuthenticationData(userId: userId, token: token, secretMachineId: machineId, isAuthenticated: true);
      }
    }

    if (password != null) {
      try {
        userId = userId.startsWith("U-") ? userId.replaceRange(0, 2, "") : userId;
        final loginResult = await tryLogin(username: userId, password: password, rememberPass: true);
        if (loginResult.isAuthenticated) return loginResult;
      } catch (_) {
        // We don't need to notify the user if the cached login fails behind the scenes, so just ignore any exceptions.
      }
    }
    return AuthenticationData.unauthenticated();
  }

  Future<void> logout(BuildContext context) async {
    const FlutterSecureStorage storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.delete(key: userIdKey);
    await storage.delete(key: machineIdKey);
    await storage.delete(key: tokenKey);
    await storage.delete(key: passwordKey);
    if (context.mounted) {
      Phoenix.rebirth(context);
    }
  }

  Future<void> extendSession() async {
    final response = await patch("/userSessions");
    if (response.statusCode != 204) {
      throw "Failed to extend session.";
    }
  }

  void checkResponse(http.Response response) {
    if (response.statusCode == 403) {
      tryCachedLogin().then((value) {
        if (!value.isAuthenticated) {
          // TODO: Turn api-client into a change notifier to present login screen when logged out
        }
      });
    }
    checkResponseCode(response);
  }

  static void checkResponseCode(http.Response response) {
    if (response.statusCode < 300) return;

    final error = "${switch (response.statusCode) {
      429 => "Sorry, you are being rate limited.",
      403 => "You are not authorized to do that.",
      404 => "Resource not found.",
      500 => "Internal server error.",
      _ => "Unknown Error."
    }} (${response.statusCode}${kDebugMode ? "|${response.body}" : ""})";

    FlutterError.reportError(FlutterErrorDetails(exception: error));
    throw error;
  }

  Map<String, String> get authorizationHeader => _authenticationData.authorizationHeader;

  static Uri buildFullUri(String path) => Uri.parse("${Config.apiBaseUrl}/api$path");

  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    headers ??= {};
    headers.addAll(authorizationHeader);
    final response = await http.get(buildFullUri(path), headers: headers);
    _logger.info("GET $path => ${response.statusCode}${response.statusCode >= 300 ? ": ${response.body}" : ""}");
    return response;
  }

  Future<http.Response> post(String path, {Object? body, Map<String, String>? headers}) async {
    headers ??= {};
    headers["Content-Type"] = "application/json";
    headers.addAll(authorizationHeader);
    final response = await http.post(buildFullUri(path), headers: headers, body: body);
    _logger.info("PST $path => ${response.statusCode}${response.statusCode >= 300 ? ": ${response.body}" : ""}");
    return response;
  }

  Future<http.Response> put(String path, {Object? body, Map<String, String>? headers}) async {
    headers ??= {};
    headers["Content-Type"] = "application/json";
    headers.addAll(authorizationHeader);
    final response = await http.put(buildFullUri(path), headers: headers, body: body);
    _logger.info("PUT $path => ${response.statusCode}${response.statusCode >= 300 ? ": ${response.body}" : ""}");
    return response;
  }

  Future<http.Response> delete(String path, {Map<String, String>? headers}) async {
    headers ??= {};
    headers.addAll(authorizationHeader);
    final response = await http.delete(buildFullUri(path), headers: headers);
    _logger.info("DEL $path => ${response.statusCode}${response.statusCode >= 300 ? ": ${response.body}" : ""}");
    return response;
  }

  Future<http.Response> patch(String path, {Object? body, Map<String, String>? headers}) async {
    headers ??= {};
    headers["Content-Type"] = "application/json";
    headers.addAll(authorizationHeader);
    final response = await http.patch(buildFullUri(path), headers: headers, body: body);
    _logger.info("PAT $path => ${response.statusCode}${response.statusCode >= 300 ? ": ${response.body}" : ""}");
    return response;
  }
}
