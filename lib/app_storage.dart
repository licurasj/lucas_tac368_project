import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'app_data.dart';

class AppStorage {
  static const String _dataFileName = 'hybrid_note_app_data.json';
  static const String _deviceFileName = 'hybrid_note_app_device.txt';
  static const String _localeFileName = 'hybrid_note_app_locale.txt';

  Future<File> _getDataFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_dataFileName');
  }

  Future<File> _getDeviceFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_deviceFileName');
  }

  Future<File> _getLocaleFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_localeFileName');
  }

  Future<String> getOrCreateDeviceId() async {
    final File file = await _getDeviceFile();

    if (await file.exists()) {
      final String savedId = await file.readAsString();
      if (savedId.trim().isNotEmpty) {
        return savedId.trim();
      }
    }

    final String newId = const Uuid().v4();
    await file.writeAsString(newId);
    return newId;
  }

  Future<AppData> loadAppData() async {
    final String deviceId = await getOrCreateDeviceId();
    final File file = await _getDataFile();

    if (!await file.exists()) {
      final AppData emptyData = AppData.empty(deviceId);
      await saveAppData(emptyData);
      return emptyData;
    }

    try {
      final String rawJson = await file.readAsString();
      final Map<String, dynamic> decoded =
          jsonDecode(rawJson) as Map<String, dynamic>;

      final AppData loadedData = AppData.fromJson(decoded);

      if (loadedData.deviceId.isEmpty) {
        return loadedData.copyWith(deviceId: deviceId);
      }

      return loadedData;
    } catch (_) {
      final AppData emptyData = AppData.empty(deviceId);
      await saveAppData(emptyData);
      return emptyData;
    }
  }

  Future<void> saveAppData(AppData data) async {
    final File file = await _getDataFile();
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data.toJson()));
  }

  Future<String?> loadPreferredLocaleCode() async {
    final File file = await _getLocaleFile();

    if (!await file.exists()) {
      return null;
    }

    final String code = (await file.readAsString()).trim();

    if (code.isEmpty || code == 'system') {
      return null;
    }

    return code;
  }

  Future<void> savePreferredLocaleCode(String? localeCode) async {
    final File file = await _getLocaleFile();
    await file.writeAsString(localeCode == null ? 'system' : localeCode);
  }
}

