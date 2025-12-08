// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CompleteGoodPage extends StatefulWidget {
  final String taskDetailId;
  final String goodId;
  final String marketName;
  final String productName;

  const CompleteGoodPage({
    super.key,
    required this.taskDetailId,
    required this.goodId,
    required this.marketName,
    required this.productName,
  });

  @override
  State<CompleteGoodPage> createState() => _CompleteGoodPageState();
}

class _CompleteGoodPageState extends State<CompleteGoodPage> {
  final TextEditingController priceUnitController = TextEditingController();
  double? lat;
  double? lng;
  bool loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getPosition();
  }

  Future<void> _getPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        loadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка получения геолокации: $e")),
      );
    }
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() {
        lat = position.latitude;
        lng = position.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Не удалось получить геолокацию: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Выполнить товар")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: loadingLocation
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Маркет: ${widget.marketName}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Продукт: ${widget.productName}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceUnitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "PriceUnit",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Lat: ${lat ?? 'не определено'}"),
                  Text("Lng: ${lng ?? 'не определено'}"),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _updateLocation,
                    child: const Text("Обновить геолокацию"),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Пока пустая кнопка
                      },
                      child: const Text("Подтвердить"),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
