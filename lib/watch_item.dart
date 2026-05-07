enum MediaType {
  movie,
  tvShow,
  book,
}

enum WatchStatus {
  planned,
  inProgress,
  completed,
}

class WatchItem {
  final String id;
  final String title;
  final MediaType type;
  final WatchStatus status;
  final int season;
  final int episode;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WatchItem({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.season,
    required this.episode,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  WatchItem copyWith({
    String? id,
    String? title,
    MediaType? type,
    WatchStatus? status,
    int? season,
    int? episode,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WatchItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'status': status.name,
      'season': season,
      'episode': episode,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WatchItem.fromJson(Map<String, dynamic> json) {
    final String rawType = json['type'] as String? ?? '';
    final String rawStatus = json['status'] as String? ?? '';

    MediaType parsedType;
    switch (rawType) {
      case 'tvShow':
        parsedType = MediaType.tvShow;
        break;
      case 'book':
        parsedType = MediaType.book;
        break;
      case 'movie':
      default:
        parsedType = MediaType.movie;
        break;
    }

    WatchStatus parsedStatus;
    switch (rawStatus) {
      case 'planToWatch':
        parsedStatus = WatchStatus.planned;
        break;
      case 'watching':
        parsedStatus = WatchStatus.inProgress;
        break;
      case 'planned':
        parsedStatus = WatchStatus.planned;
        break;
      case 'inProgress':
        parsedStatus = WatchStatus.inProgress;
        break;
      case 'completed':
        parsedStatus = WatchStatus.completed;
        break;
      default:
        parsedStatus = WatchStatus.planned;
        break;
    }

    return WatchItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: parsedType,
      status: parsedStatus,
      season: json['season'] as int? ?? 0,
      episode: json['episode'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
