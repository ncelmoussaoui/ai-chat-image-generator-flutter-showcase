import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for saving images to the device gallery
class GalleryService {
  GalleryService._();

  /// Save an image to the gallery
  static Future<bool> saveImage(String filePath) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Check and request permissions first
        final hasAccess = await checkPermissions();
        if (!hasAccess) return false;

        // Save file using 'gal' package
        await Gal.putImage(filePath);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving image to gallery: $e');
      return false;
    }
  }

  /// Check and request permissions
  static Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need 'photos' permission
      // For older versions, we need 'storage'
      final status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) return true;
      
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted || photosStatus.isLimited;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) return true;

      final requestStatus = await Permission.photos.request();
      return requestStatus.isGranted || requestStatus.isLimited;
    }
    return true;
  }
}
