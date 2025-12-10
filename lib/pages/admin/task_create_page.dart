import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import '../../config.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  List markets = [];
  bool loadingMarkets = true;

  String selectedWorkerPhone = "77753513132"; // статический воркер
  List<String> selectedMarketIds = [];
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    loadMarkets();
  }

  Future<void> loadMarkets() async {
    setState(() => loadingMarkets = true);
    final response = await http.get(
      Uri.parse("$QYZ_API_BASE/markets"),
      headers: {'Authorization': 'Bearer ${Config.bearerToken}'},
    );

    if (response.statusCode == 200) {
      markets = json.decode(utf8.decode(response.bodyBytes));
    }

    setState(() => loadingMarkets = false);
  }

  Future<void> saveTask() async {
    if (selectedMarketIds.isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Заполните все поля")));
      return;
    }

    final correctedDate = selectedDate!.add(const Duration(hours: 5));

    final body = {
      "phoneNumber": selectedWorkerPhone,
      "marketIds": selectedMarketIds,
      "deadLine": correctedDate.toIso8601String(),
    };

    try {
      final res = await http.post(
        Uri.parse(
          "$QYZ_API_BASE/task/create",
        ), // прямой URL
        headers: {
          "Authorization": "Bearer ${Config.bearerToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Задача создана")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка: ${res.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Создать задачу")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ---------------- WORKER ----------------
            Text(
              "Работник: $selectedWorkerPhone",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // ---------------- MARKETS LIST ----------------
            loadingMarkets
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView(
                      children: markets.map((m) {
                        final marketId = m["id"];
                        final checked = selectedMarketIds.contains(marketId);

                        return CheckboxListTile(
                          title: Text(m["name"] ?? "—"),
                          subtitle: Text(m["address"] ?? ""),
                          value: checked,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                selectedMarketIds.add(marketId);
                              } else {
                                selectedMarketIds.remove(marketId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

            const SizedBox(height: 8),

            // ---------------- DATE PICKER ----------------
            OutlinedButton(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: now,
                  lastDate: DateTime(now.year + 2),
                );

                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Text(
                selectedDate == null
                    ? "Выберите дедлайн"
                    : "Дедлайн: ${DateFormat('dd.MM.yyyy').format(selectedDate!)}",
              ),
            ),

            const SizedBox(height: 12),

            // ---------------- SAVE BUTTON ----------------
            ElevatedButton(
              onPressed: saveTask,
              child: const Text("Создать задачу"),
            ),
          ],
        ),
      ),
    );
  }
}
