import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'app_data.dart';

class AppStorage {
  static const String _dataFileName = 'hybrid_note_app_data.json';
  static const String _deviceFileName = 'hybrid_note_app_device.txt';

  Future<File> _getDataFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_dataFileName');
  }

  Future<File> _getDeviceFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_deviceFileName');
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
}
