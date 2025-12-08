import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:price_book/keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:price_book/config.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String? refresh = prefs.getString("refreshToken");

    if (token == null) {
      setState(() => loading = false);
      return;
    }

    Future<Map<String, dynamic>?> requestProfile() async {
      final res = await http.get(
        Uri.parse(profileUrl),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      if (res.statusCode == 401 && refresh != null) {
        // refresh
        final r = await http.post(
          Uri.parse(refreshToken),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"token": token, "refreshToken": refresh}),
        );

        if (r.statusCode == 200) {
          final data = jsonDecode(r.body);
          await prefs.setString("token", data["token"]);
          await prefs.setString("refreshToken", data["refreshToken"]);
          token = data["token"];
          refresh = data["refreshToken"];

          // повторяем запрос
          final retry = await http.get(
            Uri.parse(profileUrl),
            headers: {"Authorization": "Bearer $token"},
          );

          if (retry.statusCode == 200) {
            return jsonDecode(retry.body);
          }
        }
      }

      return null;
    }

    final data = await requestProfile();
    setState(() {
      profile = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String? img = profile?["imageUrl"];
    String? fullUrl;
    if (img != null && img.isNotEmpty) {
      final path = img.split("/api/v1/files").last;
      fullUrl = "$fileBaseUrl/api/proxy$path";
    }
    return Scaffold(
      appBar: AppBar(title: Text(myProfile.tr())),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
          ? Center(child: Text(profileLoadErrorK.tr()))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: fullUrl != null
                        ? NetworkImage(fullUrl)
                        : null,
                    child: fullUrl == null
                        ? Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                _field(lastNameK.tr(), profile!["lastname"]),
                _field(firstNameK.tr(), profile!["firstname"]),
                _field(patronymicK.tr(), profile!["patronymic"]),
                _field(phoneK.tr(), profile!["phone"]),
                _field(emailK.tr(), profile!["email"]),
                _field(identityNumberK.tr(), profile!["identityNumber"]),
                _field(
                  dateOfBirthK.tr(),
                  profile!["dateOfBirth"] != null
                      ? profile!["dateOfBirth"].toString().split("T").first
                      : "",
                ),
              ],
            ),
    );
  }

  Widget _field(String title, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(value ?? "-", style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
