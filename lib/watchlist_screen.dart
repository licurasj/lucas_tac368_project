import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_cubit.dart';
import 'app_state.dart';
import 'watch_item.dart';
import 'app_colors.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  Future<void> _showWatchItemDialog(
    BuildContext context, {
    WatchItem? item,
  }) async {
    final TextEditingController titleController = TextEditingController(
      text: item?.title ?? '',
    );
    final TextEditingController seasonController = TextEditingController(
      text: item != null && item.type == MediaType.tvShow && item.season > 0
          ? item.season.toString()
          : '',
    );
    final TextEditingController episodeController = TextEditingController(
      text: item != null && item.type == MediaType.tvShow && item.episode > 0
          ? item.episode.toString()
          : '',
    );
    final TextEditingController notesController = TextEditingController(
      text: item?.notes ?? '',
    );

    MediaType selectedType = item?.type ?? MediaType.movie;
    WatchStatus selectedStatus = item?.status ?? WatchStatus.planned;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                item == null ? 'Add Watch/Read Item' : 'Edit Watch/Read Item',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<MediaType>(
                        value: selectedType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: MediaType.movie,
                            child: Text('Movie'),
                          ),
                          DropdownMenuItem(
                            value: MediaType.tvShow,
                            child: Text('TV Show'),
                          ),
                          DropdownMenuItem(
                            value: MediaType.book,
                            child: Text('Book'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedType = value;

                              if (selectedType != MediaType.tvShow) {
                                seasonController.clear();
                                episodeController.clear();
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<WatchStatus>(
                        value: selectedStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                        ),
                        items: WatchStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_statusLabel(status)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                      if (selectedType == MediaType.tvShow) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: seasonController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Season',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: episodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Episode',
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (item == null) {
                      context.read<AppCubit>().addWatchItem(
                            title: titleController.text,
                            type: selectedType,
                            status: selectedStatus,
                            season: int.tryParse(seasonController.text) ?? 0,
                            episode: int.tryParse(episodeController.text) ?? 0,
                            notes: notesController.text,
                          );
                    } else {
                      context.read<AppCubit>().editWatchItem(
                            itemId: item.id,
                            title: titleController.text,
                            type: selectedType,
                            status: selectedStatus,
                            season: int.tryParse(seasonController.text) ?? 0,
                            episode: int.tryParse(episodeController.text) ?? 0,
                            notes: notesController.text,
                          );
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // Intentionally do not dispose these local dialog controllers immediately.
    // On Android, the dialog route and keyboard can still rebuild TextFields for
    // a frame while closing, and disposing here can cause:
    // "A TextEditingController was used after being disposed."
  }

  static String _statusLabel(WatchStatus status) {
    switch (status) {
      case WatchStatus.planned:
        return 'Planned';
      case WatchStatus.inProgress:
        return 'In Progress';
      case WatchStatus.completed:
        return 'Completed';
    }
  }

  String _typeLabel(MediaType type) {
    switch (type) {
      case MediaType.movie:
        return 'Movie';
      case MediaType.tvShow:
        return 'TV Show';
      case MediaType.book:
        return 'Book';
    }
  }

  String _watchSubtitle(WatchItem item) {
    final List<String> parts = [
      _typeLabel(item.type),
      _statusLabel(item.status),
    ];

    if (item.type == MediaType.tvShow) {
      if (item.season > 0) {
        parts.add('Season ${item.season}');
      }

      if (item.episode > 0) {
        parts.add('Episode ${item.episode}');
      }
    }

    if (item.notes.trim().isNotEmpty) {
      parts.add(item.notes.trim());
    }

    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final List<WatchItem> items = [...state.data.watchItems]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Scaffold(
          backgroundColor: AppColors.softBackground,
          appBar: AppBar(
            title: const Text('Watch/Read List'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showWatchItemDialog(context);
            },
            child: const Icon(Icons.add),
          ),
          body: RefreshIndicator(
            onRefresh: () {
              return context.read<AppCubit>().syncWithDrive();
            },
            child: items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    children: const [
                      SizedBox(height: 260),
                      Center(
                        child: Text('No watch/read items yet.'),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final WatchItem item = items[index];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ListTile(
                          title: Text(
                            item.title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          subtitle: Text(
                            _watchSubtitle(item),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showWatchItemDialog(
                                  context,
                                  item: item,
                                );
                              }

                              if (value == 'delete') {
                                context.read<AppCubit>().deleteWatchItem(
                                      item.id,
                                    );
                              }
                            },
                            itemBuilder: (context) {
                              return const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Edit'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline),
                                    title: Text('Delete'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ];
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
