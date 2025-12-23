import 'dart:async';
import 'dart:convert';
import 'package:price_book/pages/widgets/dateFilter.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:price_book/api_client.dart';
import 'package:price_book/pages/widgets/drawer.dart';
import 'package:price_book/keys.dart';

import 'markets_page.dart';

const Color kPrimaryColor = Color.fromRGBO(144, 202, 249, 1);

class WorkerPage extends StatefulWidget {
  const WorkerPage({super.key});
  @override
  State<WorkerPage> createState() => _WorkerPageState();
}

class _WorkerPageState extends State<WorkerPage> {
  List tasks = [];
  bool loading = false;
  String phone = "";

  // ===== Calendar filter (toggle) =====
  DateTime? _filterDay; // null = фильтр выключен

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime safeParse(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  DateTime taskDate(dynamic t) {
    // Поменяй порядок, если у тебя приоритет другой
    return safeParse(t["createdAt"] ?? t["startTime"] ?? t["deadLine"]);
  }

  void onCalendarTap(DateTime day) {
    setState(() {
      if (_filterDay != null && _isSameDay(_filterDay!, day)) {
        _filterDay = null; // нажали ту же дату второй раз — выключить
      } else {
        _filterDay = day; // включить
      }
    });
  }

  List get visibleTasks {
    final list = List.of(tasks);

    list.sort((a, b) => taskDate(b).compareTo(taskDate(a)));

    if (_filterDay == null) return list;

    final d = _dateOnly(_filterDay!);
    return list.where((t) => _isSameDay(_dateOnly(taskDate(t)), d)).toList();
  }

  Future<void> loadAllTasks() async {
    setState(() => loading = true);

    try {
      final res = await ApiClient.get('/task', context);

      if (res.statusCode == 200) {
        final List list = jsonDecode(utf8.decode(res.bodyBytes));

        list.sort((a, b) => taskDate(b).compareTo(taskDate(a)));

        if (!mounted) return;
        setState(() {
          tasks = list;
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
      if (mounted) setState(() => loading = false);
    }
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

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

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  Future<void> _openTask(String taskId, int statusCode) async {
    final canOpen = await autoChangeStatus(taskId, statusCode);
    if (!canOpen) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerTaskObjectsPage(taskId: taskId),
      ),
    );

    await loadAllTasks();
  }

  Future<bool> autoChangeStatus(String taskId, int currentStatus) async {
    if (currentStatus != 1) return true;

    Position pos;
    try {
      pos = await _getPosition();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось получить геопозицию: $e')),
      );
      return false;
    }

    final body = {"status": 2, "lat": pos.latitude, "lng": pos.longitude};

    try {
      print(body);
      final response = await ApiClient.put('/task/$taskId', context, body);

      if (response.statusCode == 200) {
        return true;
      } else {
        String message = statusEr.tr();
        try {
          final jsonBody = jsonDecode(response.body);
          if (jsonBody["error"]?["message"] != null) {
            message = jsonBody["error"]["message"];
          }
        } catch (_) {}

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${error.tr()}: $e")));
      return false;
    }
  }

  Future<void> _updateTaskStatus(String taskId, int newStatus) async {
    try {
      final pos =
          await _getPosition(); // можно отправлять координаты, как в autoChangeStatus

      final body = <String, dynamic>{
        "status": newStatus,
        if (pos != null) "lat": pos.latitude,
        if (pos != null) "lng": pos.longitude,
      };

      final response = await ApiClient.put('/task/$taskId', context, body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(status_updated.tr())));
        await loadAllTasks();
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
                _updateTaskStatus(taskId, selected);
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadAllTasks());
  }

  int parseStatus(dynamic rawStatus) {
    if (rawStatus is int) return rawStatus;

    final s = (rawStatus ?? "").toString();
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

  // КЛЮЧИ локализации (без .tr() тут)
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
      case 4:
        return Colors.green;
      case 5:
      case 6:
        return Colors.red;
      case 2:
      case 3:
        return Colors.orange;
      case 1:
        return kPrimaryColor;
      default:
        return Colors.grey;
    }
  }

  Widget buildStatusBadge(int code, String taskId) {
    final color = statusColor(code);
    final label = statusText(code);

    return GestureDetector(
      onTap: () => _showStatusDialog(taskId, code), // ручная смена
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = visibleTasks;

    return Scaffold(
      drawer: const AppDrawer(current: DrawerRoute.worker),
      appBar: AppBar(
        title: Text(tasksK.tr()),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade200, kPrimaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: reload.tr(),
            onPressed: loading ? null : loadAllTasks,
            icon: AnimatedRotation(
              turns: loading ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade200, kPrimaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: WeekCalendarFilter(
              selectedDay: _filterDay,
              onDayTap: onCalendarTap,
              selectedColor: Colors.black,
              todayColor: const Color.fromARGB(255, 54, 95, 244),
              pillColor: Colors.white.withOpacity(0.85),
            ),
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : tasks.isEmpty
                        ? Center(
                            key: const ValueKey("empty"),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.inbox_rounded,
                                  size: 56,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  noTasks.tr(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pullToRefresh.tr(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : shown.isEmpty
                        ? Center(
                            key: const ValueKey("filtered_empty"),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.event_busy_rounded,
                                  size: 56,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Нет задач на выбранную дату",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Нажми на эту дату ещё раз, чтобы отключить фильтр",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            key: const ValueKey("list"),
                            onRefresh: loadAllTasks,
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              itemCount: shown.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final t = shown[index];
                                final formatter = DateFormat('dd.MM.yyyy');

                                final int code = parseStatus(t["status"]);
                                final markets = (t["markets"] as List?) ?? [];

                                final start = t["startTime"] != null
                                    ? formatter.format(
                                        DateTime.parse(t["startTime"]),
                                      )
                                    : "";

                                final end = t["deadLine"] != null
                                    ? formatter.format(
                                        DateTime.parse(t["deadLine"]),
                                      )
                                    : "";

                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(
                                    milliseconds: 250 + index * 40,
                                  ),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 16 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 6,
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    Colors.blue.shade100,
                                                child: Icon(
                                                  Icons.assignment_rounded,
                                                  size: 20,
                                                  color: Colors.blue.shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${tasksK.tr()} : ${index + 1}/${shown.length}",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      "${objectsK.tr()}: ${markets.length}",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              buildStatusBadge(
                                                code,
                                                t["id"].toString(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.play_arrow_rounded,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${startedAt.tr()}: $start",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.flag_rounded,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${deadline.tr()}: $end",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          if (markets.isNotEmpty)
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Theme(
                                                data: Theme.of(context)
                                                    .copyWith(
                                                      dividerColor:
                                                          Colors.transparent,
                                                    ),
                                                child: ExpansionTile(
                                                  tilePadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                      ),
                                                  childrenPadding:
                                                      const EdgeInsets.only(
                                                        bottom: 8,
                                                        right: 10,
                                                        left: 10,
                                                      ),
                                                  title: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.storefront,
                                                        size: 18,
                                                        color: Colors.blue,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "${Markets.tr()} (${markets.length})",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  children: [
                                                    ...markets.map<Widget>((m) {
                                                      return Container(
                                                        margin:
                                                            const EdgeInsets.only(
                                                              top: 6,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .blue
                                                              .shade50,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              "${name.tr()}: ${m["name"]}",
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            if ((m["address"] ??
                                                                    "")
                                                                .toString()
                                                                .isNotEmpty)
                                                              Text(
                                                                "${Address.tr()}: ${m["address"]}",
                                                              ),
                                                            if (m["type"] !=
                                                                null)
                                                              Text(
                                                                "${Type.tr()}: ${m["type"]}",
                                                              ),
                                                            if (m["workHours"] !=
                                                                null)
                                                              Text(
                                                                "${WorkHours.tr()}: ${m["workHours"]}",
                                                              ),
                                                          ],
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: SizedBox(
                                              height: 40,
                                              child: ElevatedButton.icon(
                                                onPressed: () => _openTask(
                                                  t["id"].toString(),
                                                  code,
                                                ),
                                                icon: const Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  size: 16,
                                                ),
                                                label: Text(open.tr()),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blue[300],
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
