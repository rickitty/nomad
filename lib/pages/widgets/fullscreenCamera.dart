import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FullscreenCameraPage extends StatelessWidget {
  final CameraDescription camera;

  const FullscreenCameraPage({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    return FutureBuilder(
      future: controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final size = MediaQuery.of(context).size;
        final squareSize = size.width * 0.75;
        final topPadding = (size.height - squareSize) / 2;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              /// CAMERA
              CameraPreview(controller),

              /// TOP DARK
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topPadding,
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),

              /// BOTTOM DARK
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: topPadding,
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),

              /// LEFT DARK
              Positioned(
                top: topPadding,
                left: 0,
                width: (size.width - squareSize) / 2,
                height: squareSize,
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),

              /// RIGHT DARK
              Positioned(
                top: topPadding,
                right: 0,
                width: (size.width - squareSize) / 2,
                height: squareSize,
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),

              /// SQUARE FRAME
              Positioned(
                top: topPadding,
                left: (size.width - squareSize) / 2,
                child: Container(
                  width: squareSize,
                  height: squareSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              /// CAPTURE BUTTON
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton(
                    onPressed: () async {
                      final photo = await controller.takePicture();
                      Navigator.pop(context, photo);
                    },
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
