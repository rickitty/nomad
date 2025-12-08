import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:price_book/drawer.dart';
import '../../config.dart';
import 'objects_page.dart';

class WorkerPage extends StatefulWidget {
  const WorkerPage({super.key});
  @override
  State<WorkerPage> createState() => _WorkerPageState();
}

class _WorkerPageState extends State<WorkerPage> {
  List tasks = [];
  bool loading = false;
  String phone = "";

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
    if (!serviceEnabled) throw Exception('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw Exception('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  Future<void> _openTask(String taskId, int status) async {
    bool canOpen = await autoChangeStatus(taskId, status);
    if (!canOpen)
      return; 

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerTaskObjectsPage(taskId: taskId),
      ),
    );

    await loadAllTasks();
  }

  Future<bool> autoChangeStatus(String taskId, int currentStatus) async {
    if (currentStatus != 1)
      return true; // Assigned, если не Assigned, пропускаем проверку

    final pos = await _getPosition();

    final body = {
      "status": 2, // InProgress
      "lat": pos.latitude,
      "lng": pos.longitude,
    };

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/tasks/$taskId/status"),
        headers: {
          "Authorization": "Bearer $bearerToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true; // Успешно
      } else {
        // Получаем сообщение ошибки
        String message = "Ошибка обновления статуса";
        try {
          final jsonBody = jsonDecode(response.body);
          if (jsonBody["error"] != null &&
              jsonBody["error"]["message"] != null) {
            message = jsonBody["error"]["message"];
          }
        } catch (_) {}

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));

        return false; // Не удалось обновить
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadAllTasks();
    });
  }

  int parseStatus(dynamic rawStatus) {
    if (rawStatus is int) return rawStatus;
    if (rawStatus is String) {
      switch (rawStatus) {
        case "Assigned":
          return 1;
        case "InProgress":
          return 2;
        case "Completed":
          return 3;
        case "Stopped":
          return 4;
        case "Canceled":
          return 5;
        default:
          return 0;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(title: const Text("Задачи")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : tasks.isEmpty
            ? const Center(child: Text("Нет задач"))
            : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final t = tasks[index];
                  final int status = parseStatus(t["status"]);
                  final markets = t["markets"] ?? [];
                  final start =
                      t["startTime"]?.toString().split("T").first ?? "";
                  final end = t["deadLine"]?.toString().split("T").first ?? "";

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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "ID: ${t["id"]}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              buildStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("Начало: $start"),
                          Text("Дедлайн: $end"),
                          const SizedBox(height: 8),
                          const Text(
                            "Маркеты:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...markets.map<Widget>(
                            (m) => Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () => _openTask(t["id"], status),
                              child: const Text("Детали"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

Widget buildStatusBadge(int status) {
  Color color;
  final Map<int, String> taskStatuses = {
    1: "Assigned",
    2: "InProgress",
    3: "Completed",
    4: "Stopped",
    5: "Canceled",
  };
  switch (status) {
    case 3:
      color = Colors.green;
      break;
    case 4:
    case 5:
      color = Colors.red;
      break;
    case 2:
      color = Colors.orange;
      break;
    default:
      color = Colors.blue;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      taskStatuses[status] ?? "Unknown",
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}
