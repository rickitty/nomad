import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:price_book/keys.dart';

import '../worker_product_task_page.dart';

class WorkerProductTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final String taskId;
  final String objectId; 
  final Future<void> Function() onUpdated;

  const WorkerProductTile({
    super.key,
    required this.product,
    required this.taskId,
    required this.objectId,
    required this.onUpdated,
  });

  String _getLocalizedName(BuildContext context) {
    final locale = context.locale.languageCode;
    final name = product['name'];

    if (name is Map) {
      return name[locale] ?? name['en'] ?? name.values.first.toString();
    }
    return name?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final name = _getLocalizedName(context);
    final completed = product['completed'] == true;
    final price =
        product['priceUnit'] != null ? product['priceUnit'].toString() : '';
    final existingPhoto = product['photoPrice']?.toString();

    return ListTile(
      title: Text(name.isEmpty ? noName.tr() : name),
      subtitle:
          price.isNotEmpty ? Text('${currentPrice.tr()}: $price') : null,
      trailing: Icon(
        completed ? Icons.check_circle : Icons.radio_button_unchecked,
        color: completed ? Colors.green : Colors.grey,
      ),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkerProductTaskPage(
              taskId: taskId,
              objectId: objectId, 
              productId: product['goodId']?.toString() ?? '',
              productName: name,
              productCategory: null,
              existingPhotoUrl: existingPhoto,
              existingPrice: price.isEmpty ? null : price,
            ),
          ),
        );
        if (result == true) {
          await onUpdated();
        }
      },
    );
  }
}
