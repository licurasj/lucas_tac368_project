import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_cubit.dart';
import 'app_state.dart';
import 'watch_item.dart';
import 'app_colors.dart';
import 'l10n/generated/app_localizations.dart';

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
        final AppLocalizations loc = AppLocalizations.of(context);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                item == null ? loc.addWatchReadItem : loc.editWatchReadItem,
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
                        decoration: InputDecoration(
                          labelText: loc.titleRequired,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<MediaType>(
                        value: selectedType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: loc.type,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: MediaType.movie,
                            child: Text(loc.movie),
                          ),
                          DropdownMenuItem(
                            value: MediaType.tvShow,
                            child: Text(loc.tvShow),
                          ),
                          DropdownMenuItem(
                            value: MediaType.book,
                            child: Text(loc.book),
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
                        decoration: InputDecoration(
                          labelText: loc.status,
                        ),
                        items: WatchStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_statusLabel(AppLocalizations.of(context), status)),
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
                          decoration: InputDecoration(
                            labelText: loc.season,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: episodeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.episode,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: loc.notes,
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
                  child: Text(loc.cancel),
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
                  child: Text(loc.save),
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

  static String _statusLabel(AppLocalizations loc, WatchStatus status) {
    switch (status) {
      case WatchStatus.planned:
        return loc.planned;
      case WatchStatus.inProgress:
        return loc.inProgress;
      case WatchStatus.completed:
        return loc.completed;
    }
  }

  String _typeLabel(AppLocalizations loc, MediaType type) {
    switch (type) {
      case MediaType.movie:
        return loc.movie;
      case MediaType.tvShow:
        return loc.tvShow;
      case MediaType.book:
        return loc.book;
    }
  }

  String _watchSubtitle(BuildContext context, WatchItem item) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final List<String> parts = [
      _typeLabel(loc, item.type),
      _statusLabel(loc, item.status),
    ];

    if (item.type == MediaType.tvShow) {
      if (item.season > 0) {
        parts.add(loc.seasonNumber(item.season));
      }

      if (item.episode > 0) {
        parts.add(loc.episodeNumber(item.episode));
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
        final AppLocalizations loc = AppLocalizations.of(context);
        final List<WatchItem> items = [...state.data.watchItems]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(loc.watchReadList),
          ),
          floatingActionButton: FloatingActionButton(
                    shape: const CircleBorder(),
                    backgroundColor: AppColors.logoBlue,
                    foregroundColor: Colors.white,
            onPressed: () {
              _showWatchItemDialog(context);
            },
            tooltip: loc.addWatchReadItemTooltip,
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
                    children: [
                      const SizedBox(height: 260),
                      Center(
                        child: Text(loc.noWatchReadItemsYet),
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
                            _watchSubtitle(context, item),
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
                              return [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: const Icon(Icons.edit_outlined),
                                    title: Text(loc.edit),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: const Icon(Icons.delete_outline),
                                    title: Text(loc.delete),
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
