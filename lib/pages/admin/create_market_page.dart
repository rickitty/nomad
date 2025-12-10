import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:price_book/config.dart';

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

    // Проверка URL и токена
    if (QYZ_API_BASE.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ошибка: базовый URL не задан")),
      );
      setState(() => loading = false);
      return;
    }
    if (Config.bearerToken.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ошибка: токен не задан")));
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

    try {
      final response = await http.post(
        Uri.parse("$QYZ_API_BASE/market/create"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${Config.bearerToken}",
        },
        body: json.encode(body),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Маркет успешно создан!")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка: ${data}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка сети: $e")));
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
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: "Address"),
            ),
            TextField(
              controller: _lat,
              decoration: const InputDecoration(labelText: "Latitude"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _lng,
              decoration: const InputDecoration(labelText: "Longitude"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _accuracy,
              decoration: const InputDecoration(labelText: "Geo Accuracy"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _type,
              decoration: const InputDecoration(labelText: "Type"),
            ),
            TextField(
              controller: _workHours,
              decoration: const InputDecoration(labelText: "Work Hours"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : createMarket,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }
}
