import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:price_book/keys.dart';

import '../../config.dart';

class WorkerProductTaskPage extends StatefulWidget {
  final String taskId;
  final String objectId;
  final String productId;
  final String productName;
  final String? productCategory;
  final String? existingPhotoUrl;
  final String? existingPrice;

  const WorkerProductTaskPage({
    super.key,
    required this.taskId,
    required this.objectId,
    required this.productId,
    required this.productName,
    this.productCategory,
    this.existingPhotoUrl,
    this.existingPrice,
  });

  @override
  State<WorkerProductTaskPage> createState() => _WorkerProductTaskPageState();
}

class _WorkerProductTaskPageState extends State<WorkerProductTaskPage> {
  CameraController? _cameraController;
  Future<void>? _initCameraFuture;

  final List<XFile> _photos = [];
  int _selectedPhotoIndex = 0;

  bool get hasPhoto => _photos.isNotEmpty;

  final _priceController = TextEditingController();
  bool _saving = false;

  bool get _isAlreadyFilled =>
      (widget.existingPhotoUrl != null &&
          widget.existingPhotoUrl!.isNotEmpty) &&
      (widget.existingPrice != null && widget.existingPrice!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    if (widget.existingPrice != null) {
      _priceController.text = widget.existingPrice!;
    }
    _requestPermissions();
    _initCamera();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.location.request();
    await Permission.storage.request();
  }

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
      debugPrint('initCamera error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 15),
    );

    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cameraIsNotReadyYet.tr())));
      return;
    }

    try {
      await _initCameraFuture;
      final file = await _cameraController!.takePicture();

      setState(() {
        _photos.add(file);
        _selectedPhotoIndex = _photos.length - 1;
      });
    } catch (e) {
      debugPrint('takePhoto error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorWhileFilming.tr())));
    }
  }

  Future<void> _save() async {
  if (!hasPhoto &&
      (widget.existingPhotoUrl == null || widget.existingPhotoUrl!.isEmpty)) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(takeAPictureFirst.tr())));
    return;
  }
  if (_priceController.text.trim().isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(enterPrice.tr())));
    return;
  }

  setState(() => _saving = true);

  try {
    final pos = await _getPosition();

    final uri = Uri.parse(
      '$baseUrl/api/v1/monitoring/taskDetail/update',
    );

    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $bearerToken'
      ..fields['TaskDetailId'] = widget.objectId 
      ..fields['GoodId'] = widget.productId    
      ..fields['PriceUnit'] = _priceController.text.trim()
      ..fields['Lat'] = pos.latitude.toString()
      ..fields['Lng'] = pos.longitude.toString();

    if (_photos.isNotEmpty) {

      request.files.add(
        await http.MultipartFile.fromPath(
          'PhotoPrice',
          _photos.first.path,
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (!mounted) return;
    setState(() => _saving = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(saved.tr())));
      Navigator.pop(context, true);
    } else if (response.statusCode == 403) {
      debugPrint('403: $body');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(geolocationIsNotMatching.tr())),
      );
    } else {
      debugPrint('save product error: ${response.statusCode} $body');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorWhileSavingTheProduct.tr())),
      );
    }

    debugPrint('Sending priceUnit: ${_priceController.text}');
    debugPrint('Photos: ${_photos.map((p) => p.path).toList()}');
  } catch (e) {
    debugPrint('save product exception: $e');
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(content: Text(geolocationOrNetworkError.tr())),
    );
  }
}


  void _retakePhoto() {
    setState(() {
      _photos.clear();
      _selectedPhotoIndex = 0;
    });
  }


  Widget _buildCameraArea() {
    if (_cameraController == null || _initCameraFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<void>(
      future: _initCameraFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildMainPhotoPreview() {
    if (hasPhoto) {
      final file = _photos[_selectedPhotoIndex];
      return kIsWeb
          ? Image.network(file.path, fit: BoxFit.contain)
          : Image.file(File(file.path), fit: BoxFit.contain);
    }

    if (widget.existingPhotoUrl != null &&
        widget.existingPhotoUrl!.isNotEmpty) {
      return Image.network(
        '$fileBaseUrl${widget.existingPhotoUrl}',
        fit: BoxFit.contain,
      );
    }

    return Center(
      child: Text(noPhotoYet.tr(), style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildThumbnails() {
    if (!hasPhoto) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final file = _photos[index];
          final isSelected = index == _selectedPhotoIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPhotoIndex = index;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.white,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: kIsWeb
                  ? Image.network(
                      file.path,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(file.path),
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.productName.isEmpty ? noName.tr() : widget.productName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          if (widget.productCategory != null &&
              widget.productCategory!.isNotEmpty)
            Text(
              widget.productCategory!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isAlreadyFilled
                      ? Colors.green.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAlreadyFilled
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: _isAlreadyFilled ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isAlreadyFilled ? filled.tr() : notFilled.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _isAlreadyFilled ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.existingPrice != null &&
                  widget.existingPrice!.isNotEmpty)
                Text(
                  '${currentPrice.tr()}: ${widget.existingPrice}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.productName.isEmpty ? productK.tr() : widget.productName,
        ),
      ),
      body: Column(
        children: [
          _buildProductHeader(),
          Expanded(
            child: Column(
              children: [
                // камера / превью
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: hasPhoto
                          ? _buildMainPhotoPreview()
                          : _buildCameraArea(),
                    ),
                  ),
                ),

                // миниатюры (если есть)
                _buildThumbnails(),

                // нижняя часть с кнопками и TextField
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      12,
                      12,
                      12 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: hasPhoto ? _retakePhoto : _takePhoto,
                                icon: Icon(
                                  hasPhoto ? Icons.refresh : Icons.camera_alt,
                                ),
                                label: Text(
                                  hasPhoto ? 'Переснять' : takeAPicture.tr(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: enterPrice.tr(),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(confirm.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
