import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'app_data.dart';
import 'sync_result.dart';

class DriveSyncService {
  static const String _fileName = 'hybrid_note_app_data.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope,
    ],
  );

  http.Client? _authClient;

  bool get isSignedIn {
    return _googleSignIn.currentUser != null;
  }

  String? get signedInEmail {
    return _googleSignIn.currentUser?.email;
  }

  Future<bool> signIn() async {
    final drive.DriveApi? api = await _getDriveApi();
    return api != null;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _authClient?.close();
    _authClient = null;
  }

  Future<bool> tryRestorePreviousSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      return account != null;
    } catch (_) {
      return false;
    }
  }

  // Manual sync / login sync / pull-to-refresh sync:
  // last-write-wins by AppData.lastModified. This avoids stale devices
  // re-adding tasks that were cleared/deleted on another device.
  Future<SyncResult> sync({
    required AppData localData,
  }) async {
    try {
      final drive.DriveApi? driveApi = await _getDriveApi();

      if (driveApi == null) {
        return SyncResult.failed(
          'Google sign-in failed or was cancelled. Local data is still saved.',
        );
      }

      return _mergeThenUpload(
        driveApi: driveApi,
        localData: localData,
      );
    } catch (error) {
      return SyncResult.failed(
        'Google Drive sync failed. Local data is still saved. $error',
      );
    }
  }

  // Startup auto-sync:
  // only runs if a previous Google sign-in can be restored silently.
  Future<SyncResult> autoSyncIfSignedIn({
    required AppData localData,
  }) async {
    try {
      if (_googleSignIn.currentUser == null) {
        await tryRestorePreviousSignIn();
      }

      if (_googleSignIn.currentUser == null) {
        return SyncResult.failed(
          'Not signed in. Auto-sync skipped.',
        );
      }

      final drive.DriveApi? driveApi = await _getDriveApi();

      if (driveApi == null) {
        return SyncResult.failed(
          'Google sign-in could not be restored. Local data is still saved.',
        );
      }

      return _mergeThenUpload(
        driveApi: driveApi,
        localData: localData,
      );
    } catch (error) {
      return SyncResult.failed(
        'Auto-sync failed. Local data is still saved. $error',
      );
    }
  }

  // Local edit sync:
  // upload local data as the new source of truth. This is important for deletes.
  // If you delete/clear/tick locally and we used merge here, the old cloud item
  // could be merged back. So local edits push the new local JSON to Drive.
  Future<SyncResult> pushLocalToDrive({
    required AppData localData,
  }) async {
    try {
      if (_googleSignIn.currentUser == null) {
        return SyncResult.failed(
          'Not signed in. Local data is saved but not synced.',
        );
      }

      final drive.DriveApi? driveApi = await _getDriveApi();

      if (driveApi == null) {
        return SyncResult.failed(
          'Google sign-in could not be restored. Local data is still saved.',
        );
      }

      final String? remoteFileId = await _findRemoteFileId(driveApi);

      // Upload the exact app state that AppCubit already timestamped and saved.
      // Do not create a second modified copy here, because returning a modified
      // copy from an older network request can overwrite newer checkbox edits.
      if (remoteFileId == null) {
        await _createRemoteFile(
          driveApi: driveApi,
          data: localData,
        );
      } else {
        await _updateRemoteFile(
          driveApi: driveApi,
          fileId: remoteFileId,
          data: localData,
        );
      }

      return SyncResult.success(
        status: SyncStatus.localNewerUploaded,
        message: 'Sync complete.',
        syncedData: localData,
      );
    } catch (error) {
      return SyncResult.failed(
        'Auto-sync failed. Local data is still saved. $error',
      );
    }
  }

  Future<SyncResult> _mergeThenUpload({
    required drive.DriveApi driveApi,
    required AppData localData,
  }) async {
    final String? remoteFileId = await _findRemoteFileId(driveApi);

    if (remoteFileId == null) {
      await _createRemoteFile(
        driveApi: driveApi,
        data: localData,
      );

      return SyncResult.success(
        status: SyncStatus.noRemoteCreated,
        message: 'Sync complete.',
        syncedData: localData,
      );
    }

    final AppData? remoteData = await _downloadRemoteData(
      driveApi: driveApi,
      fileId: remoteFileId,
    );

    if (remoteData == null) {
      await _updateRemoteFile(
        driveApi: driveApi,
        fileId: remoteFileId,
        data: localData,
      );

      return SyncResult.success(
        status: SyncStatus.localNewerUploaded,
        message: 'Sync complete.',
        syncedData: localData,
      );
    }

    final DateTime localModified = localData.lastModified.toUtc();
    final DateTime remoteModified = remoteData.lastModified.toUtc();

    if (remoteModified.isAfter(localModified)) {
      return SyncResult.success(
        status: SyncStatus.remoteNewerDownloaded,
        message: 'Sync complete.',
        syncedData: remoteData,
      );
    }

    if (localModified.isAfter(remoteModified)) {
      await _updateRemoteFile(
        driveApi: driveApi,
        fileId: remoteFileId,
        data: localData,
      );

      return SyncResult.success(
        status: SyncStatus.localNewerUploaded,
        message: 'Sync complete.',
        syncedData: localData,
      );
    }

    return SyncResult.success(
      status: SyncStatus.noChanges,
      message: 'Sync complete.',
      syncedData: localData,
    );
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      print('Google Drive: currentUser = ${_googleSignIn.currentUser?.email}');

      GoogleSignInAccount? account = _googleSignIn.currentUser;

      if (account == null) {
        print('Google Drive: opening Google sign-in...');
        account = await _googleSignIn.signIn();
      }

      if (account == null) {
        print('Google Drive: signIn returned null.');
        return null;
      }

      print('Google Drive: signed in as ${account.email}');
      print('Google Drive: getting authenticated client...');

      _authClient = await _googleSignIn.authenticatedClient();

      if (_authClient == null) {
        print('Google Drive: authenticatedClient returned null.');
        return null;
      }

      print('Google Drive: Drive API ready.');
      return drive.DriveApi(_authClient!);
    } catch (error, stackTrace) {
      print('Google Drive: _getDriveApi error: $error');
      print(stackTrace);
      return null;
    }
  }

  Future<String?> _findRemoteFileId(drive.DriveApi driveApi) async {
    final drive.FileList result = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName' and trashed = false",
      $fields: 'files(id, name, modifiedTime)',
    );

    if (result.files == null || result.files!.isEmpty) {
      return null;
    }

    return result.files!.first.id;
  }

  Future<AppData?> _downloadRemoteData({
    required drive.DriveApi driveApi,
    required String fileId,
  }) async {
    final drive.Media media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> bytes = [];

    await for (final List<int> chunk in media.stream) {
      bytes.addAll(chunk);
    }

    final String rawJson = utf8.decode(bytes);
    final Map<String, dynamic> decoded =
        jsonDecode(rawJson) as Map<String, dynamic>;

    return AppData.fromJson(decoded);
  }

  Future<void> _createRemoteFile({
    required drive.DriveApi driveApi,
    required AppData data,
  }) async {
    final drive.File fileMetadata = drive.File()
      ..name = _fileName
      ..parents = ['appDataFolder'];

    final String encodedData = _encodeAppData(data);
    final List<int> encodedBytes = utf8.encode(encodedData);

    final drive.Media media = drive.Media(
      Stream<List<int>>.value(encodedBytes),
      encodedBytes.length,
      contentType: 'application/json',
    );

    await driveApi.files.create(
      fileMetadata,
      uploadMedia: media,
    );
  }

  Future<void> _updateRemoteFile({
    required drive.DriveApi driveApi,
    required String fileId,
    required AppData data,
  }) async {
    final String encodedData = _encodeAppData(data);
    final List<int> encodedBytes = utf8.encode(encodedData);

    final drive.Media media = drive.Media(
      Stream<List<int>>.value(encodedBytes),
      encodedBytes.length,
      contentType: 'application/json',
    );

    await driveApi.files.update(
      drive.File(),
      fileId,
      uploadMedia: media,
    );
  }

  String _encodeAppData(AppData data) {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data.toJson());
  }

  AppData _copyWithSyncTime(AppData data) {
    return data.copyWith(
      lastModified: DateTime.now().toUtc(),
    );
  }

  AppData _mergeAppData({
    required AppData localData,
    required AppData remoteData,
  }) {
    final Map<String, dynamic> localJson =
        Map<String, dynamic>.from(localData.toJson());
    final Map<String, dynamic> remoteJson =
        Map<String, dynamic>.from(remoteData.toJson());

    final Map<String, dynamic> merged = {
      ...remoteJson,
      ...localJson,
    };

    merged['schemaVersion'] = _maxInt(
      localJson['schemaVersion'],
      remoteJson['schemaVersion'],
    );
    merged['deviceId'] = localJson['deviceId'] ?? remoteJson['deviceId'];
    merged['lastModified'] = DateTime.now().toUtc().toIso8601String();

    merged['categories'] = _mergeStringList(
      _asList(localJson['categories']),
      _asList(remoteJson['categories']),
      removeLegacyMyTasks: true,
    );

    merged['tasks'] = _mergeTasksByTitle(
      _asListOfMaps(localJson['tasks']),
      _asListOfMaps(remoteJson['tasks']),
    );

    merged['journalEntries'] = _mergeExactDuplicateOnly(
      _asListOfMaps(localJson['journalEntries']),
      _asListOfMaps(remoteJson['journalEntries']),
      keyBuilder: _journalExactKey,
    );

    merged['watchItems'] = _mergeExactDuplicateOnly(
      _asListOfMaps(localJson['watchItems']),
      _asListOfMaps(remoteJson['watchItems']),
      keyBuilder: _watchExactKey,
    );

    merged['groceryItems'] = _mergeExactDuplicateOnly(
      _asListOfMaps(localJson['groceryItems']),
      _asListOfMaps(remoteJson['groceryItems']),
      keyBuilder: _genericExactKey,
    );

    return AppData.fromJson(merged);
  }

  List<Map<String, dynamic>> _mergeTasksByTitle(
    List<Map<String, dynamic>> localTasks,
    List<Map<String, dynamic>> remoteTasks,
  ) {
    final Map<String, Map<String, dynamic>> merged = {};

    for (final Map<String, dynamic> task in remoteTasks) {
      final String key = _taskTitleKey(task);
      merged[key.isEmpty ? _fallbackItemKey(task) : key] =
          Map<String, dynamic>.from(task);
    }

    for (final Map<String, dynamic> localTask in localTasks) {
      final String key = _taskTitleKey(localTask);
      final String safeKey = key.isEmpty ? _fallbackItemKey(localTask) : key;
      final Map<String, dynamic>? remoteTask = merged[safeKey];

      if (remoteTask == null) {
        merged[safeKey] = Map<String, dynamic>.from(localTask);
        continue;
      }

      merged[safeKey] = _mergeOneTaskByTitle(
        localTask: localTask,
        remoteTask: remoteTask,
      );
    }

    final List<Map<String, dynamic>> output = merged.values.toList();
    output.sort(_compareByUpdatedAtOrCreatedAtDescending);
    return output;
  }

  Map<String, dynamic> _mergeOneTaskByTitle({
    required Map<String, dynamic> localTask,
    required Map<String, dynamic> remoteTask,
  }) {
    final bool localNewer = _itemUpdatedAt(localTask).isAfter(
      _itemUpdatedAt(remoteTask),
    );

    final Map<String, dynamic> base = Map<String, dynamic>.from(
      localNewer ? localTask : remoteTask,
    );
    final Map<String, dynamic> older = localNewer ? remoteTask : localTask;

    base['subtasks'] = _mergeSubtasksByTitle(
      _asListOfMaps(localTask['subtasks']),
      _asListOfMaps(remoteTask['subtasks']),
    );

    base['isCompleted'] =
        _boolValue(localTask['isCompleted']) || _boolValue(remoteTask['isCompleted']);

    base['category'] = _preferNonEmpty(
      base['category'],
      older['category'],
    );

    base['description'] = _preferNonEmpty(
      base['description'],
      older['description'],
    );

    base['reminderAt'] = _preferNewerField(
      localItem: localTask,
      remoteItem: remoteTask,
      field: 'reminderAt',
    );
    base['repeatFrequency'] = _preferNewerField(
      localItem: localTask,
      remoteItem: remoteTask,
      field: 'repeatFrequency',
    );
    base['customRepeatDays'] = _preferNewerField(
      localItem: localTask,
      remoteItem: remoteTask,
      field: 'customRepeatDays',
    );

    base['updatedAt'] = DateTime.now().toUtc().toIso8601String();

    return base;
  }

  List<Map<String, dynamic>> _mergeSubtasksByTitle(
    List<Map<String, dynamic>> localSubtasks,
    List<Map<String, dynamic>> remoteSubtasks,
  ) {
    final Map<String, Map<String, dynamic>> merged = {};

    for (final Map<String, dynamic> subtask in remoteSubtasks) {
      final String key = _normalizedString(subtask['title']);
      merged[key.isEmpty ? _fallbackItemKey(subtask) : key] =
          Map<String, dynamic>.from(subtask);
    }

    for (final Map<String, dynamic> localSubtask in localSubtasks) {
      final String key = _normalizedString(localSubtask['title']);
      final String safeKey = key.isEmpty ? _fallbackItemKey(localSubtask) : key;
      final Map<String, dynamic>? remoteSubtask = merged[safeKey];

      if (remoteSubtask == null) {
        merged[safeKey] = Map<String, dynamic>.from(localSubtask);
        continue;
      }

      final bool localNewer = _itemUpdatedAt(localSubtask).isAfter(
        _itemUpdatedAt(remoteSubtask),
      );

      final Map<String, dynamic> base = Map<String, dynamic>.from(
        localNewer ? localSubtask : remoteSubtask,
      );

      base['isCompleted'] = _boolValue(localSubtask['isCompleted']) ||
          _boolValue(remoteSubtask['isCompleted']);
      base['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      merged[safeKey] = base;
    }

    final List<Map<String, dynamic>> output = merged.values.toList();
    output.sort(_compareByUpdatedAtOrCreatedAtDescending);
    return output;
  }

  List<Map<String, dynamic>> _mergeExactDuplicateOnly(
    List<Map<String, dynamic>> localItems,
    List<Map<String, dynamic>> remoteItems, {
    required String Function(Map<String, dynamic> item) keyBuilder,
  }) {
    final Map<String, Map<String, dynamic>> merged = {};

    for (final Map<String, dynamic> item in remoteItems) {
      merged[keyBuilder(item)] = Map<String, dynamic>.from(item);
    }

    for (final Map<String, dynamic> item in localItems) {
      final String key = keyBuilder(item);
      final Map<String, dynamic>? existing = merged[key];

      if (existing == null) {
        merged[key] = Map<String, dynamic>.from(item);
        continue;
      }

      final bool localNewer = _itemUpdatedAt(item).isAfter(
        _itemUpdatedAt(existing),
      );

      merged[key] = Map<String, dynamic>.from(localNewer ? item : existing);
    }

    final List<Map<String, dynamic>> output = merged.values.toList();
    output.sort(_compareByUpdatedAtOrCreatedAtDescending);
    return output;
  }

  List<String> _mergeStringList(
    List<dynamic> localList,
    List<dynamic> remoteList, {
    required bool removeLegacyMyTasks,
  }) {
    final Set<String> seen = {};
    final List<String> output = [];

    void addValue(dynamic value) {
      final String text = value.toString().trim();
      if (text.isEmpty) {
        return;
      }
      if (removeLegacyMyTasks && text == 'My Tasks') {
        return;
      }
      final String key = text.toLowerCase();
      if (seen.add(key)) {
        output.add(text);
      }
    }

    addValue(AppData.defaultCategory);

    for (final dynamic value in localList) {
      addValue(value);
    }

    for (final dynamic value in remoteList) {
      addValue(value);
    }

    output.sort((a, b) {
      if (a == AppData.defaultCategory) {
        return -1;
      }
      if (b == AppData.defaultCategory) {
        return 1;
      }
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

    return output;
  }

  String _mergeMessage({
    required AppData localData,
    required AppData remoteData,
    required AppData mergedData,
  }) {
    return 'Sync complete.';
  }

  int _totalItemCount(AppData data) {
    final Map<String, dynamic> json = data.toJson();
    return _asList(json['tasks']).length +
        _asList(json['journalEntries']).length +
        _asList(json['watchItems']).length +
        _asList(json['groceryItems']).length;
  }

  String _taskTitleKey(Map<String, dynamic> item) {
    return 'task:${_normalizedString(item['title'])}';
  }

  String _journalExactKey(Map<String, dynamic> item) {
    final String title = _normalizedString(item['title']);
    final String body = _normalizedString(item['body'] ?? item['content']);
    final String date = _normalizedString(
      item['date'] ?? item['entryDate'] ?? item['createdAt'],
    );

    return 'journal:$title|$body|$date';
  }

  String _watchExactKey(Map<String, dynamic> item) {
    final List<String> parts = item.keys.toList()..sort();
    return 'watch:${parts.map((key) => '$key=${item[key]}').join('|')}';
  }

  String _genericExactKey(Map<String, dynamic> item) {
    final List<String> parts = item.keys.toList()..sort();
    return 'generic:${parts.map((key) => '$key=${item[key]}').join('|')}';
  }

  String _fallbackItemKey(Map<String, dynamic> item) {
    final String id = item['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      return 'id:$id';
    }

    return _genericExactKey(item);
  }

  int _compareByUpdatedAtOrCreatedAtDescending(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    return _itemUpdatedAt(b).compareTo(_itemUpdatedAt(a));
  }

  DateTime _itemUpdatedAt(Map<String, dynamic> item) {
    return _parseDateTime(item['updatedAt']) ??
        _parseDateTime(item['createdAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  dynamic _preferNewerField({
    required Map<String, dynamic> localItem,
    required Map<String, dynamic> remoteItem,
    required String field,
  }) {
    final bool localNewer = _itemUpdatedAt(localItem).isAfter(
      _itemUpdatedAt(remoteItem),
    );

    final dynamic preferred = localNewer ? localItem[field] : remoteItem[field];
    final dynamic fallback = localNewer ? remoteItem[field] : localItem[field];

    return preferred ?? fallback;
  }

  dynamic _preferNonEmpty(dynamic preferred, dynamic fallback) {
    final String preferredText = preferred?.toString().trim() ?? '';
    if (preferredText.isNotEmpty) {
      return preferred;
    }

    return fallback;
  }

  bool _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }

    return value.toString().toLowerCase() == 'true';
  }

  int _maxInt(dynamic a, dynamic b) {
    final int first = int.tryParse(a?.toString() ?? '') ?? 0;
    final int second = int.tryParse(b?.toString() ?? '') ?? 0;
    return first > second ? first : second;
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return value;
    }

    return [];
  }

  List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _normalizedString(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString())?.toUtc();
  }
}
