// ignore_for_file: unused_element

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:price_book/drawer.dart';
import 'package:price_book/keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';

const Color kPrimaryColor = Color.fromRGBO(144, 202, 249, 1);

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  List markets = [];
  bool loadingMarkets = true;

  String selectedWorkerPhone = ""; // берём из SharedPreferences
  List<String> selectedMarketIds = [];
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone');

    if (!mounted) return;

    setState(() {
      if (phone != null && phone.isNotEmpty) {
        selectedWorkerPhone = phone;
      }
    });

    await loadMarkets();
  }

  Future<void> loadMarkets() async {
    setState(() => loadingMarkets = true);

    try {
      final headers = await Config.authorizedJsonHeaders();

      if (!headers.containsKey('Authorization')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Токен не найден. Авторизуйтесь заново.'),
          ),
        );
        setState(() => loadingMarkets = false);
        return;
      }

      final response = await http.get(
        Uri.parse("$QYZ_API_BASE/markets"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        markets = json.decode(utf8.decode(response.bodyBytes));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки рынков: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    } finally {
      setState(() => loadingMarkets = false);
    }
  }

  Future<void> saveTask() async {
    if (selectedMarketIds.isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("fill_all_the_fields".tr())));
      return;
    }

    // подправляем дату на +5 часов
    final correctedDate = selectedDate!.add(const Duration(hours: 5));

    final body = {
      "phoneNumber": selectedWorkerPhone,
      "marketIds": selectedMarketIds,
      "deadLine": correctedDate.toIso8601String(),
    };

    try {
      final headers = await Config.authorizedJsonHeaders();

      if (!headers.containsKey('Authorization')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Токен не найден. Авторизуйтесь заново.'),
          ),
        );
        return;
      }

      final res = await http.post(
        Uri.parse("$QYZ_API_BASE/task/create"),
        headers: headers,
        body: jsonEncode(body),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(taskIsMade.tr())));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${error.tr()}: ${res.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${error.tr()}: $e")));
    }
  }

  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: kPrimaryColor) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isFormValid = selectedMarketIds.isNotEmpty && selectedDate != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      drawer: AppDrawer(current: DrawerRoute.taskCreate),
      appBar: AppBar(
        title: Text(
          createATask.tr(),
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
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: kPrimaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  worker.tr(),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedWorkerPhone.isEmpty
                                      ? "—"
                                      : selectedWorkerPhone,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      Text(
                        deadline.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            selectedDate == null
                                ? chooseDate.tr()
                                : DateFormat(
                                    'dd.MM.yyyy',
                                  ).format(selectedDate!),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            foregroundColor: const Color.fromARGB(
                              255,
                              84,
                              123,
                              154,
                            ),
                            side: BorderSide(
                              color: Color.fromARGB(
                                255,
                                84,
                                123,
                                154,
                              ).withOpacity(0.7),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? now,
                              firstDate: now,
                              lastDate: DateTime(now.year + 2),
                            );

                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Text(
                                Markets.tr(),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (selectedMarketIds.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    "+${selectedMarketIds.length}",
                                    style: textTheme.bodySmall?.copyWith(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: loadMarkets,
                                tooltip: reload.tr(),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        const SizedBox(height: 4),
                        Expanded(
                          child: loadingMarkets
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(
                                      kPrimaryColor,
                                    ),
                                  ),
                                )
                              : markets.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Text(
                                      availableObj.tr(),
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: markets.length,
                                  itemBuilder: (context, index) {
                                    final m = markets[index];
                                    final marketId = (m["id"] ?? m["_id"] ?? "")
                                        .toString();
                                    final checked = selectedMarketIds.contains(
                                      marketId,
                                    );

                                    final name = (m["name"] ?? "—").toString();
                                    final address = (m["address"] ?? "")
                                        .toString();

                                    return CheckboxListTile(
                                      value: checked,
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            if (!selectedMarketIds.contains(
                                              marketId,
                                            )) {
                                              selectedMarketIds.add(marketId);
                                            }
                                          } else {
                                            selectedMarketIds.remove(marketId);
                                          }
                                        });
                                      },
                                      title: Text(
                                        name,
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: address.isEmpty
                                          ? null
                                          : Text(
                                              address,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                            ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      activeColor: kPrimaryColor,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isFormValid ? saveTask : saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFormValid
                        ? kPrimaryColor
                        : kPrimaryColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    createATask.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
