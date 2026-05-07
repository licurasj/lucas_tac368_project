enum RepeatFrequency {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

class SubtaskItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubtaskItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  SubtaskItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubtaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SubtaskItem.fromJson(Map<String, dynamic> json) {
    return SubtaskItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final String category;
  final List<SubtaskItem> subtasks;
  final DateTime? reminderAt;
  final RepeatFrequency repeatFrequency;
  final int? customRepeatDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.category,
    required this.subtasks,
    required this.reminderAt,
    required this.repeatFrequency,
    required this.customRepeatDays,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? category,
    List<SubtaskItem>? subtasks,
    DateTime? reminderAt,
    RepeatFrequency? repeatFrequency,
    int? customRepeatDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearReminder = false,
    bool clearCustomRepeatDays = false,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      subtasks: subtasks ?? this.subtasks,
      reminderAt: clearReminder ? null : reminderAt ?? this.reminderAt,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      customRepeatDays:
          clearCustomRepeatDays ? null : customRepeatDays ?? this.customRepeatDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get completedSubtaskCount {
    return subtasks.where((subtask) => subtask.isCompleted).length;
  }

  bool get hasReminder {
    return reminderAt != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'category': category,
      'subtasks': subtasks.map((subtask) => subtask.toJson()).toList(),
      'reminderAt': reminderAt?.toIso8601String(),
      'repeatFrequency': repeatFrequency.name,
      'customRepeatDays': customRepeatDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      category: json['category'] as String? ?? '',
      subtasks: (json['subtasks'] as List<dynamic>? ?? [])
          .map((item) => SubtaskItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      reminderAt: DateTime.tryParse(json['reminderAt'] as String? ?? ''),
      repeatFrequency: RepeatFrequency.values.firstWhere(
        (repeat) => repeat.name == json['repeatFrequency'],
        orElse: () => RepeatFrequency.none,
      ),
      customRepeatDays: json['customRepeatDays'] as int?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
