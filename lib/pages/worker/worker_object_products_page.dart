import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:price_book/keys.dart';
import '../../config.dart';
import 'widgets/worker_product_tile.dart';

class WorkerObjectProductsPage extends StatefulWidget {
  final String taskId;
  final String objectId;   
  final String objectName; 

  const WorkerObjectProductsPage({
    super.key,
    required this.taskId,
    required this.objectId,
    required this.objectName,
  });

  @override
  State<WorkerObjectProductsPage> createState() =>
      _WorkerObjectProductsPageState();
}

class _WorkerObjectProductsPageState extends State<WorkerObjectProductsPage> {
  bool loading = false;
  List<Map<String, dynamic>> products = [];
  String? selectedCategory;

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(locationDisabled.tr()),
          content: Text(enableLocationServices.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Geolocator.openLocationSettings();
              },
              child: Text(openSettings.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(cancel.tr()),
            ),
          ],
        ),
      );
      throw Exception("Location services disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(locationPermissionDeniedForever.tr()),
          content: Text(pleaseGrantLocationPermissionFromSettings.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
              },
              child: Text(openAppSettings.tr()),
            ),
            TextButton(
              onPressed: () {
                Geolocator.openLocationSettings();
              },
              child: Text(openLocationSettings.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(cancel.tr()),
            ),
          ],
        ),
      );
      throw Exception("Location permission denied forever");
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    );

    return pos;
  }

  Color _categoryColor(String localizedCategory) {
    final lower = localizedCategory.toLowerCase();

    if (lower.contains('dairy') ||
        lower.contains('молоч') ||
        lower.contains('сүт')) {
      return Colors.blue;
    }
    if (lower.contains('vegetables') ||
        lower.contains('овощ') ||
        lower.contains('көкөніс')) {
      return Colors.green;
    }
    if (lower.contains('fruit') ||
        lower.contains('фрукт') ||
        lower.contains('жеміс')) {
      return Colors.red;
    }
    if (lower.contains('drink') ||
        lower.contains('напит') ||
        lower.contains('сусын')) {
      return Colors.purple;
    }
    if (lower.contains('bake') ||
        lower.contains('хлеб') ||
        lower.contains('нан')) {
      return Colors.brown;
    }
    if (lower.contains('cereal') ||
        lower.contains('круп') ||
        lower.contains('дән')) {
      return Colors.orange;
    }
    if (lower.contains('animal') ||
        lower.contains('животно') ||
        lower.contains('ауылшаруашылық')) {
      return const Color.fromARGB(255, 201, 75, 117);
    }

    return Colors.grey;
  }

  Future<void> _loadProducts() async {
    setState(() => loading = true);
    try {
      final uri = Uri.parse(
        '$baseUrl/api/v1/monitoring/task/${widget.taskId}',
      );

      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $bearerToken',
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        final detail = data
            .cast<Map<String, dynamic>>()
            .firstWhere(
              (d) => d['id'] == widget.objectId,
              orElse: () => <String, dynamic>{},
            );

        final List<dynamic> rawGoods =
            (detail['goods'] as List?) ?? <dynamic>[];

        final List<Map<String, dynamic>> mappedGoods =
            rawGoods.map<Map<String, dynamic>>((g) {
          final m = Map<String, dynamic>.from(g as Map);
          final completed = (m['completed'] ?? false) == true;
          m['status'] = completed ? 'added' : 'pending';
          return m;
        }).toList();

        mappedGoods.sort((a, b) {
          final aDone = (a['status'] ?? 'pending') == 'added';
          final bDone = (b['status'] ?? 'pending') == 'added';
          if (aDone == bDone) return 0;
          return aDone ? 1 : -1;
        });

        setState(() {
          products = mappedGoods;
          loading = false;
        });
      } else {
        debugPrint('loadProducts error: ${res.statusCode} ${res.body}');
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(loadProductsError.tr())),
        );
      }
    } catch (e) {
      debugPrint('loadProducts exception: $e');
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(geolocationOrNetworkError.tr())),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    String getLocalized(dynamic data) {
      if (data == null || data is! Map) return "";
      return data[locale] ?? data["en"] ?? data.values.first.toString();
    }

    final categorySet = <String>{};
    for (final p in products) {
      final cat = getLocalized(p['category']);
      if (cat.isNotEmpty) {
        categorySet.add(cat);
      }
    }
    final categories = categorySet.toList()..sort();

    final visibleProducts = selectedCategory == null
        ? products
        : products.where((raw) {
            final cat = getLocalized(raw['category']);
            return cat == selectedCategory;
          }).toList();

    Widget buildCategoryFilter() {
      if (categories.isEmpty || products.isEmpty) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          children: [
            const SizedBox(width: 4),
            ChoiceChip(
              label: Text(all.tr()),
              selected: selectedCategory == null,
              onSelected: (_) {
                setState(() {
                  selectedCategory = null;
                });
              },
            ),
            const SizedBox(width: 8),
            ...categories.map((cat) {
              final color = _categoryColor(cat);
              final selected = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? Colors.white : color,
                      fontSize: 12,
                    ),
                  ),
                  selected: selected,
                  selectedColor: color,
                  backgroundColor: color.withOpacity(0.12),
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },
                ),
              );
            }),
          ],
        ),
      );
    }

    Widget buildBody() {
      if (loading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (visibleProducts.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${theProductsHaveNotLoadedYet.tr()}.\n'
              '${checkYourGeo.tr()}.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return ListView.builder(
        itemCount: visibleProducts.length,
        itemBuilder: (context, index) {
          final p = visibleProducts[index];

          return WorkerProductTile(
            product: p,
            taskId: widget.taskId,
            objectId: widget.objectId, // = TaskDetailId
            onUpdated: _loadProducts,
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.objectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: showDistanceToObject.tr(),
            onPressed: loading ? null : _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          buildCategoryFilter(),
          Expanded(child: buildBody()),
        ],
      ),
    );
  }
}
