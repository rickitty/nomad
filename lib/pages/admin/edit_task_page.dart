import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config.dart';
import 'package:price_book/keys.dart';

class EditTaskPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  bool saving = false;
  bool loading = false;

  DateTime? selectedDate;

  String? selectedWorkerId;
  Map<String, dynamic>? workerData;

  List objects = [];
  List products = [];

  final Set<String> selectedObjects = {};
  final Set<String> selectedProducts = {};

  String searchObjects = '';
  String searchProducts = '';

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    try {
      final dateStr = task["date"]?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        selectedDate = DateTime.parse(dateStr);
      }
    } catch (_) {
      selectedDate = DateTime.now();
    }

    workerData = (task["worker"] is Map)
        ? Map<String, dynamic>.from(task["worker"])
        : null;

    selectedWorkerId =
        task["workerId"]?.toString() ?? workerData?["_id"]?.toString();

    for (var o in (task["objects"] ?? []) as List) {
      final objId = _extractId(o["objectId"] ?? o["_id"]);
      if (objId != null) {
        selectedObjects.add(objId);
      }

      final prods = (o["products"] is List)
          ? o["products"] as List
          : <dynamic>[];
      for (var p in prods) {
        if (p is Map) {
          final prodId = _extractId(p["productId"] ?? p["_id"] ?? p["id"]);
          if (prodId != null) {
            selectedProducts.add(prodId);
          }
        }
      }
    }

    _loadData();
  }

  String? _extractId(dynamic val) {
    if (val == null) return null;
    if (val is String) return val;
    if (val is Map && val["_id"] != null) {
      return val["_id"].toString();
    }
    return val.toString();
  }

  Future<void> _loadData() async {
    if (selectedWorkerId == null) return;

    setState(() => loading = true);
    try {
      final resObjects = await http.get(
        Uri.parse("$baseUrl/object/objects-of/$selectedWorkerId"),
      );
      if (resObjects.statusCode == 200) {
        objects = jsonDecode(resObjects.body);
      }

      final locale = context.locale.languageCode;
      final resProducts = await http.get(
        Uri.parse("$baseUrl/products?lang=$locale"),
      );
      if (resProducts.statusCode == 200) {
        products = jsonDecode(resProducts.body);
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки данных: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите дату')));
      return;
    }
    if (selectedWorkerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Работник не найден')));
      return;
    }
    if (selectedObjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один объект')),
      );
      return;
    }
    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один продукт')),
      );
      return;
    }

    final taskId =
        widget.task["_id"]?.toString() ?? widget.task["id"]?.toString();

    if (taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: не найден ID задачи')),
      );
      return;
    }

    final List<Map<String, dynamic>> objectsPayload = selectedObjects
        .map((objId) {
          return {
            "objectId": objId,
            "products": selectedProducts
                .map((prodId) => {"productId": prodId})
                .toList(),
          };
        })
        .toList()
        .cast<Map<String, dynamic>>();

    setState(() => saving = true);

    try {
      final local = selectedDate!;
      final utcDate = DateTime.utc(local.year, local.month, local.day);
      final res = await http.put(
        Uri.parse("$baseUrl/tasks/update-task/$taskId"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "date": utcDate.toIso8601String(),
          "workerId": selectedWorkerId,
          "objects": objectsPayload,
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Задача обновлена')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: ${res.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    final filteredObjects = objects.where((o) {
      final name = (o["name"] ?? "").toString().toLowerCase();
      final category = (o["type"] ?? "").toString().toLowerCase();
      final query = searchObjects.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();

    final filteredProducts = products.where((p) {
      final name = (p["name"] ?? "").toString().toLowerCase();
      final category = (p["category"] ?? "").toString().toLowerCase();
      final query = searchProducts.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();

    final workerName = () {
      if (workerData == null) return noName.tr();
      final nameMap = workerData!["name"];
      String name;
      if (nameMap is Map) {
        name =
            nameMap[locale] ??
            nameMap["ru"] ??
            nameMap["en"] ??
            nameMap.values.first.toString();
      } else {
        name = nameMap?.toString() ?? noName.tr();
      }
      final phone = workerData!["phone"]?.toString() ?? "???";
      return "$phone — $name";
    }();

    return Scaffold(
      appBar: AppBar(title: Text(editTask.tr())),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(worker.tr()),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(workerName),
                  ),

                  const SizedBox(height: 20),

                  Text(objectsK.tr()),
                  TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: searchObjectsBy.tr(),
                    ),
                    onChanged: (v) => setState(() => searchObjects = v),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: filteredObjects.length > 5 ? 250 : null,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: filteredObjects.map((o) {
                          final objId = _extractId(o["_id"]);
                          if (objId == null) return const SizedBox.shrink();

                          final isSelected = selectedObjects.contains(objId);

                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(o["name"] ?? "Без имени"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o["address"] ?? ""),
                                Text(o["type"] ?? ""),
                              ],
                            ),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  selectedObjects.add(objId);
                                } else {
                                  selectedObjects.remove(objId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Продукты — как на странице создания
                  Text(productsK.tr()),
                  TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: productsSearch.tr(),
                    ),
                    onChanged: (v) => setState(() => searchProducts = v),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: filteredProducts.length > 5 ? 250 : null,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: filteredProducts.map((p) {
                          final prodId = _extractId(p["_id"]);
                          if (prodId == null) return const SizedBox.shrink();

                          final imageUrl = p["imageUrl"]?.toString();
                          final hasImage =
                              imageUrl != null && imageUrl.isNotEmpty;

                          final isSelected = selectedProducts.contains(prodId);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.grey.shade200,
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: hasImage
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.image_not_supported,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 28,
                                      ),
                              ),
                              title: Text(
                                p["name"] ?? "No name",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                p["category"] ?? "",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      selectedProducts.add(prodId);
                                    } else {
                                      selectedProducts.remove(prodId);
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: Text(
                      selectedDate == null
                          ? chooseDate.tr()
                          : selectedDate!.toLocal().toString().split(" ").first,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : _save,
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(save.tr()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
