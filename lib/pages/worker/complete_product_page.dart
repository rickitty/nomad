import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:price_book/api_client.dart';
import 'package:price_book/pages/widgets/fullscreenCamera.dart';
import 'package:price_book/pages/widgets/loading_dialog.dart';
import '../../keys.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart';
import 'package:price_book/pages/widgets/dialogError.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  ThousandsSeparatorInputFormatter({this.allowDecimal = true});
  final bool allowDecimal;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // оставляем только цифры (+ . , если allowDecimal)
    final reg = allowDecimal ? RegExp(r'[0-9\.,]') : RegExp(r'[0-9]');
    final filtered = newValue.text
        .split('')
        .where((c) => reg.hasMatch(c))
        .join();

    String normalized = filtered.replaceAll(',', '.');
    String intPart = normalized;
    String fracPart = '';
    final hasDot = allowDecimal && normalized.contains('.');

    if (hasDot) {
      final dot = normalized.indexOf('.');
      intPart = normalized.substring(0, dot);
      fracPart = normalized.substring(dot + 1).replaceAll('.', '');
    }

    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    final formattedInt = _formatThousands(intPart);
    final resultText = hasDot ? '$formattedInt.$fracPart' : formattedInt;

    // курсор: сохраняем количество цифр слева
    final digitsLeft = _countDigits(
      newValue.text.substring(0, newValue.selection.end),
    );
    final newCursor = _cursorFromDigits(resultText, digitsLeft);

    return TextEditingValue(
      text: resultText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  String _formatThousands(String digits) {
    if (digits.isEmpty) return '';
    final b = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      b.write(digits[i]);
      count++;
      if (count % 3 == 0 && i != 0) b.write(' ');
    }
    return b.toString().split('').reversed.join();
  }

  int _countDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '').length;

  int _cursorFromDigits(String formatted, int digitsLeft) {
    if (digitsLeft <= 0) return 0;
    int seen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) seen++;
      if (seen == digitsLeft) return i + 1;
    }
    return formatted.length;
  }
}

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
  double? accuracy;

  CameraController? _cameraController;
  Future<void>? _initCameraFuture;

  bool priceError = false;
  bool showCameraSection = false;

  XFile? _photoProduct;
  XFile? _photoPrice;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initCamera();
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _getFreshPosition();
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    priceUnitController.dispose();
    super.dispose();
  }

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
      await AppDialogs.error(context, 'Ошибка получения геолокации: $e');
    }
  }

  Future<Position> _getFreshPosition() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    setState(() {
      lat = pos.latitude;
      lng = pos.longitude;
      accuracy = pos.accuracy;
    });
    return pos;
  }

  // Future<void> _updateLocation() async {
  //   try {
  //     final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.medium,
  //     );
  //     setState(() {
  //       lat = position.latitude;
  //       lng = position.longitude;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Не удалось получить геолокацию: $e")),
  //     );
  //   }
  // }

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
    final cameras = await availableCameras();

    final photo = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenCameraPage(camera: cameras.first),
      ),
    );

    if (photo == null) return;

    setState(() {
      if (isProduct) {
        _photoProduct = photo;
      } else {
        _photoPrice = photo;
      }
    });
  }

  Widget _buildCameraOrPhoto({required XFile? file}) {
    if (file != null) {
      return kIsWeb
          ? Image.network(file.path, fit: BoxFit.cover)
          : Image.file(File(file.path), fit: BoxFit.cover);
    }

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    }

    return const Center(child: CircularProgressIndicator());
  }

  Future<http.MultipartFile> _compressAndConvert(
    XFile xfile,
    String fieldName,
  ) async {
    if (kIsWeb) {
      return http.MultipartFile.fromBytes(
        fieldName,
        await xfile.readAsBytes(),
        filename: '${xfile.name}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
    }

    final inputPath = xfile.path;
    final fileName = (xfile.name.isNotEmpty)
        ? xfile.name
        : inputPath.split('/').last;

    final outPath =
        '${Directory.systemTemp.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_$fileName';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      inputPath,
      outPath,
      quality: 50,
      format: CompressFormat.jpeg,
    );

    final pathToSend = compressed?.path ?? inputPath;

    return http.MultipartFile.fromPath(
      fieldName,
      pathToSend,
      filename: fileName,
      contentType: MediaType('image', 'jpeg'),
    );
  }

  Future<void> _sendData() async {
    showLoadingDialog(context, text: sendingData.tr());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(geo_not_determined.tr())));
      return;
    }

    if (accuracy != null && accuracy! > 80) {
      await AppDialogs.error(
        context,
        'Слабый GPS: точность ~${accuracy!.toStringAsFixed(0)}м. Включите GPS/выйдите ближе к окну и нажмите ещё раз.',
      );
      return;
    }

    if (priceUnitController.text.trim().isEmpty) {
      setState(() => priceError = true);
      return;
    }

    if (_photoProduct == null || _photoPrice == null) {
      await AppDialogs.error(context, 'Нужно сделать 2 фото: товар и ценник');
      return;
    }

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(geo_not_determined.tr())));
      return;
    }

    setState(() => saving = true);

    try {
      String toCommaCoord(double v) =>
          v.toStringAsFixed(6).replaceAll('.', ',');

      final fields = <String, String>{
        'TaskDetailId': widget.taskDetailId,
        'GoodId': widget.goodId,
        'PriceUnit': priceUnitController.text.trim().replaceAll(',', '.'),
        'Lng': toCommaCoord(lng!),
        'Lat': toCommaCoord(lat!),
      };

      final files = <http.MultipartFile>[];

      if (kIsWeb) {
        files.add(
          http.MultipartFile.fromBytes(
            'PhotoProduct',
            await _photoProduct!.readAsBytes(),
            filename: '${_photoProduct!.name}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
        files.add(
          http.MultipartFile.fromBytes(
            'PhotoPrice',
            await _photoPrice!.readAsBytes(),
            filename: '${_photoPrice!.name}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        files.add(await _compressAndConvert(_photoProduct!, 'PhotoProduct'));
        files.add(await _compressAndConvert(_photoPrice!, 'PhotoPrice'));
      }

      final response = await ApiClient.multipartPut(
        '/taskDetail/update',
        fields,
        files,
        context,
      );

      if (!mounted) return;
      setState(() => saving = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(saved.tr())));
        Navigator.of(context).pop(true);
      } else {
        final body = await response.stream.bytesToString();
        debugPrint('update taskDetail error: ${response.statusCode} $body');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${errorWhileSavingTheProduct.tr()} (${response.statusCode})',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('sendData exception: $e');
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(geolocationOrNetworkError.tr())));
    } finally {
      hideLoadingDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product_do.tr()),
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
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(wereGettingYourLocation.tr()),
                ],
              ),
            )
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
                                    "${productsK.tr()}: ${widget.productName}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${Market.tr()}: ${widget.marketName}",
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
                              inputFormatters: [
                                ThousandsSeparatorInputFormatter(
                                  allowDecimal: true,
                                ),
                              ],
                              onChanged: (_) {
                                if (priceError) {
                                  setState(() => priceError = false);
                                }
                              },
                              decoration: InputDecoration(
                                labelText: price.tr(),
                                prefixIcon: const Icon(Icons.wallet),
                                border: const OutlineInputBorder(),
                                errorText: priceError ? enterPrice.tr() : null,
                              ),
                            ),

                            // Row(
                            //   children: [
                            //     Icon(
                            //       Icons.location_on_rounded,
                            //       size: 20,
                            //       color: lat != null
                            //           ? Colors.green
                            //           : Colors.redAccent,
                            //     ),
                            //     const SizedBox(width: 6),
                            //     Expanded(
                            //       child: Column(
                            //         crossAxisAlignment:
                            //             CrossAxisAlignment.start,
                            //         children: [
                            //           Text(
                            //             "Lat: ${lat ?? noData.tr()}",
                            //             style: const TextStyle(fontSize: 13),
                            //           ),
                            //           Text(
                            //             "Lng: ${lng ?? noData.tr()}",
                            //             style: const TextStyle(fontSize: 13),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //     ElevatedButton.icon(
                            //       onPressed: _updateLocation,
                            //       icon: const Icon(
                            //         Icons.refresh_rounded,
                            //         size: 18,
                            //       ),
                            //       label: const Text(
                            //         "Гео",
                            //         style: TextStyle(fontSize: 13),
                            //       ),
                            //       style: ElevatedButton.styleFrom(
                            //         padding: const EdgeInsets.symmetric(
                            //           horizontal: 10,
                            //           vertical: 8,
                            //         ),
                            //         shape: RoundedRectangleBorder(
                            //           borderRadius: BorderRadius.circular(20),
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
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
                            if (!showCameraSection) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      showCameraSection = true;
                                    });
                                  },
                                  icon: const Icon(Icons.camera_alt_rounded),
                                  label: Text(openCamera.tr()),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (showCameraSection) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 220,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            productK.tr(),
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: _buildCameraOrPhoto(
                                                file: _photoProduct,
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
                                            label: Text(takeAPicture.tr()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue[300],
                                              foregroundColor: Colors.white,
                                              minimumSize:
                                                  const Size.fromHeight(40),
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
                                          Text(
                                            price.tr(),
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: _buildCameraOrPhoto(
                                                file: _photoPrice,
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
                                            label: Text(takeAPicture.tr()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue[300],
                                              foregroundColor: Colors.white,
                                              minimumSize:
                                                  const Size.fromHeight(40),
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
                        label: Text(saving ? saveWdots.tr() : confirm.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[300],
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
