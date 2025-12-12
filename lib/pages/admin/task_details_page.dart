import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;

import '../../config.dart';
import '../../keys.dart';

const Color kPrimaryColor = Color.fromRGBO(144, 202, 249, 1);

class TaskDetailsPage extends StatelessWidget {
  final String taskId;

  const TaskDetailsPage({super.key, required this.taskId});
  String getLocalized(dynamic data, String locale) {
    if (data == null) return "";

    if (data is String) return data;

    if (data is Map<String, dynamic>) {
      return data[locale] ?? data["en"] ?? data.values.first.toString();
    }

    if (data is List && data.isNotEmpty) {
      return getLocalized(data.first, locale);
    }

    return data.toString();
  }

  Future<List<Map<String, dynamic>>> fetchTask() async {
    final headers = await Config.authorizedJsonHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('Токен не найден. Авторизуйтесь заново.');
    }

    final response = await http.get(
      Uri.parse("$QYZ_API_BASE/task/$taskId"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        return [decoded];
      } else {
        throw Exception('Неожиданный формат ответа');
      }
    } else {
      throw Exception("Ошибка загрузки: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: Text(
          taskDetails.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTask(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(kPrimaryColor),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "${error.tr()}: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(noData.tr()));
          }

          final taskList = snapshot.data!;
          final first = taskList.first;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // верхняя карточка с ID задачи
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              taskID.tr(),
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (first["id"] ?? first["_id"] ?? "").toString(),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // карточки по маркетам / деталям
              ...taskList.map((task) {
                final marketId = (task["marketId"] ?? "—").toString();
                final completedAt = (task["completedAt"] ?? "").toString();
                final goods = (task["goods"] as List?) ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // заголовок маркета
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: kPrimaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${Market.tr()}: $marketId",
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (completedAt.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${complete.tr()}: $completedAt",
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),

                        Text(
                          "${productsK.tr()}:",
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),

                        if (goods.isEmpty)
                          Text(
                            noData.tr(),
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          )
                        else
                          ...goods.map((g) {
                            final name = getLocalized(g["name"], locale);
                            final completed = g["completed"] ?? false;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    completed
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: completed
                                        ? Colors.green
                                        : Colors.grey[400],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name.isEmpty ? "-" : name,
                                      style:
                                          textTheme.bodyMedium?.copyWith(),
                                    ),
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
