import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:price_book/api_client.dart';
import 'dart:convert';
import 'package:price_book/keys.dart';
import 'package:price_book/pages/worker/map_picker_page.dart';

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
  final _formKey = GlobalKey<FormState>();
  bool _useMap = false;
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

    print("=== CREATE MARKET REQUEST ===");
    print(jsonEncode(body));

    try {
      final response = await ApiClient.post('/market/create', body, context);

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(succsessfulCreateMarket.tr())));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${error.tr()}: ${data ?? bodyStr}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка сети: $e")));
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
      prefixIcon: icon != null ? Icon(icon, color: kPrimaryColor) : null,
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

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _accuracy.dispose();
    _workHours.dispose();
    super.dispose();
  }

  String _formatTimeRange(TimeOfDay start, TimeOfDay end) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final startStr = "${twoDigits(start.hour)}:${twoDigits(start.minute)}";
    final endStr = "${twoDigits(end.hour)}:${twoDigits(end.minute)}";

    return "$startStr - $endStr";
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: Text(createMarketK.tr()),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newMarket.tr(),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2933),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fillInTheMarketDetails.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name
                      TextFormField(
                        controller: _name,
                        decoration: _inputDecoration(
                          label: name.tr(),
                          icon: Icons.store_mall_directory,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return requiredField.tr();
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      ToggleButtons(
                        isSelected: [_useMap, !_useMap],
                        onPressed: (index) {
                          setState(() {
                            _useMap = index == 0;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        selectedColor: Colors.white,
                        fillColor: kPrimaryColor,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(Icons.map),
                                SizedBox(width: 6),
                                Text(onMap.tr()),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(Icons.edit_location),
                                SizedBox(width: 6),
                                Text(byHand.tr()),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (_useMap) ...[
                        ElevatedButton.icon(
                          onPressed: _openMapPicker,
                          icon: const Icon(Icons.place),
                          label: const Text("Выбрать точку на карте"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _address,
                          readOnly: true,
                          decoration: _inputDecoration(
                            label: Address.tr(),
                            icon: Icons.location_on_outlined,
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? requiredField.tr()
                              : null,
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _address,
                          decoration: _inputDecoration(
                            label: Address.tr(),
                            icon: Icons.location_on_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return requiredField.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _lat,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDecoration(
                                  label: Latitude.tr(),
                                  icon: Icons.my_location,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return requiredField.tr();
                                  }
                                  if (double.tryParse(value) == null) {
                                    return invalidNumber.tr();
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
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
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return requiredField.tr();
                                  }
                                  if (double.tryParse(value) == null) {
                                    return invalidNumber.tr();
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _accuracy,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: allowedDistance.tr(),
                          icon: Icons.gps_fixed,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return requiredField.tr();
                          }
                          if (double.tryParse(value) == null) {
                            return invalidNumber.tr();
                          }
                          return null;
                        },
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return requiredField.tr();
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _workHours,
                        readOnly: true,
                        onTap: _pickWorkHours,
                        decoration: _inputDecoration(
                          label: WorkHours.tr(),
                          icon: Icons.access_time,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return requiredField.tr();
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    createMarket();
                                  }
                                },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            disabledBackgroundColor: kPrimaryColor.withOpacity(
                              0.5,
                            ),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
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
      ),
    );
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (result != null) {
      setState(() {
        _lat.text = result["lat"].toString();
        _lng.text = result["lng"].toString();
        _address.text = result["address"];
      });
    }
  }
}
