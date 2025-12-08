import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:price_book/pages/worker/complete_product_task_page.dart';

class WorkerObjectProductsPage extends StatelessWidget {
  final List<Map<String, dynamic>> taskObjects;
  final String objectId;

  const WorkerObjectProductsPage({
    super.key,
    required this.taskObjects,
    required this.objectId,
  });

  @override
  Widget build(BuildContext context) {
    final object = taskObjects.firstWhere(
      (obj) => obj["id"] == objectId,
      orElse: () => {},
    );

    final goods = (object["goods"] as List?) ?? [];
    final marketName = object["marketId"] ?? "Неизвестно";

    return Scaffold(
      appBar: AppBar(title: const Text("Товары")),
      body: goods.isEmpty
          ? const Center(child: Text("Нет товаров"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: goods.length,
              itemBuilder: (context, index) {
                final good = goods[index];
                final productName =
                    good["name"][context.locale.languageCode] ??
                    good["name"]["en"];
                final completed = good["completed"] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(productName),
                    trailing: completed
                        ? const Text(
                            "Выполнено",
                            style: TextStyle(color: Colors.green),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CompleteGoodPage(
                                    taskDetailId: objectId,
                                    goodId: good["goodId"],
                                    marketName: marketName,
                                    productName: productName,
                                  ),
                                ),
                              );
                            },
                            child: const Text("Выполнить"),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
