import 'grocery_item.dart';
import 'journal_entry.dart';
import 'task_item.dart';
import 'watch_item.dart';

class AppData {
  static const String defaultCategory = 'All My Tasks';

  final int schemaVersion;
  final String deviceId;
  final DateTime lastModified;
  final List<String> categories;
  final List<TaskItem> tasks;
  final List<JournalEntry> journalEntries;
  final List<WatchItem> watchItems;
  final List<GroceryItem> groceryItems;

  const AppData({
    required this.schemaVersion,
    required this.deviceId,
    required this.lastModified,
    required this.categories,
    required this.tasks,
    required this.journalEntries,
    required this.watchItems,
    required this.groceryItems,
  });

  factory AppData.empty(String deviceId) {
    return AppData(
      schemaVersion: 1,
      deviceId: deviceId,
      lastModified: DateTime.now().toUtc(),
      categories: const [defaultCategory],
      tasks: const [],
      journalEntries: const [],
      watchItems: const [],
      groceryItems: const [],
    );
  }

  AppData copyWith({
    int? schemaVersion,
    String? deviceId,
    DateTime? lastModified,
    List<String>? categories,
    List<TaskItem>? tasks,
    List<JournalEntry>? journalEntries,
    List<WatchItem>? watchItems,
    List<GroceryItem>? groceryItems,
  }) {
    return AppData(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      deviceId: deviceId ?? this.deviceId,
      lastModified: lastModified ?? this.lastModified,
      categories: categories ?? this.categories,
      tasks: tasks ?? this.tasks,
      journalEntries: journalEntries ?? this.journalEntries,
      watchItems: watchItems ?? this.watchItems,
      groceryItems: groceryItems ?? this.groceryItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'deviceId': deviceId,
      'lastModified': lastModified.toIso8601String(),
      'categories': categories,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'journalEntries': journalEntries.map((entry) => entry.toJson()).toList(),
      'watchItems': watchItems.map((item) => item.toJson()).toList(),
      'groceryItems': groceryItems.map((item) => item.toJson()).toList(),
    };
  }

  factory AppData.fromJson(Map<String, dynamic> json) {
    final List<TaskItem> loadedTasks = (json['tasks'] as List<dynamic>? ?? [])
        .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
        .map((task) {
      if (task.category == 'My Tasks' || task.category == defaultCategory) {
        return task.copyWith(category: '');
      }

      return task;
    }).toList();

    final List<String> loadedCategories =
        (json['categories'] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .where((item) => item != 'My Tasks')
            .where((item) => item != defaultCategory)
            .toSet()
            .toList();

    final List<String> taskCategories = loadedTasks
        .map((task) => task.category)
        .where((category) => category.trim().isNotEmpty)
        .where((category) => category != 'My Tasks')
        .where((category) => category != defaultCategory)
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
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      deviceId: json['deviceId'] as String? ?? '',
      lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ??
          DateTime.now().toUtc(),
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
    );
  }
}
