import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'package:price_book/keys.dart';
import 'dart:convert';
import '../../config.dart';

class AdminAssignPage extends StatefulWidget {
  const AdminAssignPage({super.key});

  @override
  State<AdminAssignPage> createState() => _AdminAssignPageState();
}

class _AdminAssignPageState extends State<AdminAssignPage> {
  List workers = [];
  List markets = [];
  List<Map<String, dynamic>> selectedMarkets = [];

  String? selectedWorker;
  String search = "";

  @override
  void initState() {
    super.initState();
    loadWorkers();
    loadMarkets();
  }

  Future<void> loadWorkers() async {
    final res = await http.get(Uri.parse(workersUrl));
    if (res.statusCode == 200) {
      setState(() {
        workers = jsonDecode(res.body);
      });
      print("Workers loaded: ${workers.length}");
    } else {
      print("Failed to load workers: ${res.body}");
    }
  }

  Future<void> loadMarkets() async {
    final res = await http.get(
      Uri.parse(getMarkets),
      headers: {'Authorization': 'Bearer $bearerToken'},
    );
    if (res.statusCode == 200) {
      final decoded = json.decode(utf8.decode(res.bodyBytes));
      setState(() {
        markets = decoded;
      });
      print("Markets loaded: ${markets.length}");
    } else {
      print("Failed to load markets: ${res.body}");
    }
  }

  Future<void> save() async {
    if (selectedWorker == null) return;

    print("Saving for worker $selectedWorker");
    print("Selected markets: $selectedMarkets");

    final res = await http.post(
      Uri.parse(assignObjectsUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": selectedWorker, "markets": selectedMarkets}),
    );

    print("Response status: ${res.statusCode}");
    print("Response body: ${res.body}");

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saved")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${res.body}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMarkets = markets
        .where(
          (m) =>
              m["name"].toString().toLowerCase().contains(search.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(assigningObjects.tr())),
      body: Column(
        children: [
          DropdownSearch<Map<String, dynamic>>(
            items: (String filter, LoadProps? lp) async {
              return workers
                  .where((w) => (w["phone"] ?? "").contains(filter))
                  .map((e) => e as Map<String, dynamic>)
                  .toList();
            },
            selectedItem: selectedWorker != null
                ? workers.where((w) => w["_id"] == selectedWorker).isNotEmpty
                      ? workers.firstWhere((w) => w["_id"] == selectedWorker)
                      : null
                : null,
            compareFn: (item, selected) => item["_id"] == selected["_id"],
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(labelText: workerSearch.tr()),
              ),
              itemBuilder: (context, item, isSelected, searchText) {
                final name = (item["name"] ?? "Имя").toString();
                final phone = (item["phone"] ?? "???").toString();
                return ListTile(title: Text("$phone — $name"));
              },
            ),
            dropdownBuilder: (context, selectedItem) {
              if (selectedItem == null || selectedItem["_id"] == null) {
                return Text(selectAWorker.tr());
              }
              final name = (selectedItem["name"] ?? "Имя").toString();
              final phone = (selectedItem["phone"] ?? "???").toString();
              return Text("$phone — $name");
            },
            onChanged: (v) {
              if (v == null || v.isEmpty) return;

              setState(() {
                selectedWorker = v["_id"];
                final list = v["markets"];

                if (list is List) {
                  selectedMarkets = List<Map<String, dynamic>>.from(list);
                } else {
                  selectedMarkets = [];
                }

                print("Selected markets after worker change: $selectedMarkets");
              });
            },
            decoratorProps: const DropDownDecoratorProps(
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                labelText: objectsSearch.tr(),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),

          Expanded(
            child: ListView(
              children: filteredMarkets.map((market) {
                final checked = selectedMarkets.any(
                  (m) =>
                      m["name"] == market["name"] &&
                      m["address"] == market["address"],
                );

                return CheckboxListTile(
                  title: Text(market["name"] ?? "Без названия"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(market["address"] ?? "Нет адреса"),
                      Text(market["type"] ?? ""),
                      Text("Часы работы: ${market["workHours"] ?? "-"}"),
                      Text(market["id"] ?? "Нет айди"),
                    ],
                  ),
                  value: checked,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selectedMarkets.add(market);
                      } else {
                        selectedMarkets.removeWhere(
                          (m) =>
                              m["name"] == market["name"] &&
                              m["address"] == market["address"],
                        );
                      }
                      print("Selected markets now: $selectedMarkets");
                    });
                  },
                );
              }).toList(),
            ),
          ),

          ElevatedButton(onPressed: save, child: Text(confirm.tr())),
        ],
      ),
    );
  }
}
