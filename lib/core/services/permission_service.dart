import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

enum PermissionStatusResult { granted, denied, permanentlyDenied, restricted }

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  int? _cachedAndroidSdkVersion;

  /// Get the Android SDK version using device_info_plus
  /// Caches the result to avoid repeated calls
  Future<int> _getAndroidSdkVersion() async {
    if (_cachedAndroidSdkVersion != null) {
      return _cachedAndroidSdkVersion!;
    }

    if (!Platform.isAndroid) return 0;

    try {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      _cachedAndroidSdkVersion = androidInfo.version.sdkInt;
      return _cachedAndroidSdkVersion!;
    } catch (e) {
      return 31;
    }
  }

  /// Check if running on Android 13 or higher (API 33+)
  Future<bool> _isAndroid13OrHigher() async {
    final sdkVersion = await _getAndroidSdkVersion();
    return sdkVersion >= 33;
  }

  Future<PermissionStatusResult> checkCameraPermissionStatus() async {
    final status = await permission_handler.Permission.camera.status;
    return _mapPermissionStatus(status);
  }

  /// Check storage permission status with automatic Android version handling
  /// For Android 13+: checks Permission.photos
  /// For Android 12 and below: checks Permission.storage
  /// For iOS: checks Permission.photos
  /// This method abstracts version differences from the caller
  Future<PermissionStatusResult> checkStoragePermissionStatus() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        final photosStatus = await permission_handler.Permission.photos.status;
        return _mapPermissionStatus(photosStatus);
      } else {
        final storageStatus =
            await permission_handler.Permission.storage.status;
        return _mapPermissionStatus(storageStatus);
      }
    } else if (Platform.isIOS) {
      final status = await permission_handler.Permission.photos.status;
      return _mapPermissionStatus(status);
    }
    return PermissionStatusResult.granted;
  }

  Future<PermissionStatusResult> requestCameraPermissionIfNeeded() async {
    final currentStatus = await checkCameraPermissionStatus();
    if (currentStatus == PermissionStatusResult.granted) {
      return PermissionStatusResult.granted;
    }

    final status = await permission_handler.Permission.camera.request();
    return _mapPermissionStatus(status);
  }

  /// Request storage permission with automatic Android version handling
  /// For Android 13+: requests Permission.photos
  /// For Android 12 and below: requests Permission.storage
  /// For iOS: requests Permission.photos
  /// This method abstracts version differences from the caller
  Future<PermissionStatusResult> requestStoragePermissionIfNeeded() async {
    final currentStatus = await checkStoragePermissionStatus();
    if (currentStatus == PermissionStatusResult.granted) {
      return PermissionStatusResult.granted;
    }

    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        final status = await permission_handler.Permission.photos.request();
        return _mapPermissionStatus(status);
      } else {
        final status = await permission_handler.Permission.storage.request();
        return _mapPermissionStatus(status);
      }
    } else if (Platform.isIOS) {
      final status = await permission_handler.Permission.photos.request();
      return _mapPermissionStatus(status);
    }
    return PermissionStatusResult.granted;
  }

  Future<bool> openAppSettings() async {
    return await permission_handler.openAppSettings();
  }

  PermissionStatusResult _mapPermissionStatus(
    permission_handler.PermissionStatus status,
  ) {
    if (status.isGranted || status.isLimited) {
      return PermissionStatusResult.granted;
    }
    if (status.isPermanentlyDenied)
      return PermissionStatusResult.permanentlyDenied;
    if (status.isRestricted) return PermissionStatusResult.restricted;
    return PermissionStatusResult.denied;
  }
}
