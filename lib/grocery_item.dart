enum GrocerySection {
  current,
  nextTime,
}

class GroceryItem {
  final String id;
  final String title;
  final String description;
  final GrocerySection section;
  final bool isCompleted;
  final bool autoAddToNext;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroceryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.section,
    required this.isCompleted,
    required this.autoAddToNext,
    required this.createdAt,
    required this.updatedAt,
  });

  GroceryItem copyWith({
    String? id,
    String? title,
    String? description,
    GrocerySection? section,
    bool? isCompleted,
    bool? autoAddToNext,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      section: section ?? this.section,
      isCompleted: isCompleted ?? this.isCompleted,
      autoAddToNext: autoAddToNext ?? this.autoAddToNext,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'section': section.name,
      'isCompleted': isCompleted,
      'autoAddToNext': autoAddToNext,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      section: GrocerySection.values.firstWhere(
        (section) => section.name == json['section'],
        orElse: () => GrocerySection.current,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      autoAddToNext: json['autoAddToNext'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
