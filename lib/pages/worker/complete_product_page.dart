import 'dart:io';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../config.dart';
import '../../keys.dart'; // тут должен быть baseUrl

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
  bool saving = false;

  CameraController? _cameraController;
  Future<void>? _initCameraFuture;

  XFile? _photoProduct;
  XFile? _photoPrice;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    priceUnitController.dispose();
    super.dispose();
  }

  // ---------- GEO ----------
  Future<void> _initLocation() async {
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
      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Не удалось получить геолокацию: $e")),
      );
    }
  }

  // ---------- CAMERA ----------
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _initCameraFuture = _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('init camera error: $e');
    }
  }

  Future<void> _takePhoto({required bool isProduct}) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar( SnackBar(content: Text(cameraIsNotReadyYet.tr())));
      return;
    }

    try {
      await _initCameraFuture;
      final file = await _cameraController!.takePicture();

      setState(() {
        if (isProduct) {
          _photoProduct = file;
        } else {
          _photoPrice = file;
        }
      });
    } catch (e) {
      debugPrint('take photo error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorWhileFilming.tr())));
    }
  }

  Widget _buildPhotoPreview(XFile? file, String placeholder) {
    if (file == null) {
      return Container(
        height: 140,
        color: Colors.grey.shade200,
        child: Center(child: Text(placeholder, textAlign: TextAlign.center)),
      );
    }

    return SizedBox(
      height: 140,
      child: kIsWeb
          ? Image.network(file.path, fit: BoxFit.cover)
          : Image.file(File(file.path), fit: BoxFit.cover),
    );
  }

  // ---------- SAVE (PUT) ----------
  Future<void> _sendData() async {
    if (priceUnitController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar( SnackBar(content: Text(enterPrice.tr()
)));
      return;
    }

    if (_photoProduct == null || _photoPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нужно сделать 2 фото: товар и ценник')),
      );
      return;
    }

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar( SnackBar(content: Text(geo_not_determined.tr())));
      return;
    }

    setState(() => saving = true);

    try {
      // 🔹 используем прямой адрес API
      final uri = Uri.parse("$QYZ_API_BASE/taskDetail/update");
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer ${Config.bearerToken}';

      // 🔹 Поля
      request.fields['TaskDetailId'] = widget.taskDetailId;
      request.fields['GoodId'] = widget.goodId;
      request.fields['PriceUnit'] = priceUnitController.text.trim();
      request.fields['Lat'] = lat!.toString();
      request.fields['Lng'] = lng!.toString();

      // 🔹 Файлы
      if (kIsWeb) {
        final productBytes = await _photoProduct!.readAsBytes();
        final priceBytes = await _photoPrice!.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'PhotoProduct',
            productBytes,
            filename: _photoProduct!.name.endsWith('.jpg')
                ? _photoProduct!.name
                : '${_photoProduct!.name}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );

        request.files.add(
          http.MultipartFile.fromBytes(
            'PhotoPrice',
            priceBytes,
            filename: _photoPrice!.name.endsWith('.jpg')
                ? _photoPrice!.name
                : '${_photoPrice!.name}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'PhotoProduct',
            _photoProduct!.path,
          ),
        );
        request.files.add(
          await http.MultipartFile.fromPath('PhotoPrice', _photoPrice!.path),
        );
      }

      final response = await request.send();

      if (!mounted) return;
      setState(() => saving = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar( SnackBar(content: Text(saved.tr())));
        Navigator.of(context).pop(true);
      } else {
        final body = await response.stream.bytesToString();
        debugPrint('update taskDetail error: ${response.statusCode} $body');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${errorWhileSavingTheProduct.tr()} (${response.statusCode})')),
        );
      }
    } catch (e) {
      debugPrint('sendData exception: $e');
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(geolocationOrNetworkError.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:  Text(product_do.tr()),
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
      body: loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${Market.tr()}: ${widget.marketName}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${productsK.tr()}: ${widget.productName}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Card(
                      elevation: 3,
                      color: const Color.fromARGB(255, 255, 255, 255),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fix_params.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: priceUnitController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: price.tr(),
                                prefixIcon: Icon(Icons.attach_money),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 20,
                                  color: lat != null
                                      ? Colors.green
                                      : Colors.redAccent,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Lat: ${lat ?? noData.tr()}",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        "Lng: ${lng ?? noData.tr()}",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _updateLocation,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    "Гео",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Card(
                      elevation: 3,
                      color: const Color.fromARGB(255, 255, 255, 255),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                               fix.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              photo_disclaimer.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 190,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: _buildPhotoPreview(
                                              _photoProduct,
                                              product_photo.tr(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _takePhoto(isProduct: true),
                                          icon: const Icon(
                                            Icons.camera_alt_rounded,
                                          ),
                                          label: Text(
                                            takeAPicture.tr(),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[300],
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size.fromHeight(
                                              40,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: _buildPhotoPreview(
                                              _photoPrice,
                                              price_tag.tr(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _takePhoto(isProduct: false),
                                          icon: const Icon(
                                            Icons.camera_alt_rounded,
                                          ),
                                          label: Text(
                                            takeAPicture.tr(),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.blue[300],
                                            minimumSize: const Size.fromHeight(
                                              40,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: saving ? null : _sendData,
                        icon: saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(saving ? "Сохранение..." : confirm.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade200,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
    );
  }
}
