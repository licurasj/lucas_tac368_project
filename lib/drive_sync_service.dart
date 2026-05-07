import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'app_data.dart';
import 'grocery_item.dart';
import 'journal_entry.dart';
import 'sync_result.dart';
import 'task_item.dart';
import 'watch_item.dart';

class DriveSyncService {
  static const String _fileName = 'hybrid_note_app_data.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // clientId: '377269928861-0u5fenqlrrdmhue0vf7g0cq148npl1gh.apps.googleusercontent.com',
    scopes: [
      drive.DriveApi.driveAppdataScope,
    ],
  );

  http.Client? _authClient;

  Future<SyncResult> sync({
    required AppData localData,
  }) async {
    try {
      final drive.DriveApi? driveApi = await _getDriveApi();

      if (driveApi == null) {
        return SyncResult.failed(
          'Google sign-in was cancelled. Local data is still saved.',
        );
      }

      final String? remoteFileId = await _findRemoteFileId(driveApi);

      if (remoteFileId == null) {
        await _createRemoteFile(
          driveApi: driveApi,
          data: localData,
        );

        return SyncResult.success(
          status: SyncStatus.noRemoteCreated,
          message: 'Created Google Drive sync file. Local data uploaded.',
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
          message: 'Remote file was unreadable, so local data was uploaded.',
          syncedData: localData,
        );
      }

      final AppData mergedData = _mergeAppData(
        localData: localData,
        remoteData: remoteData,
      );

      final bool localWasNewer =
          localData.lastModified.isAfter(remoteData.lastModified);
      final bool remoteWasNewer =
          remoteData.lastModified.isAfter(localData.lastModified);

      await _updateRemoteFile(
        driveApi: driveApi,
        fileId: remoteFileId,
        data: mergedData,
      );

      if (_sameInstant(localData.lastModified, remoteData.lastModified)) {
        return SyncResult.success(
          status: SyncStatus.noChanges,
          message: 'Sync complete. No major changes found.',
          syncedData: mergedData,
        );
      }

      if (localWasNewer && !_dataCountsChanged(localData, mergedData)) {
        return SyncResult.success(
          status: SyncStatus.localNewerUploaded,
          message: 'Local changes uploaded to Google Drive.',
          syncedData: mergedData,
        );
      }

      if (remoteWasNewer && !_dataCountsChanged(remoteData, mergedData)) {
        return SyncResult.success(
          status: SyncStatus.remoteNewerDownloaded,
          message: 'Newer Google Drive data downloaded.',
          syncedData: mergedData,
        );
      }

      return SyncResult.success(
        status: SyncStatus.merged,
        message: 'Sync complete. Local and remote changes were merged.',
        syncedData: mergedData,
      );
    } catch (error) {
      return SyncResult.failed(
        'Google Drive sync failed. Local data is still saved. $error',
      );
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _authClient?.close();
    _authClient = null;
  }

  Future<bool> signIn() async {
    final drive.DriveApi? api = await _getDriveApi();
    return api != null;
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
        print('Google Drive: On macOS, this often means the OAuth redirect did not return to the app.');
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

    final drive.Media media = drive.Media(
      Stream<List<int>>.value(utf8.encode(encodedData)),
      utf8.encode(encodedData).length,
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

    final drive.Media media = drive.Media(
      Stream<List<int>>.value(utf8.encode(encodedData)),
      utf8.encode(encodedData).length,
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

  bool _sameInstant(DateTime a, DateTime b) {
    return a.toUtc().toIso8601String() == b.toUtc().toIso8601String();
  }

  bool _dataCountsChanged(AppData oldData, AppData newData) {
    return oldData.tasks.length != newData.tasks.length ||
        oldData.journalEntries.length != newData.journalEntries.length ||
        oldData.watchItems.length != newData.watchItems.length ||
        oldData.groceryItems.length != newData.groceryItems.length ||
        oldData.categories.length != newData.categories.length;
  }

  AppData _mergeAppData({
    required AppData localData,
    required AppData remoteData,
  }) {
    final DateTime now = DateTime.now().toUtc();

    return AppData(
      schemaVersion: localData.schemaVersion > remoteData.schemaVersion
          ? localData.schemaVersion
          : remoteData.schemaVersion,
      deviceId: localData.deviceId,
      lastModified: now,
      categories: _mergeCategories(
        localData.categories,
        remoteData.categories,
      ),
      tasks: _mergeByUpdatedAt<TaskItem>(
        localData.tasks,
        remoteData.tasks,
        getId: (task) => task.id,
        getUpdatedAt: (task) => task.updatedAt,
      ),
      journalEntries: _mergeByUpdatedAt<JournalEntry>(
        localData.journalEntries,
        remoteData.journalEntries,
        getId: (entry) => entry.id,
        getUpdatedAt: (entry) => entry.updatedAt,
      ),
      watchItems: _mergeByUpdatedAt<WatchItem>(
        localData.watchItems,
        remoteData.watchItems,
        getId: (item) => item.id,
        getUpdatedAt: (item) => item.updatedAt,
      ),
      groceryItems: _mergeByUpdatedAt<GroceryItem>(
        localData.groceryItems,
        remoteData.groceryItems,
        getId: (item) => item.id,
        getUpdatedAt: (item) => item.updatedAt,
      ),
    );
  }

  List<String> _mergeCategories(
    List<String> localCategories,
    List<String> remoteCategories,
  ) {
    final Set<String> mergedSet = {
      AppData.defaultCategory,
      ...localCategories,
      ...remoteCategories,
    };

    mergedSet.remove('My Tasks');

    final List<String> merged = mergedSet
        .where((category) => category.trim().isNotEmpty)
        .toList();

    merged.sort((a, b) {
      if (a == AppData.defaultCategory) {
        return -1;
      }

      if (b == AppData.defaultCategory) {
        return 1;
      }

      return a.compareTo(b);
    });

    return merged;
  }

  List<T> _mergeByUpdatedAt<T>(
    List<T> localItems,
    List<T> remoteItems, {
    required String Function(T item) getId,
    required DateTime Function(T item) getUpdatedAt,
  }) {
    final Map<String, T> merged = {};

    for (final T item in remoteItems) {
      merged[getId(item)] = item;
    }

    for (final T localItem in localItems) {
      final String id = getId(localItem);
      final T? remoteItem = merged[id];

      if (remoteItem == null) {
        merged[id] = localItem;
        continue;
      }

      if (getUpdatedAt(localItem).isAfter(getUpdatedAt(remoteItem))) {
        merged[id] = localItem;
      }
    }

    final List<T> output = merged.values.toList();

    output.sort((a, b) {
      return getUpdatedAt(b).compareTo(getUpdatedAt(a));
    });

    return output;
  }
}
