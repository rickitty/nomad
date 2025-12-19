import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:price_book/drawer.dart';
import 'package:price_book/keys.dart';
import 'package:price_book/pages/admin/task_details_page.dart';
import '../../config.dart';

const Color kPrimaryColor = Color.fromRGBO(144, 202, 249, 1);

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

  final Map<int, String> taskStatusKeys = {
    0: noneStatus,
    1: assignedStatus,
    2: inprogressStatus,
    3: awaitingreviewStatus,
    4: completedStatus,
    5: canceledStatus,
    6: stopedStatus,
  };

  String statusText(int code) => (taskStatusKeys[code] ?? noneStatus).tr();

  Color statusColor(int code) {
    switch (code) {
      case 4: // Completed
        return Colors.green;
      case 5: // Canceled
      case 6: // Stopped
        return Colors.red;
      case 2: // InProgress
      case 3: // AwaitingReview
        return Colors.orange;
      case 1: // Assigned
        return kPrimaryColor;
      default:
        return Colors.grey;
    }
  }

  int _parseStatusCode(dynamic raw) {
    if (raw is int) return raw;

    final s = (raw ?? "").toString();

    final n = int.tryParse(s);
    if (n != null) return n;

    switch (s) {
      case "Assigned":
        return 1;
      case "InProgress":
        return 2;
      case "AwaitingReview":
        return 3;
      case "Completed":
        return 4;
      case "Canceled":
        return 5;
      case "Stopped":
        return 6;
      default:
        return 0;
    }
  }

  Future<void> loadAllTasks() async {
    setState(() => loading = true);

    try {
      final headers = await Config.authorizedJsonHeaders();

      if (!headers.containsKey('Authorization')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(token_not_found.tr())));
        return;
      }

      final res = await http.get(
        Uri.parse("$QYZ_API_BASE/task"),
        headers: headers,
      );

      if (res.statusCode == 200) {
        setState(() {
          tasks = jsonDecode(utf8.decode(res.bodyBytes));
          filteredByPhone = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${errorLoading.tr()}: ${res.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${error.tr()}: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<Position?> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 15),
    );

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateTaskStatus(String taskId, int newStatus) async {
    try {
      final pos = await _getPosition();

      final body = <String, dynamic>{
        "status": newStatus,
        if (pos != null) "lat": pos.latitude,
        if (pos != null) "lng": pos.longitude,
      };

      final headers = await Config.authorizedJsonHeaders();

      if (!headers.containsKey('Authorization')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(token_not_found.tr())));
        return;
      }

      final response = await http.put(
        Uri.parse("$QYZ_API_BASE/task/$taskId"),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(status_updated.tr())));
        loadAllTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${error.tr()}: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${error.tr()}: $e")));
    }
  }

  void _showStatusDialog(String taskId, int currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        int selected = currentStatus;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            ChangeStatus.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return DropdownButtonFormField<int>(
                value: selected,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: taskStatusKeys.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text("${e.key} - ${e.value.tr()}"),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setStateDialog(() => selected = value);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(cancel.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                updateTaskStatus(taskId, selected);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(save.tr()),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _searchDecoration() {
    return InputDecoration(
      labelText: searchByPhone.tr(),
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const AppDrawer(current: DrawerRoute.taskList),
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: Text(
          ChangeStatus.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: _searchDecoration(),
                onChanged: (v) => phone = v,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: loadAllTasks,
                  icon: const Icon(Icons.list),
                  label: Text(allTasks.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(kPrimaryColor),
                  ),
                ),
              Expanded(
                child: tasks.isEmpty && !loading
                    ? Center(
                        child: Text(
                          tasksNotFound.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final t = tasks[index];

                          final String taskId = (t["id"] ?? "").toString();
                          final int statusCode = _parseStatusCode(t["status"]);
                          final String statusLabel = statusText(statusCode);
                          final Color color = statusColor(statusCode);

                          final markets = (t["markets"] as List?) ?? [];

                          final start =
                              t["startTime"]?.toString().split("T").first ?? "";
                          final end =
                              t["deadLine"]?.toString().split("T").first ?? "";

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${tasksK.tr()}: ${index + 1}/${tasks.length}",
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _showStatusDialog(
                                          taskId,
                                          statusCode,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 10,
                                                color: color,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                statusLabel,
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: color,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "${startedAt.tr()}: $start",
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    "${deadline.tr()}: $end",
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "${Markets.tr()}:",
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  ...markets.map<Widget>((m) {
                                    final nameValue = (m["name"] ?? "")
                                        .toString();
                                    final addressValue = (m["address"] ?? "")
                                        .toString();
                                    final typeValue = (m["type"] ?? "")
                                        .toString();
                                    final workHoursValue =
                                        (m["workHours"] ?? "").toString();

                                    return Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${name.tr()}: $nameValue",
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          if (addressValue.isNotEmpty)
                                            Text(
                                              "${Address.tr()}: $addressValue",
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey[700],
                                                  ),
                                            ),
                                          Text(
                                            "${Type.tr()}: $typeValue",
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[700],
                                                ),
                                          ),
                                          Text(
                                            "${WorkHours.tr()}: $workHoursValue",
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[700],
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),

                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TaskDetailsPage(
                                              taskId: taskId,
                                              taskNumber: index + 1,
                                              totalTasks: tasks.length,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.arrow_forward),
                                      label: Text(taskDetails.tr()),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color.fromARGB(
                                          255,
                                          58,
                                          88,
                                          113,
                                        ),
                                      ),
                                    ),
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
        ),
      ),
    );
  }
}
