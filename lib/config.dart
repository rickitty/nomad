import 'package:shared_preferences/shared_preferences.dart';

// final baseUrl = 'http://localhost:3000/api';
// final fileBaseUrl = 'http://localhost:3000';
final QYZ_API_BASE = 'https://qyzylorda-idm-test.curs.kz/api/v1/monitoring';

class Config {
  static String bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiI4MzJmN2U3ZC1lYmZmLTRkYTktYjVmNC1lNWNiMjU1NjAyMzAiLCJsb2dpbiI6Ijc3NzUzNTEzMTMyIiwidXNlckdyb3VwIjoiYWRtaW4iLCJuYmYiOjE3NjUzOTQzODQsImV4cCI6MTc2NTM5Nzk4NCwiaWF0IjoxNzY1Mzk0Mzg0LCJpc3MiOiJxeXp5bG9yZGFzYyIsImF1ZCI6IndlYiJ9.hbFy3RGKLeu7a5l1IrnWSn5deVXH8VR3fZnI-W1K7I8";

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    bearerToken = prefs.getString("BearerToken") ?? "";
  }

  static Future<void> updateToken(String newToken) async {
    bearerToken = newToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("BearerToken", newToken);
  }
}

// final createmarket = '$baseUrl/market/create-market';
// final getMarkets = '$baseUrl/market/markets';
// final alltasks = '$baseUrl/tasks/all';
// final createTaskUrl = '$baseUrl/tasks/create-task';
// final sendCode = '$baseUrl/proxy/sendcode';
// final login = '$baseUrl/proxy/login';
// final refreshToken = '$baseUrl/proxy/refresh';
// final profileUrl = '$baseUrl/proxy/profile';
