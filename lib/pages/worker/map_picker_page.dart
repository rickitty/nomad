import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:price_book/keys.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? selected;
  Future<String> _getAddress(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isEmpty) return "";

      final p = placemarks.first;

      return [
        p.street,
        p.subLocality,
        p.locality,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(choosePoint.tr())),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(51.169392, 71.449074),
              zoom: 14,
            ),
            onTap: (pos) {
              setState(() => selected = pos);
            },
            markers: selected == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId("selected"),
                      position: selected!,
                    ),
                  },
          ),
          if (selected != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: () async {
                  final address = await _getAddress(selected!);
                  Navigator.pop(context, {
                    "lat": selected!.latitude,
                    "lng": selected!.longitude,
                    "address": address.isEmpty ? "Адрес не найден" : address,
                  });
                },
                child: const Text("Подтвердить"),
              ),
            ),
        ],
      ),
    );
  }
}
