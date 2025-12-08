import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import 'products_page.dart';

class WorkerTaskObjectsPage extends StatefulWidget {
  final String taskId;

  const WorkerTaskObjectsPage({super.key, required this.taskId});

  @override
  State<WorkerTaskObjectsPage> createState() => _WorkerTaskObjectsPageState();
}

class _WorkerTaskObjectsPageState extends State<WorkerTaskObjectsPage> {
  List<Map<String, dynamic>> taskObjects = [];
  bool loading = true;
  bool error = false;

  String getLocalized(Map<String, dynamic>? data, String locale) {
    if (data == null) return "";
    return data[locale] ?? data["en"] ?? data.values.first.toString();
  }

  Future<void> fetchTaskObjects() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/tasks/${widget.taskId}"),
        headers: {"Authorization": "Bearer $bearerToken"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> res = jsonDecode(response.body);
        if (res.isNotEmpty) {
          setState(() {
            taskObjects = res.cast<Map<String, dynamic>>();
            loading = false;
          });
        } else {
          setState(() {
            loading = false;
            taskObjects = [];
          });
        }
      } else {
        throw Exception("Ошибка загрузки: ${response.body}");
      }
    } catch (e) {
      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTaskObjects();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: const Text("Детали таска")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error
          ? const Center(child: Text("Ошибка загрузки"))
          : taskObjects.isEmpty
          ? const Center(child: Text("Нет данных"))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: taskObjects.map((task) {
                final marketId = task["marketId"] ?? "Неизвестно";
                final completedAt = task["completedAt"] ?? "";
                final goods = (task["goods"] as List?) ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Маркет: $marketId",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (completedAt.isNotEmpty)
                          Text("Завершён: $completedAt"),
                        const SizedBox(height: 8),
                        const Text(
                          "Товары:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ...goods.map((g) {
                          final name = getLocalized(g["name"], locale);
                          final completed = g["completed"] ?? false;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: Text("- $name")),
                                Icon(
                                  completed
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: completed ? Colors.green : Colors.grey,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkerObjectProductsPage(
                                  taskObjects: taskObjects,
                                  objectId: task["id"] ?? "",
                                ),
                              ),
                            );
                          },
                          child: const Text("Перейти к товарам"),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
