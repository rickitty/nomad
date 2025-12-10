import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';

class TaskDetailsPage extends StatelessWidget {
  final String taskId;

  const TaskDetailsPage({super.key, required this.taskId});

  String getLocalized(Map<String, dynamic>? data, String locale) {
    if (data == null) return "";
    return data[locale] ?? data["en"] ?? data.values.first.toString();
  }

  Future<List<Map<String, dynamic>>> fetchTask() async {
    final response = await http.get(
      Uri.parse("$QYZ_API_BASE/task/$taskId"),
      headers: {
        "Authorization": "Bearer ${Config.bearerToken}",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return [data]; 
    } else {
      throw Exception("Ошибка загрузки: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: const Text("Детали таска")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTask(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}"));
          }

          final taskList = snapshot.data!;
          if (taskList.isEmpty) return const Center(child: Text("Нет данных"));

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                "ID таска: ${taskList[0]["id"]}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              // Показываем каждый маркет как отдельную карточку
              ...taskList.map((task) {
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
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
