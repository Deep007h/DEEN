import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

/// Abstract interface for controlling hardware display brightness and system audio volume.
abstract class DeviceControlsService {
  Future<double> getScreenBrightness();
  Future<void> setScreenBrightness(double brightness);
  Future<void> resetScreenBrightness();
  Future<double> getVolume();
  Future<void> setVolume(double volume);
  void hideSystemVolumeUI();
  void showSystemVolumeUI();
  void addVolumeListener(ValueChanged<double> onVolumeChanged);
  void removeVolumeListener();
}

/// Production implementation of [DeviceControlsService] interfacing with Android/iOS platform channels.
class PlatformDeviceControlsService implements DeviceControlsService {
  final ScreenBrightness _screenBrightness;
  final VolumeController _volumeController;

  PlatformDeviceControlsService({
    ScreenBrightness? screenBrightness,
    VolumeController? volumeController,
  })  : _screenBrightness = screenBrightness ?? ScreenBrightness.instance,
        _volumeController = volumeController ?? VolumeController.instance;

  @override
  Future<double> getScreenBrightness() async {
    try {
      final brightness = await _screenBrightness.application;
      return brightness.clamp(0.0, 1.0);
    } catch (e) {
      developer.log('Unable to get screen brightness: $e', name: 'DeviceControlsService');
      return 0.5;
    }
  }

  @override
  Future<void> setScreenBrightness(double brightness) async {
    final clamped = brightness.clamp(0.0, 1.0);
    try {
      await _screenBrightness.setApplicationScreenBrightness(clamped);
    } catch (e) {
      developer.log('Unable to set screen brightness ($clamped): $e', name: 'DeviceControlsService');
    }
  }

  @override
  Future<void> resetScreenBrightness() async {
    try {
      await _screenBrightness.resetApplicationScreenBrightness();
    } catch (e) {
      developer.log('Unable to reset screen brightness: $e', name: 'DeviceControlsService');
    }
  }

  @override
  Future<double> getVolume() async {
    try {
      final vol = await _volumeController.getVolume();
      return vol.clamp(0.0, 1.0);
    } catch (e) {
      developer.log('Unable to get system volume: $e', name: 'DeviceControlsService');
      return 1.0;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    try {
      await _volumeController.setVolume(clamped);
    } catch (e) {
      developer.log('Unable to set system volume ($clamped): $e', name: 'DeviceControlsService');
    }
  }

  @override
  void hideSystemVolumeUI() {
    try {
      _volumeController.showSystemUI = false;
    } catch (e) {
      developer.log('Unable to hide system volume UI: $e', name: 'DeviceControlsService');
    }
  }

  @override
  void showSystemVolumeUI() {
    try {
      _volumeController.showSystemUI = true;
    } catch (e) {
      developer.log('Unable to show system volume UI: $e', name: 'DeviceControlsService');
    }
  }

  @override
  void addVolumeListener(ValueChanged<double> onVolumeChanged) {
    try {
      _volumeController.addListener((volume) {
        onVolumeChanged(volume.clamp(0.0, 1.0));
      }, fetchInitialVolume: false);
    } catch (e) {
      developer.log('Unable to register volume listener: $e', name: 'DeviceControlsService');
    }
  }

  @override
  void removeVolumeListener() {
    try {
      _volumeController.removeListener();
    } catch (e) {
      developer.log('Unable to remove volume listener: $e', name: 'DeviceControlsService');
    }
  }
}

/// In-memory mock implementation of [DeviceControlsService] for unit and widget tests.
class MockDeviceControlsService implements DeviceControlsService {
  double brightness = 0.5;
  double volume = 1.0;
  bool isSystemUIVisible = true;
  ValueChanged<double>? _listener;

  @override
  Future<double> getScreenBrightness() async => brightness;

  @override
  Future<void> setScreenBrightness(double val) async {
    brightness = val.clamp(0.0, 1.0);
  }

  @override
  Future<void> resetScreenBrightness() async {
    brightness = 0.5;
  }

  @override
  Future<double> getVolume() async => volume;

  @override
  Future<void> setVolume(double val) async {
    volume = val.clamp(0.0, 1.0);
    _listener?.call(volume);
  }

  @override
  void hideSystemVolumeUI() {
    isSystemUIVisible = false;
  }

  @override
  void showSystemVolumeUI() {
    isSystemUIVisible = true;
  }

  @override
  void addVolumeListener(ValueChanged<double> onVolumeChanged) {
    _listener = onVolumeChanged;
  }

  @override
  void removeVolumeListener() {
    _listener = null;
  }
}

/// Riverpod provider for [DeviceControlsService].
final deviceControlsServiceProvider = Provider<DeviceControlsService>((ref) {
  return PlatformDeviceControlsService();
});
