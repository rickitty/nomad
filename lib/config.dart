// config.dart
import 'package:shared_preferences/shared_preferences.dart';

// final baseUrl = 'http://localhost:3000/api';
// final fileBaseUrl = 'http://localhost:3000';
final QYZ_API_BASE = 'https://qyzylorda-idm-test.curs.kz/api/v1/monitoring';

class Config {
  static String bearerToken = "";

  /// Загружаем токен при старте приложения
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    bearerToken = prefs.getString("BearerToken") ?? "";
  }

  /// Обновляем токен из Drawer или другого места
  static Future<void> updateToken(String newToken) async {
    bearerToken = newToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("BearerToken", newToken);
  }
}

// URL-адреса API
// final createmarket = '$baseUrl/market/create-market';
// final getMarkets = '$baseUrl/market/markets';
// final alltasks = '$baseUrl/tasks/all';
// final createTaskUrl = '$baseUrl/tasks/create-task';
// final sendCode = '$baseUrl/proxy/sendcode';
// final login = '$baseUrl/proxy/login';
// final refreshToken = '$baseUrl/proxy/refresh';
// final profileUrl = '$baseUrl/proxy/profile';
