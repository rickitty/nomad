import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:price_book/config.dart';
import 'package:price_book/pages/login_screen.dart';

class ApiClient {
  static const _refreshUrl =
      'https://qyzylorda-idm-test.curs.kz/api/v1/user/token/refresh';

  /// ---------- GET ----------
  static Future<http.Response> get(
    String path,
    BuildContext context, { // теперь context обязателен
    Map<String, String>? headers,
  }) async {
    return _send(() async {
      final h = await Config.authorizedJsonHeaders(extra: headers);
      return http.get(Uri.parse('$QYZ_API_BASE$path'), headers: h);
    }, context);
  }

  /// ---------- POST ----------
  static Future<http.Response> post(
    String path,
    Object body,
    BuildContext context, {
    Map<String, String>? headers,
  }) async {
    return _send(() async {
      final h = await Config.authorizedJsonHeaders(extra: headers);
      return http.post(
        Uri.parse('$QYZ_API_BASE$path'),
        headers: h,
        body: jsonEncode(body),
      );
    }, context);
  }

  /// ---------- PUT ----------
  static Future<http.Response> put(
    String path,
    BuildContext context,
    Object body, {
    Map<String, String>? headers,
  }) async {
    return _send(() async {
      final h = await Config.authorizedJsonHeaders(extra: headers);
      return http.put(
        Uri.parse('$QYZ_API_BASE$path'),
        headers: h,
        body: jsonEncode(body),
      );
    }, context);
  }

  static Future<http.Response> _send(
    Future<http.Response> Function() request,
    BuildContext context,
  ) async {
    final response = await request();

    if (response.statusCode != 401) {
      return response;
    }

    final refreshed = await _refreshToken();

    if (!refreshed) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      throw UnauthorizedException();
    }

    return request();
  }

  /// ---------- MULTIPART PUT ----------
  static Future<http.StreamedResponse> multipartPut(
    String path,
    Map<String, String> fields,
    List<http.MultipartFile> files,
    BuildContext context,
  ) async {
    final uri = Uri.parse('$QYZ_API_BASE$path');

    final token = await Config.getToken();
    if (token == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      throw Exception('Token not found');
    }

    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    request.files.addAll(files);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();

      if (!refreshed) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        throw UnauthorizedException();
      }

      // 🔁 повторяем запрос с новым токеном
      final newToken = await Config.getToken();
      final retry = http.MultipartRequest('PUT', uri);
      retry.headers['Authorization'] = 'Bearer $newToken';
      retry.fields.addAll(fields);
      retry.files.addAll(files);

      response = await retry.send();
    }

    return response;
  }

  /// ---------- REFRESH ----------
  static Future<bool> _refreshToken() async {
    final refreshToken = await Config.getRefreshToken();
    final token = await Config.getToken();

    if (refreshToken == null || token == null) {
      return false;
    }

    final response = await http.post(
      Uri.parse(_refreshUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken, 'token': token}),
    );

    print('DEBUG refresh response: ${response.statusCode}');
    print('DEBUG refresh body: ${response.body}');

    if (response.statusCode != 200) {
      return false;
    }

    final data = jsonDecode(response.body);

    await Config.saveAuthData(
      token: data['accessToken'],
      refreshToken: data['refreshToken'],
      phone: await Config.getPhone() ?? '',
    );

    return true;
  }
}

class UnauthorizedException implements Exception {}
