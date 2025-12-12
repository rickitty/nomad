// lib/config.dart
import 'package:shared_preferences/shared_preferences.dart';

const QYZ_API_BASE = 'https://qyzylorda-idm-test.curs.kz/api/v1/monitoring';

class Config {
  static const _tokenKey = 'token';
  static const _refreshTokenKey = 'refreshToken';
  static const _phoneKey = 'phone';

  /// Сохранить токены и телефон после логина
  static Future<void> saveAuthData({
    required String token,
    required String refreshToken,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    print("DEBUG saveAuthData: token=$token, refreshToken=$refreshToken, phone=$phone");
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_phoneKey, phone);
  }

  
    static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('DEBUG getToken: token from prefs = $token');
    return token;
  }

  static Future<Map<String, String>> authorizedJsonHeaders({
    Map<String, String>? extra,
  }) async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?extra,
    };
    print('DEBUG headers: $headers');
    return headers;
  }
}


//   static Future<void> updateToken(String newToken) async {
//     bearerToken = newToken;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString("BearerToken", newToken);
//   }
// }

// final createmarket = '$baseUrl/market/create-market';
// final getMarkets = '$baseUrl/market/markets';
// final alltasks = '$baseUrl/tasks/all';
// final createTaskUrl = '$baseUrl/tasks/create-task';
// final sendCode = '$baseUrl/proxy/sendcode';
// final login = '$baseUrl/proxy/login';
// final refreshToken = '$baseUrl/proxy/refresh';
// final profileUrl = '$baseUrl/proxy/profile';
