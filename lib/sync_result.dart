import 'app_data.dart';

enum SyncStatus {
  success,
  failed,
  localNewerUploaded,
  remoteNewerDownloaded,
  merged,
  noRemoteCreated,
  noChanges,
  conflict,
}

class SyncResult {
  final bool success;
  final SyncStatus status;
  final String message;
  final AppData? syncedData;

  const SyncResult({
    required this.success,
    required this.status,
    required this.message,
    this.syncedData,
  });

  factory SyncResult.success({
    required SyncStatus status,
    required String message,
    AppData? syncedData,
  }) {
    return SyncResult(
      success: true,
      status: status,
      message: message,
      syncedData: syncedData,
    );
  }

  factory SyncResult.failed(String message) {
    return SyncResult(
      success: false,
      status: SyncStatus.failed,
      message: message,
    );
  }
}
