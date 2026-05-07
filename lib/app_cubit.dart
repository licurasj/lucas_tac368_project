import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'app_data.dart';
import 'app_state.dart';
import 'app_storage.dart';
import 'drive_sync_service.dart';
import 'grocery_item.dart';
import 'journal_entry.dart';
import 'sync_result.dart';
import 'task_item.dart';
import 'watch_item.dart';

class AppCubit extends Cubit<AppState> {
  final AppStorage storage;
  final DriveSyncService driveSyncService;

  bool _isAutoSyncing = false;
  bool _needsAnotherAutoSync = false;
  int _localChangeVersion = 0;

  AppCubit({
    required this.storage,
    required this.driveSyncService,
    required String deviceId,
  }) : super(AppState.initial(deviceId));


  Future<void> setPreferredLocaleCode(String? localeCode) async {
    await storage.savePreferredLocaleCode(localeCode);

    emit(
      state.copyWith(
        selectedLocaleCode: localeCode,
        clearSelectedLocale: localeCode == null,
      ),
    );
  }

  void _clearSyncMessageSoon(
    String message, {
    Duration delay = const Duration(milliseconds: 900),
  }) {
    Future<void>.delayed(delay, () {
      if (isClosed) {
        return;
      }

      if (state.syncMessage == message && !state.isSyncing) {
        emit(
          state.copyWith(
            clearSyncMessage: true,
          ),
        );
      }
    });
  }


  Future<void> toggleDarkMode() async {
    final bool nextMode = !state.isDarkMode;

    emit(
      state.copyWith(
        isDarkMode: nextMode,
      ),
    );

    await _updateAndSave(
      state.data.copyWith(
        isDarkMode: nextMode,
      ),
    );
  }

  Future<void> loadData() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSyncMessage: true,
      ),
    );

    try {
      final AppData loadedData = await storage.loadAppData();
      final String? preferredLocaleCode = await storage.loadPreferredLocaleCode();

      emit(
        state.copyWith(
          data: loadedData,
          isDarkMode: loadedData.isDarkMode,
          isLoading: false,
          isGoogleSignedIn: driveSyncService.isSignedIn,
          selectedLocaleCode: preferredLocaleCode,
          clearSelectedLocale: preferredLocaleCode == null,
          clearError: true,
        ),
      );

      final bool restoredSignIn =
          driveSyncService.isSignedIn ||
          await driveSyncService.tryRestorePreviousSignIn();

      if (!restoredSignIn) {
        emit(
          state.copyWith(
            isGoogleSignedIn: false,
          ),
        );
        return;
      }

      final int syncStartVersion = _localChangeVersion;

      emit(
        state.copyWith(
          isGoogleSignedIn: true,
          isSyncing: true,
          clearSyncMessage: true,
          clearError: true,
        ),
      );

      final SyncResult result = await driveSyncService.sync(
        localData: loadedData,
      );

      if (syncStartVersion != _localChangeVersion) {
        // The user changed local data while startup sync was running.
        // Do not apply an older cloud result over the user's newer edit.
        emit(
          state.copyWith(
            isSyncing: false,
            isGoogleSignedIn: driveSyncService.isSignedIn,
            clearSyncMessage: true,
          ),
        );
        await _autoPushLocalChange();
        return;
      }

      if (result.success && result.syncedData != null) {
        await _saveData(result.syncedData!);

        emit(
          state.copyWith(
            data: result.syncedData!,
            isDarkMode: result.syncedData!.isDarkMode,
            isSyncing: false,
            isGoogleSignedIn: driveSyncService.isSignedIn,
            lastSyncedAt: DateTime.now().toUtc(),
            clearSyncMessage: true,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isSyncing: false,
            isGoogleSignedIn: driveSyncService.isSignedIn,
            syncMessage: result.message,
          ),
        );
        _clearSyncMessageSoon(result.message);
      }
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          isSyncing: false,
          errorMessage: 'Could not load local data.',
        ),
      );
    }
  }

  Future<void> _saveData(AppData data) async {
    await storage.saveAppData(data);
  }


  SyncTombstone _makeTombstone(String id, DateTime now) {
    return SyncTombstone(
      id: id,
      deletedAt: now.toUtc(),
      deviceId: state.data.deviceId,
    );
  }

  List<SyncTombstone> _upsertTombstone(
    List<SyncTombstone> tombstones,
    SyncTombstone newTombstone,
  ) {
    final List<SyncTombstone> output = tombstones
        .where((tombstone) => tombstone.id != newTombstone.id)
        .toList();
    output.add(newTombstone);
    output.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return output;
  }

  List<SyncTombstone> _removeTombstone(
    List<SyncTombstone> tombstones,
    String id,
  ) {
    return tombstones.where((tombstone) => tombstone.id != id).toList();
  }

  String _categoryTombstoneId(String categoryName) {
    return categoryName.trim().toLowerCase();
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  DateTime _clampDateTime({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required int second,
    required int millisecond,
    required int microsecond,
  }) {
    final int maxDay = _daysInMonth(year, month);
    final int clampedDay = day > maxDay ? maxDay : day;

    return DateTime(
      year,
      month,
      clampedDay,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  DateTime? _advanceReminderOnce(TaskItem task, DateTime localReminder) {
    switch (task.repeatFrequency) {
      case RepeatFrequency.none:
        return null;
      case RepeatFrequency.daily:
        return localReminder.add(const Duration(days: 1));
      case RepeatFrequency.weekly:
        return localReminder.add(const Duration(days: 7));
      case RepeatFrequency.monthly:
        return _clampDateTime(
          year: localReminder.year,
          month: localReminder.month + 1,
          day: localReminder.day,
          hour: localReminder.hour,
          minute: localReminder.minute,
          second: localReminder.second,
          millisecond: localReminder.millisecond,
          microsecond: localReminder.microsecond,
        );
      case RepeatFrequency.yearly:
        return _clampDateTime(
          year: localReminder.year + 1,
          month: localReminder.month,
          day: localReminder.day,
          hour: localReminder.hour,
          minute: localReminder.minute,
          second: localReminder.second,
          millisecond: localReminder.millisecond,
          microsecond: localReminder.microsecond,
        );
      case RepeatFrequency.custom:
        final int? customDays = task.customRepeatDays;

        if (customDays == null || customDays <= 0) {
          return null;
        }

        return localReminder.add(Duration(days: customDays));
    }
  }

  DateTime? _nextReminderForTask(TaskItem task, DateTime now) {
    if (task.reminderAt == null || task.repeatFrequency == RepeatFrequency.none) {
      return null;
    }

    DateTime? nextLocalReminder = _advanceReminderOnce(
      task,
      task.reminderAt!.toLocal(),
    );

    // If the completed reminder is old, keep advancing by the same repeat gap
    // until the next generated instance is actually in the future.
    int safetyCounter = 0;
    while (nextLocalReminder != null &&
        !nextLocalReminder.toUtc().isAfter(now) &&
        safetyCounter < 1000) {
      nextLocalReminder = _advanceReminderOnce(task, nextLocalReminder);
      safetyCounter++;
    }

    return nextLocalReminder?.toUtc();
  }

  List<SubtaskItem> _copySubtasksForRepeatedTask(
    List<SubtaskItem> subtasks,
    DateTime now,
    String newTaskId,
  ) {
    return subtasks.map((subtask) {
      return SubtaskItem(
        id: '$newTaskId-subtask-${subtask.id}',
        title: subtask.title,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }

  TaskItem? _makeNextRepeatedTask(TaskItem completedTask, DateTime now) {
    final DateTime? nextReminder = _nextReminderForTask(completedTask, now);

    if (nextReminder == null) {
      return null;
    }

    final String nextTaskId =
        'repeat-${completedTask.id}-${nextReminder.millisecondsSinceEpoch}';

    return TaskItem(
      id: nextTaskId,
      title: completedTask.title,
      description: completedTask.description,
      isCompleted: false,
      category: completedTask.category,
      subtasks: _copySubtasksForRepeatedTask(
        completedTask.subtasks,
        now,
        nextTaskId,
      ),
      reminderAt: nextReminder,
      repeatFrequency: completedTask.repeatFrequency,
      customRepeatDays: completedTask.customRepeatDays,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _updateAndSave(AppData data) async {
    final AppData updatedData = data
        .copyWith(
          lastModified: DateTime.now().toUtc(),
        )
        .pruneOldTombstones();

    _localChangeVersion++;

    emit(
      state.copyWith(
        data: updatedData,
        isDarkMode: updatedData.isDarkMode,
        clearError: true,
      ),
    );

    try {
      await _saveData(updatedData);
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'Could not save local data.',
        ),
      );
      return;
    }

    await _autoPushLocalChange();
  }

  Future<void> _autoPushLocalChange() async {
    if (!driveSyncService.isSignedIn) {
      return;
    }

    if (_isAutoSyncing) {
      _needsAnotherAutoSync = true;
      return;
    }

    _isAutoSyncing = true;

    emit(
      state.copyWith(
        isSyncing: true,
        isGoogleSignedIn: true,
        clearSyncMessage: true,
        clearError: true,
      ),
    );

    String? failureMessage;

    do {
      _needsAnotherAutoSync = false;

      final int uploadVersion = _localChangeVersion;
      final AppData uploadSnapshot = state.data;

      final SyncResult result = await driveSyncService.pushLocalToDrive(
        localData: uploadSnapshot,
      );

      if (result.success) {
        if (uploadVersion == _localChangeVersion) {
          final AppData syncedData = result.syncedData ?? uploadSnapshot;
          await _saveData(syncedData);

          emit(
            state.copyWith(
              data: syncedData,
              isDarkMode: syncedData.isDarkMode,
              isGoogleSignedIn: true,
              lastSyncedAt: DateTime.now().toUtc(),
              clearError: true,
            ),
          );
        } else {
          _needsAnotherAutoSync = true;
        }
      } else {
        failureMessage = result.message;
        emit(
          state.copyWith(
            isGoogleSignedIn: driveSyncService.isSignedIn,
            syncMessage: result.message,
          ),
        );
      }
    } while (_needsAnotherAutoSync);

    _isAutoSyncing = false;

    if (failureMessage == null) {
      emit(
        state.copyWith(
          isSyncing: false,
          isGoogleSignedIn: driveSyncService.isSignedIn,
          clearSyncMessage: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isSyncing: false,
          isGoogleSignedIn: driveSyncService.isSignedIn,
          syncMessage: failureMessage,
        ),
      );
      _clearSyncMessageSoon(failureMessage);
    }
  }

  Future<void> signInToGoogle() async {
    if (driveSyncService.isSignedIn || state.isGoogleSignedIn) {
      await signOutOfGoogle();
      return;
    }

    emit(
      state.copyWith(
        isSyncing: true,
        clearSyncMessage: true,
        clearError: true,
      ),
    );

    final bool signedIn = await driveSyncService.signIn();

    if (!signedIn) {
      const String message = 'Google sign-in failed or was cancelled.';

      emit(
        state.copyWith(
          isSyncing: false,
          isGoogleSignedIn: false,
          syncMessage: message,
        ),
      );
      _clearSyncMessageSoon(message);
      return;
    }

    const String message = 'Signed in.';

    emit(
      state.copyWith(
        isSyncing: false,
        isGoogleSignedIn: true,
        syncMessage: message,
        clearError: true,
      ),
    );

    _clearSyncMessageSoon(message);

    await syncWithDrive();
  }

  Future<void> signOutOfGoogle() async {
    await driveSyncService.signOut();

    const String message = 'Signed out.';

    emit(
      state.copyWith(
        isGoogleSignedIn: false,
        isSyncing: false,
        syncMessage: message,
        clearError: true,
      ),
    );
    _clearSyncMessageSoon(message);
  }

  Future<void> syncWithDrive() async {
    final int syncStartVersion = _localChangeVersion;
    final AppData syncSnapshot = state.data;

    emit(
      state.copyWith(
        isSyncing: true,
        clearSyncMessage: true,
        clearError: true,
      ),
    );

    final SyncResult result = await driveSyncService.sync(localData: syncSnapshot);

    if (syncStartVersion != _localChangeVersion) {
      // A local edit happened while manual sync was running.
      // Do not apply remote data over that edit; push the newest local state instead.
      emit(
        state.copyWith(
          isSyncing: false,
          isGoogleSignedIn: driveSyncService.isSignedIn,
          clearSyncMessage: true,
        ),
      );
      await _autoPushLocalChange();
      return;
    }

    if (result.success && result.syncedData != null) {
      await _saveData(result.syncedData!);

      const String message = 'Sync complete.';

      emit(
        state.copyWith(
          data: result.syncedData!,
          isDarkMode: result.syncedData!.isDarkMode,
          isSyncing: false,
          isGoogleSignedIn: driveSyncService.isSignedIn,
          syncMessage: message,
          lastSyncedAt: DateTime.now().toUtc(),
          clearError: true,
        ),
      );
      _clearSyncMessageSoon(message);
    } else {
      emit(
        state.copyWith(
          isSyncing: false,
          isGoogleSignedIn: driveSyncService.isSignedIn,
          syncMessage: result.message,
        ),
      );
      _clearSyncMessageSoon(result.message);
    }
  }

  Future<void> addCategory(String categoryName) async {
    final String cleanedName = categoryName.trim();

    if (cleanedName.isEmpty) {
      emit(state.copyWith(errorMessage: 'Category name cannot be empty.'));
      return;
    }

    if (cleanedName == AppData.defaultCategory || cleanedName == 'My Tasks') {
      emit(
        state.copyWith(
          errorMessage: 'That category name is reserved.',
        ),
      );
      return;
    }

    final bool alreadyExists = state.data.categories.any(
      (category) => category.toLowerCase() == cleanedName.toLowerCase(),
    );

    if (alreadyExists) {
      emit(state.copyWith(errorMessage: 'That category already exists.'));
      return;
    }

    final List<String> updatedCategories = [
      ...state.data.categories,
      cleanedName,
    ]..sort((a, b) {
        if (a == AppData.defaultCategory) {
          return -1;
        }

        if (b == AppData.defaultCategory) {
          return 1;
        }

        return a.compareTo(b);
      });

    await _updateAndSave(
      state.data.copyWith(
        categories: updatedCategories,
        categoryTombstones: _removeTombstone(
          state.data.categoryTombstones,
          _categoryTombstoneId(cleanedName),
        ),
      ),
    );
  }

  Future<void> deleteCategory(String categoryName) async {
    if (categoryName == AppData.defaultCategory) {
      emit(
        state.copyWith(
          errorMessage: 'All My Tasks cannot be deleted.',
        ),
      );
      return;
    }

    final bool categoryHasTasks = state.data.tasks.any(
      (task) => task.category == categoryName,
    );

    if (categoryHasTasks) {
      emit(
        state.copyWith(
          errorMessage: 'Delete or move tasks in this category first.',
        ),
      );
      return;
    }

    final DateTime now = DateTime.now().toUtc();
    final List<String> updatedCategories = state.data.categories
        .where((category) => category != categoryName)
        .toList();

    await _updateAndSave(
      state.data.copyWith(
        categories: updatedCategories,
        categoryTombstones: _upsertTombstone(
          state.data.categoryTombstones,
          _makeTombstone(_categoryTombstoneId(categoryName), now),
        ),
      ),
    );
  }

  String _cleanTaskCategory(String category) {
    final String cleanedCategory = category.trim();

    if (cleanedCategory.isEmpty || cleanedCategory == AppData.defaultCategory) {
      return '';
    }

    return cleanedCategory;
  }

  bool _categoryIsAllowed(String category) {
    if (category.isEmpty) {
      return true;
    }

    return state.data.categories.contains(category);
  }

  Future<void> addTask({
    required String title,
    required String description,
    required String category,
    required DateTime? reminderAt,
    required RepeatFrequency repeatFrequency,
    required int? customRepeatDays,
  }) async {
    if (title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Task title cannot be empty.'));
      return;
    }

    final String finalCategory = _cleanTaskCategory(category);

    if (!_categoryIsAllowed(finalCategory)) {
      emit(
        state.copyWith(
          errorMessage: 'Selected category does not exist.',
        ),
      );
      return;
    }

    if (repeatFrequency == RepeatFrequency.custom &&
        (customRepeatDays == null || customRepeatDays <= 0)) {
      emit(
        state.copyWith(
          errorMessage: 'Custom repeat must be at least 1 day.',
        ),
      );
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    final TaskItem task = TaskItem(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description.trim(),
      isCompleted: false,
      category: finalCategory,
      subtasks: const [],
      reminderAt: reminderAt?.toUtc(),
      repeatFrequency: reminderAt == null ? RepeatFrequency.none : repeatFrequency,
      customRepeatDays:
          repeatFrequency == RepeatFrequency.custom ? customRepeatDays : null,
      createdAt: now,
      updatedAt: now,
    );

    final List<TaskItem> updatedTasks = [...state.data.tasks, task];

    await _updateAndSave(
      state.data.copyWith(tasks: updatedTasks),
    );
  }

  Future<void> editTask({
    required String taskId,
    required String title,
    required String description,
    required String category,
    required DateTime? reminderAt,
    required RepeatFrequency repeatFrequency,
    required int? customRepeatDays,
  }) async {
    if (title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Task title cannot be empty.'));
      return;
    }

    final String finalCategory = _cleanTaskCategory(category);

    if (!_categoryIsAllowed(finalCategory)) {
      emit(
        state.copyWith(
          errorMessage: 'Selected category does not exist.',
        ),
      );
      return;
    }

    if (repeatFrequency == RepeatFrequency.custom &&
        (customRepeatDays == null || customRepeatDays <= 0)) {
      emit(
        state.copyWith(
          errorMessage: 'Custom repeat must be at least 1 day.',
        ),
      );
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    final List<TaskItem> updatedTasks = state.data.tasks.map((task) {
      if (task.id != taskId) {
        return task;
      }

      return task.copyWith(
        title: title.trim(),
        description: description.trim(),
        category: finalCategory,
        reminderAt: reminderAt?.toUtc(),
        repeatFrequency: reminderAt == null ? RepeatFrequency.none : repeatFrequency,
        customRepeatDays:
            repeatFrequency == RepeatFrequency.custom ? customRepeatDays : null,
        clearReminder: reminderAt == null,
        clearCustomRepeatDays: repeatFrequency != RepeatFrequency.custom,
        updatedAt: now,
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(tasks: updatedTasks),
    );
  }

  Future<void> toggleTaskComplete(String taskId) async {
    final List<TaskItem> updatedTasks = state.data.tasks.map((task) {
      if (task.id != taskId) {
        return task;
      }

      return task.copyWith(
        isCompleted: !task.isCompleted,
        updatedAt: DateTime.now().toUtc(),
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(tasks: updatedTasks),
    );
  }

  Future<void> deleteTask(String taskId) async {
    final DateTime now = DateTime.now().toUtc();
    final List<TaskItem> updatedTasks =
        state.data.tasks.where((task) => task.id != taskId).toList();

    await _updateAndSave(
      state.data.copyWith(
        tasks: updatedTasks,
        taskTombstones: _upsertTombstone(
          state.data.taskTombstones,
          _makeTombstone(taskId, now),
        ),
      ),
    );
  }

  Future<void> clearCompletedTask(String taskId) async {
    TaskItem? completedTask;

    for (final TaskItem task in state.data.tasks) {
      if (task.id == taskId) {
        completedTask = task;
        break;
      }
    }

    if (completedTask == null) {
      return;
    }

    if (!completedTask.isCompleted) {
      emit(
        state.copyWith(
          errorMessage: 'Only completed tasks can be cleared.',
        ),
      );
      return;
    }

    final DateTime now = DateTime.now().toUtc();
    final TaskItem? nextRepeatedTask = _makeNextRepeatedTask(completedTask, now);

    final List<TaskItem> updatedTasks = state.data.tasks
        .where((task) => task.id != taskId)
        .toList();

    if (nextRepeatedTask != null) {
      final bool alreadyHasNextTask = updatedTasks.any(
        (task) => task.id == nextRepeatedTask.id,
      );

      if (!alreadyHasNextTask) {
        updatedTasks.add(nextRepeatedTask);
      }
    }

    await _updateAndSave(
      state.data.copyWith(
        tasks: updatedTasks,
        taskTombstones: _upsertTombstone(
          state.data.taskTombstones,
          _makeTombstone(taskId, now),
        ),
      ),
    );
  }

  Future<void> clearCompletedTasks(String category) async {
    final DateTime now = DateTime.now().toUtc();
    List<SyncTombstone> updatedTombstones = state.data.taskTombstones;

    final List<TaskItem> updatedTasks = [];
    final Set<String> taskIdsAlreadyAdded = {};

    for (final TaskItem task in state.data.tasks) {
      final bool shouldClear = task.isCompleted &&
          (category == AppData.defaultCategory || task.category == category);

      if (!shouldClear) {
        updatedTasks.add(task);
        taskIdsAlreadyAdded.add(task.id);
        continue;
      }

      updatedTombstones = _upsertTombstone(
        updatedTombstones,
        _makeTombstone(task.id, now),
      );

      final TaskItem? nextRepeatedTask = _makeNextRepeatedTask(task, now);

      if (nextRepeatedTask != null &&
          !taskIdsAlreadyAdded.contains(nextRepeatedTask.id)) {
        updatedTasks.add(nextRepeatedTask);
        taskIdsAlreadyAdded.add(nextRepeatedTask.id);
      }
    }

    await _updateAndSave(
      state.data.copyWith(
        tasks: updatedTasks,
        taskTombstones: updatedTombstones,
      ),
    );
  }

  Future<void> addSubtask({
    required String taskId,
    required String title,
  }) async {
    if (title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Subtask title cannot be empty.'));
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    final SubtaskItem subtask = SubtaskItem(
      id: const Uuid().v4(),
      title: title.trim(),
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    final List<TaskItem> updatedTasks = state.data.tasks.map((task) {
      if (task.id != taskId) {
        return task;
      }

      return task.copyWith(
        subtasks: [...task.subtasks, subtask],
        updatedAt: now,
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(tasks: updatedTasks),
    );
  }

  Future<void> editSubtask({
    required String taskId,
    required String subtaskId,
    required String title,
  }) async {
    if (title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Subtask title cannot be empty.'));
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    final List<TaskItem> updatedTasks = state.data.tasks.map((task) {
      if (task.id != taskId) {
        return task;
      }

      final List<SubtaskItem> updatedSubtasks = task.subtasks.map((subtask) {
        if (subtask.id != subtaskId) {
          return subtask;
        }

        return subtask.copyWith(
          title: title.trim(),
          updatedAt: now,
        );
      }).toList();

      return task.copyWith(
        subtasks: updatedSubtasks,
        updatedAt: now,
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(tasks: updatedTasks),
    );
  }

  Future<void> toggleSubtask({
    required String taskId,
    required String subtaskId,
  }) async {
    final DateTime now = DateTime.now().toUtc();

    final List<TaskItem> updatedTasks = state.data.tasks.map((task) {
      if (task.id != taskId) {
        return task;
      }

      final List<SubtaskItem> updatedSubtasks = task.subtasks.map((subtask) {
        if (subtask.id != subtaskId) {
          return subtask;
        }

        return subtask.copyWith(
          isCompleted: !subtask.isCompleted,
          updatedAt: now,
        );
      }).toList();

      return task.copyWith(
        subtasks: updatedSubtasks,
        updatedAt: now,
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(tasks: updatedTasks),
    );
  }

  Future<void> deleteSubtask({
    required String taskId,
    required String subtaskId,
  }) async {
    final DateTime now = DateTime.now().toUtc();

    final List<TaskItem> updatedTasks = state.data.tasks.map((task) {
      if (task.id != taskId) {
        return task;
      }

      return task.copyWith(
        subtasks:
            task.subtasks.where((subtask) => subtask.id != subtaskId).toList(),
        updatedAt: now,
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(
        tasks: updatedTasks,
        subtaskTombstones: _upsertTombstone(
          state.data.subtaskTombstones,
          _makeTombstone(subtaskId, now),
        ),
      ),
    );
  }

  Future<void> addJournalEntry({
    required String title,
    required String body,
  }) async {
    if (title.trim().isEmpty && body.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Journal entry cannot be empty.',
        ),
      );
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    final JournalEntry entry = JournalEntry(
      id: const Uuid().v4(),
      title: title.trim().isEmpty ? 'Untitled Entry' : title.trim(),
      body: body.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final List<JournalEntry> updatedEntries = [
      ...state.data.journalEntries,
      entry,
    ];

    await _updateAndSave(
      state.data.copyWith(journalEntries: updatedEntries),
    );
  }

  Future<void> editJournalEntry({
    required String entryId,
    required String title,
    required String body,
  }) async {
    if (title.trim().isEmpty && body.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Journal entry cannot be empty.',
        ),
      );
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    final List<JournalEntry> updatedEntries =
        state.data.journalEntries.map((entry) {
      if (entry.id != entryId) {
        return entry;
      }

      return entry.copyWith(
        title: title.trim().isEmpty ? 'Untitled Entry' : title.trim(),
        body: body.trim(),
        updatedAt: now,
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(journalEntries: updatedEntries),
    );
  }

  Future<void> deleteJournalEntry(String entryId) async {
    final DateTime now = DateTime.now().toUtc();
    final List<JournalEntry> updatedEntries =
        state.data.journalEntries.where((entry) => entry.id != entryId).toList();

    await _updateAndSave(
      state.data.copyWith(
        journalEntries: updatedEntries,
        journalTombstones: _upsertTombstone(
          state.data.journalTombstones,
          _makeTombstone(entryId, now),
        ),
      ),
    );
  }

  Future<void> addWatchItem({
    required String title,
    required MediaType type,
    required WatchStatus status,
    required int season,
    required int episode,
    required String notes,
  }) async {
    if (title.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Watchlist title cannot be empty.',
        ),
      );
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    final WatchItem item = WatchItem(
      id: const Uuid().v4(),
      title: title.trim(),
      type: type,
      status: status,
      season: type == MediaType.tvShow && season > 0 ? season : 0,
      episode: type == MediaType.tvShow && episode > 0 ? episode : 0,
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final List<WatchItem> updatedItems = [
      ...state.data.watchItems,
      item,
    ];

    await _updateAndSave(
      state.data.copyWith(watchItems: updatedItems),
    );
  }

  Future<void> editWatchItem({
    required String itemId,
    required String title,
    required MediaType type,
    required WatchStatus status,
    required int season,
    required int episode,
    required String notes,
  }) async {
    if (title.trim().isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Watchlist title cannot be empty.',
        ),
      );
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    final List<WatchItem> updatedItems = state.data.watchItems.map((item) {
      if (item.id != itemId) {
        return item;
      }

      return item.copyWith(
        title: title.trim(),
        type: type,
        status: status,
        season: type == MediaType.tvShow && season > 0 ? season : 0,
        episode: type == MediaType.tvShow && episode > 0 ? episode : 0,
        notes: notes.trim(),
        updatedAt: now,
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(watchItems: updatedItems),
    );
  }

  Future<void> deleteWatchItem(String itemId) async {
    final DateTime now = DateTime.now().toUtc();
    final List<WatchItem> updatedItems =
        state.data.watchItems.where((item) => item.id != itemId).toList();

    await _updateAndSave(
      state.data.copyWith(
        watchItems: updatedItems,
        watchTombstones: _upsertTombstone(
          state.data.watchTombstones,
          _makeTombstone(itemId, now),
        ),
      ),
    );
  }

  Future<void> updateWatchStatus({
    required String itemId,
    required WatchStatus status,
  }) async {
    final List<WatchItem> updatedItems = state.data.watchItems.map((item) {
      if (item.id != itemId) {
        return item;
      }

      return item.copyWith(
        status: status,
        updatedAt: DateTime.now().toUtc(),
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(watchItems: updatedItems),
    );
  }

  Future<void> addGroceryItem({
    required String title,
    required String description,
    required GrocerySection section,
    required bool autoAddToNext,
  }) async {
    if (title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Grocery item title cannot be empty.'));
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    final GroceryItem item = GroceryItem(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description.trim(),
      section: section,
      isCompleted: false,
      autoAddToNext: autoAddToNext,
      createdAt: now,
      updatedAt: now,
    );

    final List<GroceryItem> updatedItems = [
      ...state.data.groceryItems,
      item,
    ];

    await _updateAndSave(
      state.data.copyWith(groceryItems: updatedItems),
    );
  }

  Future<void> editGroceryItem({
    required String itemId,
    required String title,
    required String description,
    required GrocerySection section,
    required bool autoAddToNext,
  }) async {
    if (title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Grocery item title cannot be empty.'));
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    final List<GroceryItem> updatedItems = state.data.groceryItems.map((item) {
      if (item.id != itemId) {
        return item;
      }

      return item.copyWith(
        title: title.trim(),
        description: description.trim(),
        section: section,
        autoAddToNext: autoAddToNext,
        updatedAt: now,
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(groceryItems: updatedItems),
    );
  }

  Future<void> toggleGroceryItemComplete(String itemId) async {
    final DateTime now = DateTime.now().toUtc();

    final List<GroceryItem> updatedItems = state.data.groceryItems.map((item) {
      if (item.id != itemId) {
        return item;
      }

      return item.copyWith(
        isCompleted: !item.isCompleted,
        updatedAt: now,
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(groceryItems: updatedItems),
    );
  }

  GroceryItem _makeNextTimeCopy(GroceryItem item, DateTime now) {
    return GroceryItem(
      id: const Uuid().v4(),
      title: item.title,
      description: item.description,
      section: GrocerySection.nextTime,
      isCompleted: false,
      autoAddToNext: item.autoAddToNext,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool _alreadyHasNextTimeCopy({
    required List<GroceryItem> items,
    required GroceryItem sourceItem,
  }) {
    return items.any((item) {
      return item.section == GrocerySection.nextTime &&
          !item.isCompleted &&
          item.title.trim().toLowerCase() ==
              sourceItem.title.trim().toLowerCase();
    });
  }

  GroceryItem? _findGroceryItem(String itemId) {
    for (final GroceryItem item in state.data.groceryItems) {
      if (item.id == itemId) {
        return item;
      }
    }

    return null;
  }

  Future<void> deleteGroceryItem(String itemId) async {
    final DateTime now = DateTime.now().toUtc();

    final GroceryItem? itemToDelete = _findGroceryItem(itemId);

    final List<GroceryItem> updatedItems =
        state.data.groceryItems.where((item) => item.id != itemId).toList();

    if (itemToDelete != null &&
        itemToDelete.section == GrocerySection.current &&
        itemToDelete.isCompleted &&
        itemToDelete.autoAddToNext &&
        !_alreadyHasNextTimeCopy(
          items: updatedItems,
          sourceItem: itemToDelete,
        )) {
      updatedItems.add(_makeNextTimeCopy(itemToDelete, now));
    }

    await _updateAndSave(
      state.data.copyWith(
        groceryItems: updatedItems,
        groceryTombstones: _upsertTombstone(
          state.data.groceryTombstones,
          _makeTombstone(itemId, now),
        ),
      ),
    );
  }

  Future<void> clearCompletedGroceryItems(GrocerySection section) async {
    final DateTime now = DateTime.now().toUtc();
    final List<GroceryItem> updatedItems = [];
    List<SyncTombstone> updatedTombstones = state.data.groceryTombstones;

    for (final GroceryItem item in state.data.groceryItems) {
      final bool shouldClear = item.section == section && item.isCompleted;

      if (!shouldClear) {
        updatedItems.add(item);
        continue;
      }

      updatedTombstones = _upsertTombstone(
        updatedTombstones,
        _makeTombstone(item.id, now),
      );

      if (item.section == GrocerySection.current &&
          item.autoAddToNext &&
          !_alreadyHasNextTimeCopy(
            items: [...updatedItems, ...state.data.groceryItems],
            sourceItem: item,
          )) {
        updatedItems.add(_makeNextTimeCopy(item, now));
      }
    }

    await _updateAndSave(
      state.data.copyWith(
        groceryItems: updatedItems,
        groceryTombstones: updatedTombstones,
      ),
    );
  }

  Future<void> moveGroceryItemToCurrent(String itemId) async {
    final DateTime now = DateTime.now().toUtc();

    final List<GroceryItem> updatedItems = state.data.groceryItems.map((item) {
      if (item.id != itemId) {
        return item;
      }

      return item.copyWith(
        section: GrocerySection.current,
        isCompleted: false,
        updatedAt: now,
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(groceryItems: updatedItems),
    );
  }

  Future<void> moveAllNextTimeGroceryItemsToCurrent() async {
    final DateTime now = DateTime.now().toUtc();
    bool changed = false;

    final List<GroceryItem> updatedItems = state.data.groceryItems.map((item) {
      if (item.section != GrocerySection.nextTime) {
        return item;
      }

      changed = true;

      return item.copyWith(
        section: GrocerySection.current,
        isCompleted: false,
        updatedAt: now,
      );
    }).toList();

    if (!changed) {
      return;
    }

    await _updateAndSave(
      state.data.copyWith(groceryItems: updatedItems),
    );
  }

  Future<void> moveGroceryItemToNextTime(String itemId) async {
    final DateTime now = DateTime.now().toUtc();

    final List<GroceryItem> updatedItems = state.data.groceryItems.map((item) {
      if (item.id != itemId) {
        return item;
      }

      return item.copyWith(
        section: GrocerySection.nextTime,
        isCompleted: false,
        updatedAt: now,
      );
    }).toList();

    await _updateAndSave(
      state.data.copyWith(groceryItems: updatedItems),
    );
  }
}
