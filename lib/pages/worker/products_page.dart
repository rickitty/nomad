import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:price_book/pages/worker/complete_product_page.dart';

import '../../keys.dart';

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
    final locale = context.locale.languageCode;

    String getName(dynamic raw) {
      if (raw == null) return "";
      if (raw is Map) {
        return raw[locale] ?? raw["en"] ?? raw.values.first.toString();
      }
      return raw.toString();
    }

    final object = taskObjects.firstWhere(
      (obj) => obj["id"] == objectId,
      orElse: () => {},
    );

    final goods = (object["goods"] as List?) ?? [];
    final marketName = object["marketId"]?.toString() ?? "${unknown.tr()}";
    final completedCount = goods
        .where((g) => (g as Map)["completed"] == true)
        .length;
    final totalGoods = goods.length;
    final double progress = totalGoods == 0 ? 0 : completedCount / totalGoods;

    return Scaffold(
      appBar: AppBar(
        title: Text("${productsK.tr()}"),
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
          child: goods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 56,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        noProd.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        noObjYet.tr(),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header info по объекту
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: Color.fromRGBO(144, 202, 249, 1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  marketName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${productsK.tr()}: $totalGoods, ${completeV.tr()}: $completedCount",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (totalGoods > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              progress >= 1 ? Colors.green : Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),

                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: goods.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final good = goods[index] as Map<String, dynamic>;
                          final productName = getName(good["name"]).isEmpty
                              ? noNameM.tr()
                              : getName(good["name"]);
                          final completed = good["completed"] ?? false;

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 220 + index * 40),
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - value)),
                                child: child,
                              ),
                            ),
                            child: Card(
                              elevation: 4,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: completed
                                        ? [Colors.green.shade50, Colors.white]
                                        : [Colors.white, Colors.blue.shade50],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: completed
                                        ? Colors.green.shade200
                                        : Colors.blue.shade200,
                                    child: Icon(
                                      completed
                                          ? Icons.check_rounded
                                          : Icons.inventory_2_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    productName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: completed
                                      ? Text(
                                          completedC.tr(),
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      : Text(
                                          waiting.tr(),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                  trailing: completed
                                      ? ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CompleteGoodPage(
                                                      taskDetailId: objectId,
                                                      goodId: good["goodId"],
                                                      marketName: marketName,
                                                      productName: productName,
                                                    ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[400],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child:  Text(
                                            redo.tr(), 
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CompleteGoodPage(
                                                      taskDetailId: objectId,
                                                      goodId: good["goodId"],
                                                      marketName: marketName,
                                                      productName: productName,
                                                    
                                                    ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[300],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: Text(
                                            execute.tr(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                ),
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
