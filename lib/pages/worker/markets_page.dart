import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:price_book/api_client.dart';
import 'package:price_book/keys.dart';
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

  @override
  void initState() {
    super.initState();
    fetchTaskObjects();
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
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      WorkerObjectProductsPage(
                                                        taskObjects:
                                                            taskObjects,
                                                        objectId:
                                                            task["id"] ?? "",
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                            ),
                                            label: Text(ktavaram.tr()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue[300],
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 18,
                                                    vertical: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
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
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
