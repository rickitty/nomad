import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:price_book/keys.dart';
import 'package:price_book/pages/admin/task_details_page.dart';
import '../../config.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List tasks = [];
  bool loading = false;
  String phone = "";
  bool filteredByPhone = false;

  final Map<int, String> taskStatuses = {
    0: "None",
    1: "Assigned",
    2: "InProgress",
    3: "AwaitingReview",
    4: "Completed",
    5: "Canceled",
    6: "Stopped",
  };

  String getLocalized(dynamic data, String locale) {
    if (data == null || data is! Map) return "";
    return data[locale] ?? data["en"] ?? data.values.first.toString();
  }

  Future<void> loadAllTasks() async {
    setState(() => loading = true);

    try {
      final res = await http.get(
        Uri.parse(alltasks),
        headers: {
          "Authorization": "Bearer $bearerToken",
          "Content-Type": "application/json",
        },
      );
      print("=== RESPONSE START ===");
      print("STATUS: ${res.statusCode}");
      print("HEADERS: ${res.headers}");
      print("BODY: ${res.body}");
      print("=== RESPONSE END ===");

      if (res.statusCode == 200) {
        setState(() {
          tasks = jsonDecode(res.body);
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: ${res.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 15),
    );

    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  Future<void> updateTaskStatus(String taskId, int newStatus) async {
    try {
      final pos = await _getPosition();

      final body = {
        "status": newStatus,
        "lat": pos.latitude,
        "lng": pos.longitude,
      };

      final response = await http.put(
        Uri.parse("$baseUrl/tasks/$taskId/status"),
        headers: {
          "Authorization": "Bearer $bearerToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Статус успешно обновлён")),
        );
        loadAllTasks();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  void _showStatusDialog(String taskId) {
    showDialog(
      context: context,
      builder: (context) {
        int selected = 0;

        return AlertDialog(
          title: const Text("Изменить статус"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return DropdownButton<int>(
                value: selected,
                items: const [
                  DropdownMenuItem(value: 0, child: Text("0 - None")),
                  DropdownMenuItem(value: 1, child: Text("1 - Assigned")),
                  DropdownMenuItem(value: 2, child: Text("2 - InProgress")),
                  DropdownMenuItem(value: 3, child: Text("3 - AwaitingReview")),
                  DropdownMenuItem(value: 4, child: Text("4 - Completed")),
                  DropdownMenuItem(value: 5, child: Text("5 - Canceled")),
                  DropdownMenuItem(value: 6, child: Text("6 - Stopped")),
                ],
                onChanged: (value) {
                  setStateDialog(() => selected = value!);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                updateTaskStatus(taskId, selected);
              },
              child: const Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: searchByPhone.tr(),
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => phone = v,
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: loadAllTasks,
                  child: Text(allTasks.tr()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          if (loading) const CircularProgressIndicator(),

          Expanded(
            child: tasks.isEmpty && !loading
                ? Center(child: Text('Нет задач'))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final t = tasks[index];

                      final status = t["status"] ?? "Unknown";
                      final markets = t["markets"] ?? [];
                      final start =
                          t["startTime"]?.toString().split("T").first ?? "";
                      final end =
                          t["deadLine"]?.toString().split("T").first ?? "";

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ID + статус
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "ID: ${t["id"]}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showStatusDialog(t["id"]),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: status == "Completed"
                                            ? Colors.green
                                            : status == "Stopped"
                                            ? Colors.red
                                            : Colors.orange,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Даты
                              Text(
                                "Начало: $start",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "Дедлайн: $end",
                                style: const TextStyle(fontSize: 14),
                              ),

                              const SizedBox(height: 12),

                              // Маркеты
                              const Text(
                                "Маркеты:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),

                              ...markets.map<Widget>((m) {
                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Название: ${m["name"]}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text("Адрес: ${m["address"]}"),
                                      Text("Тип: ${m["type"]}"),
                                      Text("Часы работы: ${m["workHours"]}"),
                                    ],
                                  ),
                                );
                              }),

                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              TaskDetailsPage(taskId: t["id"]),
                                        ),
                                      );
                                    },
                                    child: const Text("Детали"),
                                  ),
                                  // IconButton(
                                  //   icon: const Icon(Icons.edit),
                                  //   onPressed: () async {
                                  //     await Navigator.push(
                                  //       context,
                                  //       MaterialPageRoute(
                                  //         builder: (_) => EditTaskPage(task: t),
                                  //       ),
                                  //     );
                                  //   },
                                  // ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
