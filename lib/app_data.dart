import 'grocery_item.dart';
import 'journal_entry.dart';
import 'task_item.dart';
import 'watch_item.dart';

class SyncTombstone {
  final String id;
  final DateTime deletedAt;
  final String deviceId;

  const SyncTombstone({
    required this.id,
    required this.deletedAt,
    required this.deviceId,
  });

  SyncTombstone copyWith({
    String? id,
    DateTime? deletedAt,
    String? deviceId,
  }) {
    return SyncTombstone(
      id: id ?? this.id,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deletedAt': deletedAt.toUtc().toIso8601String(),
      'deviceId': deviceId,
    };
  }

  factory SyncTombstone.fromJson(Map<String, dynamic> json) {
    return SyncTombstone(
      id: json['id'] as String? ?? '',
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      deviceId: json['deviceId'] as String? ?? '',
    );
  }
}

class AppData {
  static const String defaultCategory = 'All My Tasks';

  final int schemaVersion;
  final String deviceId;
  final DateTime lastModified;
  final bool isDarkMode;
  final List<String> categories;
  final List<TaskItem> tasks;
  final List<JournalEntry> journalEntries;
  final List<WatchItem> watchItems;
  final List<GroceryItem> groceryItems;
  final List<SyncTombstone> taskTombstones;
  final List<SyncTombstone> subtaskTombstones;
  final List<SyncTombstone> journalTombstones;
  final List<SyncTombstone> watchTombstones;
  final List<SyncTombstone> groceryTombstones;
  final List<SyncTombstone> categoryTombstones;

  const AppData({
    required this.schemaVersion,
    required this.deviceId,
    required this.lastModified,
    required this.isDarkMode,
    required this.categories,
    required this.tasks,
    required this.journalEntries,
    required this.watchItems,
    required this.groceryItems,
    required this.taskTombstones,
    required this.subtaskTombstones,
    required this.journalTombstones,
    required this.watchTombstones,
    required this.groceryTombstones,
    required this.categoryTombstones,
  });

  factory AppData.empty(String deviceId) {
    return AppData(
      schemaVersion: 2,
      deviceId: deviceId,
      lastModified: DateTime.now().toUtc(),
      isDarkMode: false,
      categories: const [defaultCategory],
      tasks: const [],
      journalEntries: const [],
      watchItems: const [],
      groceryItems: const [],
      taskTombstones: const [],
      subtaskTombstones: const [],
      journalTombstones: const [],
      watchTombstones: const [],
      groceryTombstones: const [],
      categoryTombstones: const [],
    );
  }

  AppData copyWith({
    int? schemaVersion,
    String? deviceId,
    DateTime? lastModified,
    bool? isDarkMode,
    List<String>? categories,
    List<TaskItem>? tasks,
    List<JournalEntry>? journalEntries,
    List<WatchItem>? watchItems,
    List<GroceryItem>? groceryItems,
    List<SyncTombstone>? taskTombstones,
    List<SyncTombstone>? subtaskTombstones,
    List<SyncTombstone>? journalTombstones,
    List<SyncTombstone>? watchTombstones,
    List<SyncTombstone>? groceryTombstones,
    List<SyncTombstone>? categoryTombstones,
  }) {
    return AppData(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      deviceId: deviceId ?? this.deviceId,
      lastModified: lastModified ?? this.lastModified,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      categories: categories ?? this.categories,
      tasks: tasks ?? this.tasks,
      journalEntries: journalEntries ?? this.journalEntries,
      watchItems: watchItems ?? this.watchItems,
      groceryItems: groceryItems ?? this.groceryItems,
      taskTombstones: taskTombstones ?? this.taskTombstones,
      subtaskTombstones: subtaskTombstones ?? this.subtaskTombstones,
      journalTombstones: journalTombstones ?? this.journalTombstones,
      watchTombstones: watchTombstones ?? this.watchTombstones,
      groceryTombstones: groceryTombstones ?? this.groceryTombstones,
      categoryTombstones: categoryTombstones ?? this.categoryTombstones,
    );
  }

  AppData pruneOldTombstones({
    DateTime? now,
    Duration maxAge = const Duration(days: 365),
  }) {
    final DateTime cutoff = (now ?? DateTime.now().toUtc()).subtract(maxAge);

    List<SyncTombstone> prune(List<SyncTombstone> tombstones) {
      return tombstones
          .where((tombstone) => tombstone.deletedAt.toUtc().isAfter(cutoff))
          .toList();
    }

    return copyWith(
      taskTombstones: prune(taskTombstones),
      subtaskTombstones: prune(subtaskTombstones),
      journalTombstones: prune(journalTombstones),
      watchTombstones: prune(watchTombstones),
      groceryTombstones: prune(groceryTombstones),
      categoryTombstones: prune(categoryTombstones),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'deviceId': deviceId,
      'lastModified': lastModified.toUtc().toIso8601String(),
      'isDarkMode': isDarkMode,
      'categories': categories,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'journalEntries': journalEntries.map((entry) => entry.toJson()).toList(),
      'watchItems': watchItems.map((item) => item.toJson()).toList(),
      'groceryItems': groceryItems.map((item) => item.toJson()).toList(),
      'taskTombstones': taskTombstones.map((item) => item.toJson()).toList(),
      'subtaskTombstones': subtaskTombstones.map((item) => item.toJson()).toList(),
      'journalTombstones': journalTombstones.map((item) => item.toJson()).toList(),
      'watchTombstones': watchTombstones.map((item) => item.toJson()).toList(),
      'groceryTombstones': groceryTombstones.map((item) => item.toJson()).toList(),
      'categoryTombstones': categoryTombstones.map((item) => item.toJson()).toList(),
    };
  }

  factory AppData.fromJson(Map<String, dynamic> json) {
    List<SyncTombstone> readTombstones(String key) {
      return (json[key] as List<dynamic>? ?? [])
          .map((item) => SyncTombstone.fromJson(item as Map<String, dynamic>))
          .where((item) => item.id.trim().isNotEmpty)
          .toList();
    }

    final List<TaskItem> loadedTasks = (json['tasks'] as List<dynamic>? ?? [])
        .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
        .map((task) {
      if (task.category == 'My Tasks' || task.category == defaultCategory) {
        return task.copyWith(category: '');
      }

      return task;
    }).toList();

    final List<SyncTombstone> categoryTombstones =
        readTombstones('categoryTombstones');
    final Set<String> deletedCategories = categoryTombstones
        .map((item) => item.id.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();

    final List<String> loadedCategories =
        (json['categories'] as List<dynamic>? ?? [])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .where((item) => item != 'My Tasks')
            .where((item) => item != defaultCategory)
            .where((item) => !deletedCategories.contains(item.toLowerCase()))
            .toSet()
            .toList();

    final List<String> taskCategories = loadedTasks
        .map((task) => task.category.trim())
        .where((category) => category.isNotEmpty)
        .where((category) => category != 'My Tasks')
        .where((category) => category != defaultCategory)
        .where((category) => !deletedCategories.contains(category.toLowerCase()))
        .toSet()
        .toList();

    final List<String> mergedCategories = {
      defaultCategory,
      ...loadedCategories,
      ...taskCategories,
    }.toList()
      ..sort((a, b) {
        if (a == defaultCategory) {
          return -1;
        }

        if (b == defaultCategory) {
          return 1;
        }

        return a.compareTo(b);
      });

    return AppData(
      schemaVersion: json['schemaVersion'] as int? ?? 2,
      deviceId: json['deviceId'] as String? ?? '',
      lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      categories: mergedCategories,
      tasks: loadedTasks,
      journalEntries: (json['journalEntries'] as List<dynamic>? ?? [])
          .map((item) => JournalEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      watchItems: (json['watchItems'] as List<dynamic>? ?? [])
          .map((item) => WatchItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      groceryItems: (json['groceryItems'] as List<dynamic>? ?? [])
          .map((item) => GroceryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      taskTombstones: readTombstones('taskTombstones'),
      subtaskTombstones: readTombstones('subtaskTombstones'),
      journalTombstones: readTombstones('journalTombstones'),
      watchTombstones: readTombstones('watchTombstones'),
      groceryTombstones: readTombstones('groceryTombstones'),
      categoryTombstones: categoryTombstones,
    ).pruneOldTombstones();
  }
}
