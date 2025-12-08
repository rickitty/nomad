import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
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
  List workers = [];
  List workerMarkets = [];

  String? selectedWorkerId;
  String? selectedWorkerPhone;
  List<String> selectedMarketIds = [];

  List<String> selectedMarketNames = [];

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    loadWorkers();
  }

  // ===================== LOAD WORKERS =====================
  Future<void> loadWorkers() async {
    final res = await http.get(Uri.parse(workersUrl));

    if (res.statusCode == 200) {
      setState(() {
        workers = jsonDecode(res.body);
      });
    } else {
      print("Failed to load workers: ${res.body}");
    }
  }

  // ===================== SAVE TASK =====================
  Future<void> saveTask() async {
    if (selectedWorkerPhone == null ||
        selectedMarketIds.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Заполните все поля")));
      return;
    }

    final correctedDate = selectedDate!.add(const Duration(hours: 5));

    final body = {
      "phoneNumber": selectedWorkerPhone,
      "marketIds": selectedMarketIds, // <-- теперь ID
      "deadLine": correctedDate.toIso8601String(),
    };

    print("Sending: $body");

    final res = await http.post(
      Uri.parse(createTaskUrl),
      headers: {
        "Authorization": "Bearer $bearerToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("Response: ${res.body}");

    if (res.statusCode == 201 || res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Задача создана")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: ${res.body}")));
    }
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Создать задачу")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ---------------- WORKER SELECT ----------------
            DropdownSearch<Map<String, dynamic>>(
              items: (String filter, _) async {
                return workers
                    .where((w) => (w["phone"] ?? "").contains(filter))
                    .map((e) => e as Map<String, dynamic>)
                    .toList();
              },
              selectedItem: selectedWorkerId != null
                  ? workers.firstWhere(
                      (w) => w["_id"] == selectedWorkerId,
                      orElse: () => {},
                    )
                  : null,
              compareFn: (a, b) => a["_id"] == b["_id"],
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: const InputDecoration(labelText: "Поиск..."),
                ),
                itemBuilder: (_, item, __, ___) {
                  return ListTile(title: Text(item["phone"] ?? ""));
                },
              ),
              dropdownBuilder: (_, item) =>
                  Text(item == null ? "Выберите работника" : item["phone"]),
              onChanged: (v) {
                if (v == null) return;

                setState(() {
                  selectedWorkerId = v["_id"];
                  selectedWorkerPhone = v["phone"];

                  workerMarkets = (v["markets"] is List)
                      ? List<Map<String, dynamic>>.from(v["markets"])
                      : [];

                  selectedMarketNames = [];
                });

                print("Worker markets: $workerMarkets");
              },
            ),

            const SizedBox(height: 12),

            // ---------------- MARKETS LIST ----------------
            Expanded(
              child: ListView(
                children: workerMarkets.map((m) {
                  final marketId = m["_id"];
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
