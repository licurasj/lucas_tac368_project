import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_cubit.dart';
import 'app_state.dart';
import 'grocery_item.dart';
import 'app_colors.dart';
import 'l10n/generated/app_localizations.dart';

class GroceryScreen extends StatelessWidget {
  const GroceryScreen({super.key});

  Future<void> _showGroceryDialog(
    BuildContext context, {
    GroceryItem? item,
    GrocerySection initialSection = GrocerySection.current,
  }) async {
    final TextEditingController titleController = TextEditingController(
      text: item?.title ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: item?.description ?? '',
    );

    GrocerySection section = item?.section ?? initialSection;
    bool autoAddToNext = item?.autoAddToNext ?? false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final AppLocalizations loc = AppLocalizations.of(context);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                item == null ? loc.addGroceryItem : loc.editGroceryItem,
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: loc.titleRequired,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: loc.description,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<GrocerySection>(
                        value: section,
                        decoration: InputDecoration(
                          labelText: loc.section,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: GrocerySection.current,
                            child: Text(loc.currentGroceryRun),
                          ),
                          DropdownMenuItem(
                            value: GrocerySection.nextTime,
                            child: Text(loc.nextTime),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              section = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          loc.addAgainNextTime,
                        ),
                        subtitle: Text(
                          loc.addAgainNextTimeDescription,
                        ),
                        value: autoAddToNext,
                        onChanged: (value) {
                          setDialogState(() {
                            autoAddToNext = value;
                          });
                        },
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
                      context.read<AppCubit>().addGroceryItem(
                            title: titleController.text,
                            description: descriptionController.text,
                            section: section,
                            autoAddToNext: autoAddToNext,
                          );
                    } else {
                      context.read<AppCubit>().editGroceryItem(
                            itemId: item.id,
                            title: titleController.text,
                            description: descriptionController.text,
                            section: section,
                            autoAddToNext: autoAddToNext,
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

    // Do not dispose these local controllers here. Android can rebuild the
    // closing dialog/TextField for a frame after showDialog completes, especially
    // while the keyboard is hiding. Disposing immediately caused
    // "TextEditingController was used after being disposed" crashes.
  }

  Widget _sectionPanel({
    required BuildContext context,
    required String title,
    required String emptyText,
    required GrocerySection section,
    required List<GroceryItem> items,
  }) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final int tickedCount = items.where((item) => item.isCompleted).length;

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${items.length}',
                  style: const TextStyle(
                    color: AppColors.actionBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: items.isEmpty
                      ? Center(
                          child: Text(emptyText),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final GroceryItem item = items[index];

                            return Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color: Theme.of(context).dividerTheme.color ?? AppColors.borderBlue,
                          ),
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: item.isCompleted,
                            onChanged: (_) {
                              context
                                  .read<AppCubit>()
                                  .toggleGroceryItemComplete(item.id);
                            },
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.description.trim().isNotEmpty)
                                Text(item.description),
                              if (item.autoAddToNext)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.repeat,
                                        size: 15,
                                        color: AppColors.actionBlue,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          loc.repeatsToNextTime,
                                          style: const TextStyle(
                                            color: AppColors.actionBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 2,
                            children: [
                              if (section == GrocerySection.nextTime)
                                IconButton(
                                  tooltip: loc.moveToCurrentRun,
                                  onPressed: () {
                                    context
                                        .read<AppCubit>()
                                        .moveGroceryItemToCurrent(item.id);
                                  },
                                  icon: const Icon(Icons.arrow_left),
                                ),
                              if (section == GrocerySection.current)
                                IconButton(
                                  tooltip: loc.moveToNextTime,
                                  onPressed: () {
                                    context
                                        .read<AppCubit>()
                                        .moveGroceryItemToNextTime(item.id);
                                  },
                                  icon: const Icon(Icons.arrow_right),
                                ),
                              IconButton(
                                onPressed: () {
                                  _showGroceryDialog(
                                    context,
                                    item: item,
                                  );
                                },
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                onPressed: () {
                                  context
                                      .read<AppCubit>()
                                      .deleteGroceryItem(item.id);
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    shape: const CircleBorder(),
                    backgroundColor: AppColors.logoBlue,
                    foregroundColor: Colors.white,
                    heroTag: 'add_grocery_${section.name}',
                    onPressed: () {
                      _showGroceryDialog(
                        context,
                        initialSection: section,
                      );
                    },
                    tooltip: loc.addGroceryItemTooltip,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      loc.tickedCount(tickedCount),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color ??
                            AppColors.mutedText,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: tickedCount > 0
                          ? () {
                              context
                                  .read<AppCubit>()
                                  .clearCompletedGroceryItems(section);
                            }
                          : null,
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: Text(loc.clearTicked),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final AppLocalizations loc = AppLocalizations.of(context);

        final List<GroceryItem> currentItems = state.data.groceryItems
            .where((item) => item.section == GrocerySection.current)
            .toList()
          ..sort((a, b) {
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? 1 : -1;
            }

            return b.createdAt.compareTo(a.createdAt);
          });

        final List<GroceryItem> nextTimeItems = state.data.groceryItems
            .where((item) => item.section == GrocerySection.nextTime)
            .toList()
          ..sort((a, b) {
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? 1 : -1;
            }

            return b.createdAt.compareTo(a.createdAt);
          });

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(loc.groceryList),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 850) {
                return RefreshIndicator(
                  onRefresh: () {
                    return context.read<AppCubit>().syncWithDrive();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 520,
                        child: _sectionPanel(
                          context: context,
                          title: loc.currentGroceryRun,
                          emptyText: loc.noGroceriesCurrent,
                          section: GrocerySection.current,
                          items: currentItems,
                        ),
                      ),
                      SizedBox(
                        height: 520,
                        child: _sectionPanel(
                          context: context,
                          title: loc.nextTime,
                          emptyText: loc.noGroceriesNext,
                          section: GrocerySection.nextTime,
                          items: nextTimeItems,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () {
                  return context.read<AppCubit>().syncWithDrive();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: _sectionPanel(
                            context: context,
                            title: loc.currentGroceryRun,
                            emptyText: loc.noGroceriesCurrent,
                            section: GrocerySection.current,
                            items: currentItems,
                          ),
                        ),
                        Expanded(
                          child: _sectionPanel(
                            context: context,
                            title: loc.nextTime,
                            emptyText: loc.noGroceriesNext,
                            section: GrocerySection.nextTime,
                            items: nextTimeItems,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
