import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_cubit.dart';
import 'app_state.dart';
import 'grocery_item.dart';

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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                item == null ? 'Add Grocery Item' : 'Edit Grocery Item',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<GrocerySection>(
                        value: section,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: GrocerySection.current,
                            child: Text('Current Grocery Run'),
                          ),
                          DropdownMenuItem(
                            value: GrocerySection.nextTime,
                            child: Text('Next Time'),
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
                        title: const Text(
                          'Add again to Next Time when completed',
                        ),
                        subtitle: const Text(
                          'The item will appear in Next Time after you clear/delete it from Current Grocery Run.',
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
                  child: const Text('Cancel'),
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
                  child: const Text('Save'),
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
                      color: Color(0xFF0A3D91),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${items.length}',
                  style: const TextStyle(
                    color: Color(0xFF0A66D8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    _showGroceryDialog(
                      context,
                      initialSection: section,
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(emptyText),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final GroceryItem item = items[index];

                      return Card(
                        elevation: 0,
                        color: const Color(0xFFF8FBFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(
                            color: Color(0xFFD8E9FF),
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
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.repeat,
                                        size: 15,
                                        color: Color(0xFF0A66D8),
                                      ),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Repeats to Next Time after clearing',
                                          style: TextStyle(
                                            color: Color(0xFF0A66D8),
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
                                  tooltip: 'Move to current run',
                                  onPressed: () {
                                    context
                                        .read<AppCubit>()
                                        .moveGroceryItemToCurrent(item.id);
                                  },
                                  icon: const Icon(Icons.arrow_left),
                                ),
                              if (section == GrocerySection.current)
                                IconButton(
                                  tooltip: 'Move to next time',
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  '$tickedCount ticked',
                  style: const TextStyle(
                    color: Colors.blueGrey,
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
                  label: const Text('Clear Ticked'),
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
          backgroundColor: const Color(0xFFF4F8FF),
          appBar: AppBar(
            title: const Text('Grocery List'),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 850) {
                return ListView(
                  children: [
                    SizedBox(
                      height: 520,
                      child: _sectionPanel(
                        context: context,
                        title: 'Current Grocery Run',
                        emptyText: 'No groceries for this run yet.',
                        section: GrocerySection.current,
                        items: currentItems,
                      ),
                    ),
                    SizedBox(
                      height: 520,
                      child: _sectionPanel(
                        context: context,
                        title: 'Next Time',
                        emptyText: 'No saved groceries for next time yet.',
                        section: GrocerySection.nextTime,
                        items: nextTimeItems,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _sectionPanel(
                      context: context,
                      title: 'Current Grocery Run',
                      emptyText: 'No groceries for this run yet.',
                      section: GrocerySection.current,
                      items: currentItems,
                    ),
                  ),
                  Expanded(
                    child: _sectionPanel(
                      context: context,
                      title: 'Next Time',
                      emptyText: 'No saved groceries for next time yet.',
                      section: GrocerySection.nextTime,
                      items: nextTimeItems,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
