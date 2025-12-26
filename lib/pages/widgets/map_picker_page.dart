import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'package:price_book/keys.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController mapController = MapController();
  final TextEditingController searchCtrl = TextEditingController();

  LatLng? selected;
  String address = "";

  // reverse geocoding
  Future<void> _loadAddress(LatLng pos) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json'
      '&lat=${pos.latitude}'
      '&lon=${pos.longitude}',
    );

    final res = await http.get(uri, headers: {'User-Agent': 'price_book_app'});

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final country = data['address']?['country_code'];

      // 🇰🇿 ограничение
      if (country != 'kz') {
        setState(() {
          isInKz = false;
          address = "Выберите точку в Казахстане";
        });
        return;
      }

      setState(() {
        isInKz = true;
        address = data['display_name'] ?? '';
      });
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?format=json'
      '&q=$query'
      '&countrycodes=kz'
      '&limit=1',
    );

    final res = await http.get(uri, headers: {'User-Agent': 'price_book_app'});

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);

      if (data.isEmpty) {
        setState(() {
          address = "Ничего не найдено";
        });
        return;
      }

      final lat = double.parse(data[0]['lat']);
      final lon = double.parse(data[0]['lon']);
      final pos = LatLng(lat, lon);

      setState(() {
        selected = pos;
        address = '';
      });

      mapController.move(pos, 15);
      await _loadAddress(pos);
    }
  }

  String? selectedCity;
  bool isInKz = false;

  final cities = {
    "Астана": LatLng(51.1694, 71.4491),
    "Алматы": LatLng(43.2389, 76.8897),
    "Шымкент": LatLng(42.3417, 69.5901),
  };

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(choosePoint.tr())),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(51.169392, 71.449074),
              initialZoom: 12,
              onTap: (tapPos, latlng) async {
                setState(() {
                  selected = latlng;
                  address = '';
                });
                await _loadAddress(latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              if (selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selected!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 🔍 Поиск
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  // hintText: "Город, улица (Казахстан)",
                  hintText: cityStreetKz.tr(),
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                onSubmitted: _searchPlace,
              ),
            ),
          ),
          // 🏙 Выбор города
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCity,
                    hint: Text(chooseCity.tr()),
                    isExpanded: true,
                    items: cities.keys
                        .map(
                          (city) =>
                              DropdownMenuItem(value: city, child: Text(city)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCity = value;
                        selected = null;
                        address = '';
                        searchCtrl.clear();
                      });

                      final pos = cities[value]!;
                      mapController.move(pos, 12);
                    },
                  ),
                ),
              ),
            ),
          ),

          // 🪪 Карточка адреса
          if (selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 90,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Выбранный адрес",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address.isEmpty ? "Загрузка адреса..." : address,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ✅ Подтвердить
          if (selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: ElevatedButton(
                onPressed: isInKz
                    ? () {
                        Navigator.pop(context, {
                          "lat": selected!.latitude,
                          "lng": selected!.longitude,
                          "address": address,
                        });
                      }
                    : null,
                child: Text(confirm.tr()),
              ),
            ),
        ],
      ),
    );
  }
}
