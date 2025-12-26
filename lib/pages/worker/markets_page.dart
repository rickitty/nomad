import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:price_book/api_client.dart';
import 'package:price_book/keys.dart';
import 'package:price_book/pages/widgets/dialogError.dart';
import 'package:price_book/pages/widgets/loading_dialog.dart';
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
  List tasks = [];

  String getLocalized(Map<String, dynamic>? data, String locale) {
    if (data == null) return "";
    return data[locale] ?? data["en"] ?? data.values.first.toString();
  }

  Future<void> fetchTaskObjects() async {
    setState(() => loading = true);

    try {
      final response = await ApiClient.get('/task/${widget.taskId}', context);

      if (response.statusCode == 200) {
        final List<dynamic> res = jsonDecode(response.body);
        setState(() {
          taskObjects = res.isNotEmpty ? res.cast<Map<String, dynamic>>() : [];
          loading = false;
          error = false;
        });
        _checkAndUpdateMainTaskStatus();
      } else {
        throw Exception("${errorLoading.tr()}: ${response.body}");
      }
    } catch (e) {
      setState(() {
        loading = false;
        error = true;
      });
      debugPrint("fetchTaskObjects exception: $e");
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

  Future<void> loadAllTasks() async {
    setState(() => loading = true);

    try {
      final res = await ApiClient.get('/task', context);

      if (res.statusCode == 200) {
        final List list = jsonDecode(utf8.decode(res.bodyBytes));

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

  String? getMainTaskStatusById(String taskId, List tasks) {
    try {
      final task = tasks.firstWhere((t) => t["id"] == taskId);
      return task["status"]?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateTaskStatus(String taskId, int status) async {
    try {
      final pos = await _getPosition();

      final body = <String, dynamic>{
        "status": status,
        if (pos != null) "lat": pos.latitude,
        if (pos != null) "lng": pos.longitude,
      };

      await ApiClient.put('/task/$taskId', context, body);
    } catch (e) {
      debugPrint("updateTaskStatus error: $e");
    } finally {
      hideLoadingDialog(context);
    }
  }

  void _checkAndUpdateMainTaskStatus() {
    if (taskObjects.isEmpty || tasks.isEmpty) return;

    final status = getMainTaskStatusById(widget.taskId, tasks);
    if (status == null) return;

    final allCompleted = taskObjects.every((t) => t["status"] == "Completed");
    final allCanceled = taskObjects.every((t) => t["status"] == "Canceled");
    final allStopped = taskObjects.every((t) => t["status"] == "Stopped");

    if (allCompleted && status != "Completed") {
      showLoadingDialog(context, text: updatingStatus.tr());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTaskStatus(widget.taskId, 4);
      });
    } else if (allCanceled && status != "Canceled") {
      showLoadingDialog(context, text: updatingStatus.tr());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTaskStatus(widget.taskId, 5);
      });
    } else if (allStopped && status != "Stopped") {
      showLoadingDialog(context, text: updatingStatus.tr());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTaskStatus(widget.taskId, 6);
      });
    }
  }

  Future<void> updateTaskDetailStatus(
    String taskDetailId,
    int newStatus,
  ) async {
    try {
      showLoadingDialog(context, text: updatingStatus.tr());
      final pos = await _getPosition();

      final body = <String, dynamic>{
        "status": newStatus,
        if (pos != null) "lat": pos.latitude,
        if (pos != null) "lng": pos.longitude,
      };

      final responce = await ApiClient.put(
        '/task/detail/$taskDetailId',
        context,
        body,
      );
      if (responce.statusCode == 200) {
        fetchTaskObjects();
        return jsonDecode(responce.body);
      } else {
        await AppDialogs.error(context, 'Error: ${responce.body}');
      }
    } catch (e) {
      await AppDialogs.error(context, 'Error: $e');
    } finally {
      hideLoadingDialog(context);
    }
  }

  @override
  void initState() {
    super.initState();
    loadAllTasks().then((_) {
      fetchTaskObjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(taskDetails.tr()),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade200, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 255, 255, 255), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error
                ? Center(
                    key: const ValueKey("error"),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          errorLoading.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: fetchTaskObjects,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(confirm.tr()),
                        ),
                      ],
                    ),
                  )
                : taskObjects.isEmpty
                ? Center(
                    key: const ValueKey("empty"),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          size: 56,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          noData.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          noObjects.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  objectsK.tr(),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${allobj.tr()}: ${taskObjects.length}",
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            IconButton(
                              tooltip: reload.tr(),
                              onPressed: fetchTaskObjects,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // List
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: fetchTaskObjects,
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            itemCount: taskObjects.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final task = taskObjects[index];
                              final status = task["status"]?.toString() ?? "";
                              final marketId =
                                  task["marketId"]?.toString() ?? "";
                              final completedAt =
                                  task["completedAt"]?.toString() ?? "";
                              final goods = (task["goods"] as List?) ?? [];
                              final totalGoods = goods.length;
                              final completedCount = goods
                                  .where((g) => (g as Map)["completed"] == true)
                                  .length;
                              final double progress = totalGoods == 0
                                  ? 0
                                  : completedCount / totalGoods;
                              if (totalGoods > 0 &&
                                  completedCount == totalGoods &&
                                  status != "Completed" &&
                                  status != "Stopped" &&
                                  status != "Canceled") {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  updateTaskDetailStatus(
                                    task["id"].toString(),
                                    3,
                                  );
                                });
                              }

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
                                  elevation: 5,
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          const Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header row: icon + market id + completedAt
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                              child: const Icon(
                                                Icons.storefront,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${Market}: $marketId",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (status == "Completed")
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 2,
                                                          ),
                                                      child: Text(
                                                        "${complete.tr()}: $completedAt",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.green[700],
                                                        ),
                                                      ),
                                                    ),
                                                  if (totalGoods > 0)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 4,
                                                          ),
                                                      child: Text(
                                                        "${productsK.tr()}: $totalGoods, ${completeV.tr()}: $completedCount",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            if (status != "Stopped" &&
                                                status != "Canceled" &&
                                                status != "Completed")
                                              Row(
                                                children: [
                                                  IconButton(
                                                    tooltip: stop.tr(),
                                                    onPressed: () async {
                                                      await updateTaskDetailStatus(
                                                        task["id"].toString(),
                                                        4,
                                                      );

                                                      setState(() {});
                                                    },

                                                    icon: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.pause,
                                                        size: 18,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),

                                                  IconButton(
                                                    tooltip: cancel.tr(),
                                                    onPressed: () async {
                                                      final confirm =
                                                          await showCancelConfirmDialog();
                                                      if (!confirm) return;

                                                      await updateTaskDetailStatus(
                                                        task["id"].toString(),
                                                        5,
                                                      );

                                                      setState(() {});
                                                    },

                                                    icon: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.close,
                                                        size: 18,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),

                                        if (totalGoods > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                              bottom: 4,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 6,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      progress >= 1
                                                          ? Colors.green
                                                          : Colors.blueAccent,
                                                    ),
                                              ),
                                            ),
                                          ),

                                        const SizedBox(height: 8),

                                        Text(
                                          productK.tr(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // Goods list
                                        if (goods.isEmpty)
                                          Text(
                                            noData.tr(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          )
                                        else
                                          ...goods.map<Widget>((g) {
                                            final name = getLocalized(
                                              g["name"],
                                              locale,
                                            );
                                            final completed =
                                                g["completed"] ?? false;

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: completed
                                                    ? Colors.green.withOpacity(
                                                        0.08,
                                                      )
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: completed
                                                      ? Colors.green
                                                      : Colors.blue.shade100,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name.isEmpty
                                                          ? "- ${noNameM.tr()}"
                                                          : "- $name",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    completed
                                                        ? Icons.check_circle
                                                        : Icons
                                                              .radio_button_unchecked,
                                                    color: completed
                                                        ? Colors.green
                                                        : Colors.grey,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),

                                        const SizedBox(height: 10),

                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: buildActionButton(
                                            status: status,
                                            task: task,
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
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<bool> showCancelConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text(cancelAnyway.tr()),
                ],
              ),
              content: Text(
                "${sureYouWannaCancelTask.tr()}\n\n"
                "${afterCancelTaskClosedForever.tr()}, "
                "${resumingWillBeImpossible.tr()}.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(no.tr()),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(cancel.tr()),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget buildActionButton({required String status, required Map task}) {
    // ❌ Отменено
    if (status == "Canceled") {
      return Text(
        taskCanceled.tr(),
        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
      );
    }

    // ✅ Завершено
    if (status == "Completed") {
      return ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkerObjectProductsPage(
              taskId: widget.taskId,
              objectId: task["id"],
            ),
          ),
        ),
        child: Text(complete.tr()),
      );
    }

    // ⏸ Остановлено
    if (status == "Stopped") {
      return ElevatedButton(
        onPressed: () async {
          await updateTaskDetailStatus(task["id"].toString(), 2); // InProgress
          await fetchTaskObjects();
        },
        child: Text(resume.tr()),
      );
    }

    // ▶ Assigned / InProgress
    return ElevatedButton.icon(
      icon: const Icon(Icons.arrow_forward_ios, size: 16),
      label: Text(ktavaram.tr()),
      onPressed: () async {
        if (status == "Assigned") {
          await updateTaskDetailStatus(task["id"].toString(), 2);
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkerObjectProductsPage(
              taskId: widget.taskId,
              objectId: task["id"],
            ),
          ),
        );

        fetchTaskObjects();
      },
    );
  }
}
