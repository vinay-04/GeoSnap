import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:geosnap/services/location.dart';
import 'package:saver_gallery/saver_gallery.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  XFile? _capturedImage;
  bool _addLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized) return;

    try {
      final XFile photo = await _controller!.takePicture();
      setState(() {
        _capturedImage = photo;
      });

      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image(image: FileImage(File(_capturedImage!.path))),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _capturedImage = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Retake'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (_addLocation) {
                        final LocationOverlay locationOverlay =
                            LocationOverlay();
                        locationOverlay.initState();
                        LocationOverlay.overlayLocationOnImageFromPath(
                            _capturedImage!.path);
                      } else {
                        final String fileName = DateTime.now()
                            .toIso8601String()
                            .replaceAll(RegExp(r'[:-]'), '')
                            .substring(0, 12);
                        SaverGallery.saveFile(
                          filePath: _capturedImage!.path,
                          fileName: 'geoSnap_$fileName.jpg',
                          skipIfExists: false,
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image saved to gallery'),
                        ),
                      );
                    },
                    child: const Text('Keep'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _isCameraInitialized
              ? Transform.rotate(
                  angle: Platform.isAndroid ? 0 : 0,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: CameraPreview(_controller!),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(
                  color: Colors.white,
                )),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Add Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Transform.rotate(
                          angle: Platform.isAndroid ? 0 : 0,
                          child: Switch(
                            value: _addLocation,
                            onChanged: (value) {
                              setState(() {
                                _addLocation = value;
                              });
                            },
                            activeColor: Colors.white,
                            activeTrackColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      onPressed: _captureImage,
                      elevation: 4,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
