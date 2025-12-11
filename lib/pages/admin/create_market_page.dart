import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:price_book/config.dart';
import 'package:price_book/keys.dart';

class CreateMarketPage extends StatefulWidget {
  const CreateMarketPage({super.key});

  @override
  State<CreateMarketPage> createState() => _CreateMarketPageState();
}

class _CreateMarketPageState extends State<CreateMarketPage> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _accuracy = TextEditingController();
  final _type = TextEditingController();
  final _workHours = TextEditingController();

  bool loading = false;

  Future<void> createMarket() async {
  setState(() => loading = true);

  if (QYZ_API_BASE.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ошибка: базовый URL не задан")),
    );
    setState(() => loading = false);
    return;
  }
  if (Config.bearerToken.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ошибка: токен не задан")),
    );
    setState(() => loading = false);
    return;
  }

  final Map<String, dynamic> body = {
    "name": _name.text,
    "address": _address.text,
    "location": {
      "lng": double.tryParse(_lng.text) ?? 0,
      "lat": double.tryParse(_lat.text) ?? 0,
    },
    "geoAccuracy": double.tryParse(_accuracy.text) ?? 0,
    "type": _type.text,
    "workHours": _workHours.text,
  };

  final uri = Uri.parse("$QYZ_API_BASE/market/create");
  final headers = <String, String>{
    "Content-Type": "application/json",
    "Authorization": "Bearer ${Config.bearerToken}",
  };
  final jsonBody = jsonEncode(body);

  print("=== CREATE MARKET REQUEST ===");
  print("URL: $uri");
  print("HEADERS: $headers");
  print("BODY: $jsonBody");

  final curl = """
curl -X POST '$uri' \\
  -H 'Content-Type: application/json' \\
  -H 'Authorization: Bearer ${Config.bearerToken}' \\
  -d '$jsonBody'
""";
  print("CURL:\n$curl");

  try {
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonBody,
    );

    final bodyStr = utf8.decode(response.bodyBytes);

    print("=== CREATE MARKET RESPONSE ===");
    print("STATUS: ${response.statusCode}");
    print("BODY: $bodyStr");


    dynamic data;
    if (bodyStr.isNotEmpty) {
      try {
        data = json.decode(bodyStr);
      } catch (_) {
        data = bodyStr; 
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(succsessfulCreateMarket.tr())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка: ${data ?? bodyStr}"),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ошибка сети: $e")),
    );
  }

  setState(() => loading = false);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Market")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: name.tr()),
            ),
            TextField(
              controller: _address,
              decoration: InputDecoration(labelText: Address.tr()),
            ),
            TextField(
              controller: _lat,
              decoration:  InputDecoration(labelText: Latitude.tr()),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _lng,
              decoration:  InputDecoration(labelText: Longitude.tr()),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _accuracy,
              decoration:  InputDecoration(labelText: GeoAccuracy.tr()),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _type,
              decoration:  InputDecoration(labelText: Type.tr()),
            ),
            TextField(
              controller: _workHours,
              decoration:  InputDecoration(labelText: WorkHours.tr()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : createMarket,
              child: loading
                  ? const CircularProgressIndicator()
                  :  Text(Create.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
