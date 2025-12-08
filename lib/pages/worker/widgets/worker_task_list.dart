// worker_task_list.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:price_book/keys.dart';

import 'worker_task_utils.dart';

class WorkerTaskList extends StatelessWidget {
  final List<dynamic> tasks;
  final String locale;
  final Future<void> Function(Map<String, dynamic> task) onStartTask;
  final Future<void> Function(Map<String, dynamic> task) onCompleteTask;
  final Future<void> Function(Map<String, dynamic> task) onOpenTask;

  const WorkerTaskList({
    super.key,
    required this.tasks,
    required this.locale,
    required this.onStartTask,
    required this.onCompleteTask,
    required this.onOpenTask,
  });

  @override
  Widget build(BuildContext context) {
    final localTasks = List<Map<String, dynamic>>.from(
      tasks.map((e) => Map<String, dynamic>.from(e as Map)),
    );

    localTasks.sort((a, b) {
      final sa = getTaskDisplayStatus(a);
      final sb = getTaskDisplayStatus(b);
      return statusOrder(sa).compareTo(statusOrder(sb));
    });

    if (localTasks.isEmpty) {
      return Center(
        child: Text(
          tasksNotFound.tr(),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      itemCount: localTasks.length,
      itemBuilder: (context, index) {
        final t = localTasks[index];

        final allProducts = <String>{};
        for (var obj in (t["objects"] ?? [])) {
          for (var p in (obj["products"] ?? [])) {
            allProducts.add(getLocalized(p["name"], locale));
          }
        }

        bool isTodayTask = false;
        final rawDate = t['date'];
        if (rawDate != null) {
          try {
            final taskDate = DateTime.parse(rawDate.toString()).toLocal();
            isTodayTask = isSameDate(taskDate, DateTime.now());
          } catch (_) {
            isTodayTask = false;
          }
        }

        final status = getTaskDisplayStatus(t);

        String buttonText;
        Color buttonColor;
        VoidCallback? mainButtonOnPressed;

        if (status == 'pending') {
          buttonText = start.tr();
          buttonColor = Colors.blue;
          mainButtonOnPressed = () async {
            if (!isTodayTask) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    canDoTaskOnlyOnAssignedDay.tr(),
                  ),
                ),
              );
              return;
            }
            await onStartTask(t);
            await onOpenTask(t);
          };
        } else if (status == 'in_progress') {
          buttonText = continueK.tr();
          buttonColor = Colors.orange;
          mainButtonOnPressed = () async {
            if (!isTodayTask) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    canDoTaskOnlyOnAssignedDay.tr(),
                  ),
                ),
              );
              return;
            }
            await onOpenTask(t);
          };
        } else {
          buttonText = status == 'completedN' ? complete.tr() : completedF.tr();
          buttonColor = Colors.green;
          mainButtonOnPressed = null;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () async {
              if (!isTodayTask) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      canDoTaskOnlyOnAssignedDay.tr(),
                    ),
                  ),
                );
                return;
              }
              await onOpenTask(t);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${worker.tr()}: ${t["worker"]?["name"]?[locale] ?? t["worker"]?["name"]?["en"] ?? "Без имени"} (${t["worker"]?["phone"] ?? "??"})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${date.tr()}: ${t["date"].toString().split("T").first}",
                  ),
                  const SizedBox(height: 12),
                  Text(
                    objectsK.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...((t["objects"] ?? []) as List).map<Widget>((obj) {
                    final name = getLocalized(obj["name"], locale);
                    final address = getLocalized(obj["address"], locale);
                    return Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text("- $name, $address"),
                    );
                  }),
                  const SizedBox(height: 12),
                  Text(
                    "${productsK.tr()}:",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...allProducts.map(
                    (productName) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Text("- $productName"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: mainButtonOnPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                      ),
                      child: Text(buttonText),
                    ),
                  ),
                  if (status == 'in_progress') ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          if (!isTodayTask) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  canCompleteTaskOnlyOnAssignedDay.tr(),
                                ),
                              ),
                            );
                            return;
                          }
                          await onCompleteTask(t);
                        },
                        child: Text(completeTheTask.tr()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
