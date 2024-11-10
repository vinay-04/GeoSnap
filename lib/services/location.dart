import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;

class LocationOverlay {
  var location = Location();
  late Future<LocationData> currentLocation;
  late final double latitude;
  late final double longitude;

  void initState() {
    currentLocation = location.getLocation();
    currentLocation.then((value) {
      latitude = value.latitude!;
      longitude = value.longitude!;
    });
  }

  static Future<String> overlayLocationOnImage(
      String imagePath, double latitude, double longitude) async {
    final File imageFile = File(imagePath);
    final img.Image? originalImage =
        img.decodeImage(await imageFile.readAsBytes());

    if (originalImage == null) throw Exception('Failed to load image');

    final img.Image image = img.copyResize(originalImage,
        width: originalImage.width, height: originalImage.height);

    img.fillRect(
      image,
      x1: 20,
      y1: image.height - 90,
      x2: await geo.placemarkFromCoordinates(latitude, longitude).then((value) =>
          '${value[0].name ?? ''}, ${value[0].locality ?? ''}, ${value[0].administrativeArea ?? ''}'
                  .replaceAll(RegExp(r', ,|,$'), '')
                  .trim()
                  .length *
              12 +
          40),
      y2: image.height - 10,
      color: img.ColorFloat16.rgba(0, 0, 0, 0.4),
    );

    img.drawString(
      image,
      'Latitude: ${latitude.toStringAsFixed(6)}',
      font: img.arial24,
      x: 20,
      y: image.height - 90,
      color: img.ColorRgb8(255, 255, 255),
    );

    img.drawString(
      image,
      'Longitude: ${longitude.toStringAsFixed(6)}',
      font: img.arial24,
      x: 20,
      y: image.height - 60,
      color: img.ColorRgb8(255, 255, 255),
    );

    img.drawString(
      image,
      await geo.placemarkFromCoordinates(latitude, longitude).then((value) =>
          '${value[0].name ?? ''}, ${value[0].locality ?? ''}, ${value[0].administrativeArea ?? ''}'
              .replaceAll(RegExp(r', ,|,$'), '')
              .trim()),
      font: img.arial24,
      x: 20,
      y: image.height - 30,
      color: img.ColorRgb8(255, 255, 255),
    );

    final directory = await getTemporaryDirectory();
    final String overlayedImagePath = '${directory.path}/overlayed_image.jpg';

    File(overlayedImagePath).writeAsBytesSync(img.encodeJpg(image));

    final String fileName = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:-]'), '')
        .substring(0, 12);
    final result = await SaverGallery.saveFile(
        filePath: overlayedImagePath,
        fileName: 'geoSnap_$fileName.jpg',
        skipIfExists: false);
    if (result.isSuccess) {
      return overlayedImagePath;
    } else {
      throw Exception('Failed to save image to gallery');
    }
  }

  static Future<String> overlayLocationOnImageFromPath(String imagePath) async {
    final LocationData locationData = await Location().getLocation();

    return overlayLocationOnImage(
        imagePath, locationData.latitude!, locationData.longitude!);
  }
}
