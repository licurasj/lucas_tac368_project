import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'app_data.dart';
import 'app_state.dart';
import 'app_storage.dart';
import 'drive_sync_service.dart';
import 'journal_entry.dart';
import 'task_item.dart';
import 'watch_item.dart';
import 'grocery_item.dart';

class AppCubit extends Cubit<AppState> {
  final AppStorage storage;
  final DriveSyncService driveSyncService;

  AppCubit({
    required this.storage,
    required this.driveSyncService,
    required String deviceId,
  }) : super(AppState.initial(deviceId));

  // Future<void> loadData() async {
  //   emit(state.copyWith(isLoading: true, clearError: true));

  //   try {
  //     final AppData loadedData = await storage.loadAppData();

  //     emit(
  //       state.copyWith(
  //         data: loadedData,
  //         isLoading: false,
  //         clearError: true,
  //       ),
  //     );

  //     await syncWithDrive();
  //   } catch (_) {
  //     emit(
  //       state.copyWith(
  //         isLoading: false,
  //         errorMessage: 'Could not load local data.',
  //       ),
  //     );
  //   }
  // }

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final AppData loadedData = await storage.loadAppData();

      emit(
        state.copyWith(
          data: loadedData,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Could not load local data.',
        ),
      );
    }
  }

  Future<void> _saveData(AppData data) async {
    await storage.saveAppData(data);
  }

  Future<void> _updateAndSave(AppData data) async {
    final AppData updatedData = data.copyWith(
      lastModified: DateTime.now().toUtc(),
    );

    emit(
      state.copyWith(
        data: updatedData,
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
    }
  }

  Future<void> signInToGoogle() async {
    emit(
      state.copyWith(
        isSyncing: true,
        clearError: true,
        clearSyncMessage: true,
      ),
    );

    final bool signedIn = await driveSyncService.signIn();

    emit(
      state.copyWith(
        isSyncing: false,
        syncMessage: signedIn
            ? 'Signed in to Google. You can sync now.'
            : 'Google sign-in failed or was cancelled.',
      ),
    );
  }

  Future<void> signOutOfGoogle() async {
    await driveSyncService.signOut();

    emit(
      state.copyWith(
        syncMessage: 'Signed out of Google.',
      ),
    );
  }

  Future<void> syncWithDrive() async {
    emit(
      state.copyWith(
        isSyncing: true,
        clearError: true,
        clearSyncMessage: true,
      ),
    );

    final result = await driveSyncService.sync(localData: state.data);

    if (result.success && result.syncedData != null) {
      await _saveData(result.syncedData!);

      emit(
        state.copyWith(
          data: result.syncedData!,
          isSyncing: false,
          syncMessage: result.message,
          lastSyncedAt: DateTime.now().toUtc(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          isSyncing: false,
          syncMessage: result.message,
        ),
      );
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
      state.data.copyWith(categories: updatedCategories),
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

    final List<String> updatedCategories =
        state.data.categories.where((category) => category != categoryName).toList();

    await _updateAndSave(
      state.data.copyWith(categories: updatedCategories),
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
    final List<TaskItem> updatedTasks =
        state.data.tasks.where((task) => task.id != taskId).toList();

    await _updateAndSave(
      state.data.copyWith(tasks: updatedTasks),
    );
  }

  Future<void> clearCompletedTasks(String category) async {
    final List<TaskItem> updatedTasks = state.data.tasks.where((task) {
      if (!task.isCompleted) {
        return true;
      }

      if (category == AppData.defaultCategory) {
        return false;
      }

      return task.category != category;
    }).toList();

    await _updateAndSave(
      state.data.copyWith(tasks: updatedTasks),
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
      state.data.copyWith(tasks: updatedTasks),
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

    final List<JournalEntry> updatedEntries = state.data.journalEntries.map((entry) {
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
    final List<JournalEntry> updatedEntries =
        state.data.journalEntries.where((entry) => entry.id != entryId).toList();

    await _updateAndSave(
      state.data.copyWith(journalEntries: updatedEntries),
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
    final List<WatchItem> updatedItems =
        state.data.watchItems.where((item) => item.id != itemId).toList();

    await _updateAndSave(
      state.data.copyWith(watchItems: updatedItems),
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

Future<void> deleteGroceryItem(String itemId) async {
  final DateTime now = DateTime.now().toUtc();

  final GroceryItem? itemToDelete = state.data.groceryItems
      .where((item) => item.id == itemId)
      .firstOrNull;

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
    state.data.copyWith(groceryItems: updatedItems),
  );
}

Future<void> clearCompletedGroceryItems(GrocerySection section) async {
  final DateTime now = DateTime.now().toUtc();
  final List<GroceryItem> updatedItems = [];

  for (final GroceryItem item in state.data.groceryItems) {
    final bool shouldClear = item.section == section && item.isCompleted;

    if (!shouldClear) {
      updatedItems.add(item);
      continue;
    }

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
    state.data.copyWith(groceryItems: updatedItems),
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
