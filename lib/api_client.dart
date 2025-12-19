import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:price_book/config.dart';
import 'package:price_book/pages/login_screen.dart';

class ApiClient {
  static const _refreshUrl =
      'https://qyzylorda-idm-test.curs.kz/api/v1/token/refresh';

  /// ---------- GET ----------
  static Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _send(() async {
      final h = await Config.authorizedJsonHeaders(extra: headers);
      return http.get(Uri.parse('$QYZ_API_BASE$path'), headers: h);
    });
  }

  /// ---------- POST ----------
  static Future<http.Response> post(
    String path,
    Object body, {
    Map<String, String>? headers,
  }) async {
    return _send(() async {
      final h = await Config.authorizedJsonHeaders(extra: headers);
      return http.post(
        Uri.parse('$QYZ_API_BASE$path'),
        headers: h,
        body: jsonEncode(body),
      );
    });
  }

  /// ---------- PUT ----------
  static Future<http.Response> put(
    String path,
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
    });
  }

  /// 🔥 ОСНОВНАЯ ЛОГИКА
  static Future<http.Response> _send(
    Future<http.Response> Function() request,
    BuildContext context, // добавляем context сюда
  ) async {
    final response = await request();

    if (response.statusCode != 401) {
      return response;
    }

    final refreshed = await _refreshToken();

    if (!refreshed) {
      // если refresh не прошёл → идём на LoginScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      throw UnauthorizedException();
    }

    return request();
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
      token: data['token'],
      refreshToken: data['refreshToken'],
      phone: data['phone'] ?? '',
    );

    return true;
  }
}

class UnauthorizedException implements Exception {}
