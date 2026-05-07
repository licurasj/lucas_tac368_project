import 'app_data.dart';

class AppState {
  final AppData data;
  final bool isLoading;
  final bool isSyncing;
  final bool isGoogleSignedIn;
  final String? errorMessage;
  final String? syncMessage;
  final DateTime? lastSyncedAt;

  const AppState({
    required this.data,
    required this.isLoading,
    required this.isSyncing,
    required this.isGoogleSignedIn,
    this.errorMessage,
    this.syncMessage,
    this.lastSyncedAt,
  });

  factory AppState.initial(String deviceId) {
    return AppState(
      data: AppData.empty(deviceId),
      isLoading: true,
      isSyncing: false,
      isGoogleSignedIn: false,
    );
  }

  AppState copyWith({
    AppData? data,
    bool? isLoading,
    bool? isSyncing,
    bool? isGoogleSignedIn,
    String? errorMessage,
    String? syncMessage,
    DateTime? lastSyncedAt,
    bool clearError = false,
    bool clearSyncMessage = false,
  }) {
    return AppState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      isGoogleSignedIn: isGoogleSignedIn ?? this.isGoogleSignedIn,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      syncMessage: clearSyncMessage ? null : syncMessage ?? this.syncMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  int get pendingTaskCount {
    return data.tasks.where((task) => !task.isCompleted).length;
  }

  int get completedTaskCount {
    return data.tasks.where((task) => task.isCompleted).length;
  }

  int get watchingCount {
    return data.watchItems
        .where((item) => item.status.name == 'watching')
        .length;
  }
}
