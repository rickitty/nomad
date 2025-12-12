import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:price_book/config.dart';
import 'package:price_book/keys.dart';

const Color kPrimaryColor = Color.fromRGBO(144, 202, 249, 1);

class CreateMarketPage extends StatefulWidget {
  const CreateMarketPage({super.key});

  @override
  State<CreateMarketPage> createState() => _CreateMarketPageState();
}

class _CreateMarketPageState extends State<CreateMarketPage> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _accuracy = TextEditingController();
  final _workHours = TextEditingController();
  String? _selectedType;

  final List<String> _marketTypes = const [
    'Супермаркет',
    'Минимаркет',
    'Киоск',
    'Гипермаркет',
    'Магазин у дома',
  ];

  bool loading = false;

  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  Future<void> createMarket() async {
    setState(() => loading = true);

    if (QYZ_API_BASE.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ошибка: базовый URL не задан")),
      );
      setState(() => loading = false);
      return;
    }

    final token = await Config.getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ошибка: токен не задан")),
      );
      setState(() => loading = false);
      return;
    }

    final Map<String, dynamic> body = {
      "name": _name.text,
      "address": _address.text,
      "location": {
        "lng": double.tryParse(_lng.text) ?? 0,
        "lat": double.tryParse(_lat.text) ?? 0,
      },
      "geoAccuracy": int.tryParse(_accuracy.text) ?? 0,
      "type": _selectedType ?? "",    
      "workHours": _workHours.text,
    };

    final uri = Uri.parse("$QYZ_API_BASE/market/create");
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
    final jsonBody = jsonEncode(body);

    print(jsonBody);
    print("=== CREATE MARKET REQUEST ===");
    print("URL: $uri");
    print("HEADERS: $headers");
    print("BODY: $jsonBody");

    final curl = """
curl -X POST '$uri' \\
  -H 'Content-Type: application/json' \\
  -H 'Authorization: Bearer $token' \\
  -d '$jsonBody'
""";
    print("CURL:\n$curl");

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonBody,
      );

      final bodyStr = utf8.decode(response.bodyBytes);

      print("=== CREATE MARKET RESPONSE ===");
      print("STATUS: ${response.statusCode}");
      print("BODY: $bodyStr");

      dynamic data;
      if (bodyStr.isNotEmpty) {
        try {
          data = json.decode(bodyStr);
        } catch (_) {
          data = bodyStr;
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(succsessfulCreateMarket.tr())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ошибка: ${data ?? bodyStr}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сети: $e")),
      );
    }

    setState(() => loading = false);
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: kPrimaryColor,
            )
          : null,
      suffixIcon: suffix,
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

  Future<void> _pickWorkHours() async {
    final now = TimeOfDay.now();

    final open = await showTimePicker(
      context: context,
      initialTime: _openTime ?? now,
      helpText: "Время открытия",
    );

    if (open == null) return;

    final close = await showTimePicker(
      context: context,
      initialTime: _closeTime ?? open,
      helpText: "Время закрытия",
    );

    if (close == null) return;

    setState(() {
      _openTime = open;
      _closeTime = close;
      _workHours.text = _formatTimeRange(open, close);
    });
  }

  String _formatTimeRange(TimeOfDay start, TimeOfDay end) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final startStr =
        "${twoDigits(start.hour)}:${twoDigits(start.minute)}";
    final endStr = "${twoDigits(end.hour)}:${twoDigits(end.minute)}";

    return "$startStr - $endStr";
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text("Create Market"),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Новый объект",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2933),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Заполните данные о торговой точке",
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    TextField(
                      controller: _name,
                      decoration: _inputDecoration(
                        label: name.tr(),
                        icon: Icons.store_mall_directory,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _address,
                      decoration: _inputDecoration(
                        label: Address.tr(),
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _lat,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: false,
                            ),
                            decoration: _inputDecoration(
                              label: Latitude.tr(),
                              icon: Icons.my_location,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _lng,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: false,
                            ),
                            decoration: _inputDecoration(
                              label: Longitude.tr(),
                              icon: Icons.explore_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _accuracy,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: GeoAccuracy.tr(),
                        icon: Icons.gps_fixed,
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: _marketTypes
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(t),
                            ),
                          )
                          .toList(),
                      decoration: _inputDecoration(
                        label: Type.tr(),
                        icon: Icons.category_outlined,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _workHours,
                      readOnly: true,
                      onTap: _pickWorkHours,
                      decoration: _inputDecoration(
                        label: WorkHours.tr(),
                        icon: Icons.access_time,
                        suffix: IconButton(
                          icon: const Icon(Icons.schedule),
                          color: kPrimaryColor,
                          onPressed: _pickWorkHours,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : createMarket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          disabledBackgroundColor:
                              kPrimaryColor.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                Create.tr(),
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
          ),
        ),
      ),
    );
  }
}
