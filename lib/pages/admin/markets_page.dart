import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:price_book/config.dart';
import 'dart:convert';
import 'create_market_page.dart';

class MarketsPage extends StatefulWidget {
  const MarketsPage({super.key});

  @override
  State<MarketsPage> createState() => _MarketsPageState();
}

class _MarketsPageState extends State<MarketsPage> {
  List markets = [];
  bool loading = true;

  Future<void> loadMarkets() async {
    setState(() => loading = true);

    try {
      final response = await http.get(
        Uri.parse(
          "$QYZ_API_BASE/markets",
        ),
        headers: {'Authorization': 'Bearer ${Config.bearerToken}'},
      );

      if (response.statusCode == 200) {
        markets = json.decode(utf8.decode(response.bodyBytes));
      } else {
        print(
          "Ошибка при загрузке рынков: ${response.statusCode} ${response.body}",
        );
        markets = [];
      }
    } catch (e) {
      print("Exception при загрузке рынков: $e");
      markets = [];
    }

    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    loadMarkets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Markets")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateMarketPage()),
          );
          loadMarkets();
        },
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: markets.length,
              itemBuilder: (context, index) {
                final m = markets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(m["name"] ?? ""),
                    subtitle: Text(m["address"] ?? ""),
                    trailing: Column(
                      children: [
                        Text(m["type"] ?? ""),
                        Text(m["workHours"] ?? ""),
                        Text(m["id"] ?? ""),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
