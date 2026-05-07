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

  // Local edit sync still downloads/merges remote first. Tombstones make this
  // safe for deletes, while preserving independent offline additions from other
  // devices.
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

  Future<SyncResult> _mergeThenUpload({
    required drive.DriveApi driveApi,
    required AppData localData,
  }) async {
    final String? remoteFileId = await _findRemoteFileId(driveApi);

    if (remoteFileId == null) {
      final AppData uploadData = localData
          .copyWith(
            schemaVersion: 2,
            lastModified: DateTime.now().toUtc(),
          )
          .pruneOldTombstones();

      await _createRemoteFile(
        driveApi: driveApi,
        data: uploadData,
      );

      return SyncResult.success(
        status: SyncStatus.noRemoteCreated,
        message: 'Sync complete.',
        syncedData: uploadData,
      );
    }

    final AppData? remoteData = await _downloadRemoteData(
      driveApi: driveApi,
      fileId: remoteFileId,
    );

    if (remoteData == null) {
      final AppData uploadData = localData
          .copyWith(
            schemaVersion: 2,
            lastModified: DateTime.now().toUtc(),
          )
          .pruneOldTombstones();

      await _updateRemoteFile(
        driveApi: driveApi,
        fileId: remoteFileId,
        data: uploadData,
      );

      return SyncResult.success(
        status: SyncStatus.localNewerUploaded,
        message: 'Sync complete.',
        syncedData: uploadData,
      );
    }

    final AppData mergedData = _mergeAppData(
      localData: localData,
      remoteData: remoteData,
    );

    await _updateRemoteFile(
      driveApi: driveApi,
      fileId: remoteFileId,
      data: mergedData,
    );

    return SyncResult.success(
      status: SyncStatus.merged,
      message: 'Sync complete.',
      syncedData: mergedData,
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

  AppData _mergeAppData({
    required AppData localData,
    required AppData remoteData,
  }) {
    final Map<String, dynamic> localJson =
        Map<String, dynamic>.from(localData.toJson());
    final Map<String, dynamic> remoteJson =
        Map<String, dynamic>.from(remoteData.toJson());

    final List<Map<String, dynamic>> taskTombstones = _mergeTombstones(
      _asListOfMaps(localJson['taskTombstones']),
      _asListOfMaps(remoteJson['taskTombstones']),
    );
    final List<Map<String, dynamic>> subtaskTombstones = _mergeTombstones(
      _asListOfMaps(localJson['subtaskTombstones']),
      _asListOfMaps(remoteJson['subtaskTombstones']),
    );
    final List<Map<String, dynamic>> journalTombstones = _mergeTombstones(
      _asListOfMaps(localJson['journalTombstones']),
      _asListOfMaps(remoteJson['journalTombstones']),
    );
    final List<Map<String, dynamic>> watchTombstones = _mergeTombstones(
      _asListOfMaps(localJson['watchTombstones']),
      _asListOfMaps(remoteJson['watchTombstones']),
    );
    final List<Map<String, dynamic>> groceryTombstones = _mergeTombstones(
      _asListOfMaps(localJson['groceryTombstones']),
      _asListOfMaps(remoteJson['groceryTombstones']),
    );
    final List<Map<String, dynamic>> categoryTombstones = _mergeTombstones(
      _asListOfMaps(localJson['categoryTombstones']),
      _asListOfMaps(remoteJson['categoryTombstones']),
    );

    final Map<String, dynamic> merged = {
      'schemaVersion': 2,
      'deviceId': localJson['deviceId'] ?? remoteJson['deviceId'] ?? '',
      'lastModified': DateTime.now().toUtc().toIso8601String(),
      'categories': _mergeCategories(
        _asList(localJson['categories']),
        _asList(remoteJson['categories']),
        categoryTombstones,
      ),
      'tasks': _mergeTasks(
        _asListOfMaps(localJson['tasks']),
        _asListOfMaps(remoteJson['tasks']),
        taskTombstones,
        subtaskTombstones,
      ),
      'journalEntries': _removeExactDuplicates(
        _mergeItemsById(
          _asListOfMaps(localJson['journalEntries']),
          _asListOfMaps(remoteJson['journalEntries']),
          journalTombstones,
        ),
        _journalExactKey,
      ),
      'watchItems': _removeExactDuplicates(
        _mergeItemsById(
          _asListOfMaps(localJson['watchItems']),
          _asListOfMaps(remoteJson['watchItems']),
          watchTombstones,
        ),
        _watchExactKey,
      ),
      'groceryItems': _removeExactDuplicates(
        _mergeItemsById(
          _asListOfMaps(localJson['groceryItems']),
          _asListOfMaps(remoteJson['groceryItems']),
          groceryTombstones,
        ),
        _groceryExactKey,
      ),
      'taskTombstones': taskTombstones,
      'subtaskTombstones': subtaskTombstones,
      'journalTombstones': journalTombstones,
      'watchTombstones': watchTombstones,
      'groceryTombstones': groceryTombstones,
      'categoryTombstones': categoryTombstones,
    };

    return AppData.fromJson(merged)
        .copyWith(lastModified: DateTime.now().toUtc())
        .pruneOldTombstones();
  }

  List<String> _mergeCategories(
    List<dynamic> localCategories,
    List<dynamic> remoteCategories,
    List<Map<String, dynamic>> categoryTombstones,
  ) {
    final Set<String> deleted = categoryTombstones
        .map((item) => _normalizedString(item['id']))
        .where((item) => item.isNotEmpty)
        .toSet();

    final Set<String> seen = {};
    final List<String> output = [];

    void add(dynamic value) {
      final String category = value.toString().trim();
      if (category.isEmpty || category == 'My Tasks') {
        return;
      }

      if (category == AppData.defaultCategory) {
        return;
      }

      final String key = category.toLowerCase();
      if (deleted.contains(key)) {
        return;
      }

      if (seen.add(key)) {
        output.add(category);
      }
    }

    for (final dynamic value in remoteCategories) {
      add(value);
    }

    for (final dynamic value in localCategories) {
      add(value);
    }

    output.sort();
    return [AppData.defaultCategory, ...output];
  }

  List<Map<String, dynamic>> _mergeTasks(
    List<Map<String, dynamic>> localTasks,
    List<Map<String, dynamic>> remoteTasks,
    List<Map<String, dynamic>> taskTombstones,
    List<Map<String, dynamic>> subtaskTombstones,
  ) {
    final Map<String, Map<String, dynamic>> localById = _itemsById(localTasks);
    final Map<String, Map<String, dynamic>> remoteById = _itemsById(remoteTasks);
    final Set<String> ids = {...localById.keys, ...remoteById.keys};
    final List<Map<String, dynamic>> output = [];

    for (final String id in ids) {
      final Map<String, dynamic>? localItem = localById[id];
      final Map<String, dynamic>? remoteItem = remoteById[id];
      final Map<String, dynamic>? tombstone = _latestTombstoneForId(
        id,
        taskTombstones,
      );
      final Map<String, dynamic>? newestItem = _newestItem(localItem, remoteItem);

      if (newestItem == null) {
        continue;
      }

      if (tombstone != null &&
          !_itemUpdatedAt(newestItem).isAfter(_tombstoneDeletedAt(tombstone))) {
        continue;
      }

      final Map<String, dynamic> mergedTask = Map<String, dynamic>.from(newestItem);
      mergedTask['subtasks'] = _mergeItemsById(
        _asListOfMaps(localItem?['subtasks']),
        _asListOfMaps(remoteItem?['subtasks']),
        subtaskTombstones,
      );
      output.add(mergedTask);
    }

    output.sort(_compareByUpdatedAtOrCreatedAtDescending);
    return output;
  }

  List<Map<String, dynamic>> _mergeItemsById(
    List<Map<String, dynamic>> localItems,
    List<Map<String, dynamic>> remoteItems,
    List<Map<String, dynamic>> tombstones,
  ) {
    final Map<String, Map<String, dynamic>> localById = _itemsById(localItems);
    final Map<String, Map<String, dynamic>> remoteById = _itemsById(remoteItems);
    final Set<String> ids = {...localById.keys, ...remoteById.keys};
    final List<Map<String, dynamic>> output = [];

    for (final String id in ids) {
      final Map<String, dynamic>? newestItem = _newestItem(
        localById[id],
        remoteById[id],
      );
      final Map<String, dynamic>? tombstone = _latestTombstoneForId(
        id,
        tombstones,
      );

      if (newestItem == null) {
        continue;
      }

      if (tombstone != null &&
          !_itemUpdatedAt(newestItem).isAfter(_tombstoneDeletedAt(tombstone))) {
        continue;
      }

      output.add(Map<String, dynamic>.from(newestItem));
    }

    output.sort(_compareByUpdatedAtOrCreatedAtDescending);
    return output;
  }

  List<Map<String, dynamic>> _mergeTombstones(
    List<Map<String, dynamic>> localTombstones,
    List<Map<String, dynamic>> remoteTombstones,
  ) {
    final DateTime cutoff = DateTime.now().toUtc().subtract(
          const Duration(days: 365),
        );
    final Map<String, Map<String, dynamic>> byId = {};

    void add(Map<String, dynamic> tombstone) {
      final String id = tombstone['id']?.toString().trim() ?? '';
      if (id.isEmpty) {
        return;
      }

      if (!_tombstoneDeletedAt(tombstone).isAfter(cutoff)) {
        return;
      }

      final Map<String, dynamic>? existing = byId[id];
      if (existing == null ||
          _tombstoneDeletedAt(tombstone).isAfter(_tombstoneDeletedAt(existing))) {
        byId[id] = Map<String, dynamic>.from(tombstone);
      }
    }

    for (final Map<String, dynamic> tombstone in remoteTombstones) {
      add(tombstone);
    }

    for (final Map<String, dynamic> tombstone in localTombstones) {
      add(tombstone);
    }

    final List<Map<String, dynamic>> output = byId.values.toList();
    output.sort((a, b) => _tombstoneDeletedAt(b).compareTo(_tombstoneDeletedAt(a)));
    return output;
  }

  List<Map<String, dynamic>> _removeExactDuplicates(
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic> item) keyBuilder,
  ) {
    final Map<String, Map<String, dynamic>> byKey = {};

    for (final Map<String, dynamic> item in items) {
      final String key = keyBuilder(item);
      final Map<String, dynamic>? existing = byKey[key];

      if (existing == null || _itemUpdatedAt(item).isAfter(_itemUpdatedAt(existing))) {
        byKey[key] = item;
      }
    }

    final List<Map<String, dynamic>> output = byKey.values.toList();
    output.sort(_compareByUpdatedAtOrCreatedAtDescending);
    return output;
  }

  Map<String, Map<String, dynamic>> _itemsById(List<Map<String, dynamic>> items) {
    final Map<String, Map<String, dynamic>> byId = {};

    for (final Map<String, dynamic> item in items) {
      final String id = item['id']?.toString().trim() ?? '';
      if (id.isEmpty) {
        continue;
      }

      final Map<String, dynamic>? existing = byId[id];
      if (existing == null || _itemUpdatedAt(item).isAfter(_itemUpdatedAt(existing))) {
        byId[id] = Map<String, dynamic>.from(item);
      }
    }

    return byId;
  }

  Map<String, dynamic>? _newestItem(
    Map<String, dynamic>? localItem,
    Map<String, dynamic>? remoteItem,
  ) {
    if (localItem == null) {
      return remoteItem == null ? null : Map<String, dynamic>.from(remoteItem);
    }

    if (remoteItem == null) {
      return Map<String, dynamic>.from(localItem);
    }

    if (_itemUpdatedAt(localItem).isAfter(_itemUpdatedAt(remoteItem))) {
      return Map<String, dynamic>.from(localItem);
    }

    return Map<String, dynamic>.from(remoteItem);
  }

  Map<String, dynamic>? _latestTombstoneForId(
    String id,
    List<Map<String, dynamic>> tombstones,
  ) {
    Map<String, dynamic>? newest;

    for (final Map<String, dynamic> tombstone in tombstones) {
      if (tombstone['id']?.toString() != id) {
        continue;
      }

      if (newest == null ||
          _tombstoneDeletedAt(tombstone).isAfter(_tombstoneDeletedAt(newest))) {
        newest = tombstone;
      }
    }

    return newest;
  }

  String _journalExactKey(Map<String, dynamic> item) {
    return [
      _normalizedString(item['title']),
      _normalizedString(item['body']),
      _normalizedString(item['createdAt']),
    ].join('|');
  }

  String _watchExactKey(Map<String, dynamic> item) {
    return [
      _normalizedString(item['title']),
      _normalizedString(item['type']),
      _normalizedString(item['status']),
      _normalizedString(item['season']),
      _normalizedString(item['episode']),
      _normalizedString(item['notes']),
    ].join('|');
  }

  String _groceryExactKey(Map<String, dynamic> item) {
    return [
      _normalizedString(item['title']),
      _normalizedString(item['description']),
      _normalizedString(item['section']),
      _normalizedString(item['autoAddToNext']),
    ].join('|');
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

  DateTime _tombstoneDeletedAt(Map<String, dynamic> tombstone) {
    return _parseDateTime(tombstone['deletedAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
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
