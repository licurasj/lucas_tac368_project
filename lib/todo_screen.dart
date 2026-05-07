import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'app_data.dart';
import 'app_cubit.dart';
import 'app_state.dart';
import 'task_item.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() {
    return _TodoScreenState();
  }
}

class _TodoScreenState extends State<TodoScreen> {
  String selectedCategory = AppData.defaultCategory;

  String _categoryDisplayName(String category) {
    if (category == AppData.defaultCategory) {
      return 'All My Tasks';
    }

    return category;
  }

  String _taskCategoryForNewTask() {
    if (selectedCategory == AppData.defaultCategory) {
      return AppData.defaultCategory;
    }

    return selectedCategory;
  }

  Widget _buildCategoryPanel({
    required BuildContext context,
    required AppState state,
    required List<String> categories,
    required String activeCategory,
    required bool isDrawer,
  }) {
    return SafeArea(
      child: Container(
        width: 260,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Categories',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A3D91),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _showAddCategoryDialog(context);
                    },
                    icon: const Icon(Icons.add),
                    color: const Color(0xFF0A66D8),
                    tooltip: 'Create category',
                  ),
                  if (isDrawer)
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Close categories',
                    ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final String category = categories[index];

                  final int count = category == AppData.defaultCategory
                      ? state.data.tasks.length
                      : state.data.tasks
                          .where((task) => task.category == category)
                          .length;

                  final bool isSelected = category == activeCategory;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: const Color(0xFFD8E9FF),
                    leading: Icon(
                      category == AppData.defaultCategory
                          ? Icons.task_alt
                          : Icons.folder_outlined,
                      color: isSelected
                          ? const Color(0xFF0A66D8)
                          : Colors.blueGrey,
                    ),
                    title: Text(
                      _categoryDisplayName(category),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    trailing: SizedBox(
                      width: category == AppData.defaultCategory ? 34 : 82,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '$count',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (category != AppData.defaultCategory)
                            IconButton(
                              onPressed: () {
                                context.read<AppCubit>().deleteCategory(
                                      category,
                                    );

                                if (selectedCategory == category) {
                                  setState(() {
                                    selectedCategory = AppData.defaultCategory;
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                              ),
                              tooltip: 'Delete category',
                            ),
                        ],
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });

                      if (isDrawer) {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader({
    required BuildContext context,
    required bool isNarrow,
    required String activeCategory,
    required List<String> categories,
  }) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _categoryDisplayName(activeCategory),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: isNarrow ? 22 : 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0A3D91),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isNarrow)
            IconButton.filled(
              onPressed: () {
                _showTaskDialog(context, categories);
              },
              icon: const Icon(Icons.add),
              tooltip: 'Add task',
            )
          else
            FilledButton.icon(
              onPressed: () {
                _showTaskDialog(context, categories);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();

    final String? categoryName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Category'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              final String trimmedValue = value.trim();

              if (trimmedValue.isNotEmpty) {
                Navigator.of(dialogContext).pop(trimmedValue);
              }
            },
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
                final String trimmedValue = nameController.text.trim();

                if (trimmedValue.isNotEmpty) {
                  Navigator.of(dialogContext).pop(trimmedValue);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    if (categoryName != null && categoryName.isNotEmpty) {
      context.read<AppCubit>().addCategory(categoryName);

      setState(() {
        selectedCategory = categoryName;
      });
    }
  }

  Future<void> _showTaskDialog(
    BuildContext context,
    List<String> categories, {
    TaskItem? task,
  }) async {
    final TextEditingController titleController = TextEditingController(
      text: task?.title ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    final TextEditingController customRepeatController = TextEditingController(
      text: task?.customRepeatDays?.toString() ?? '',
    );

    String category = task == null
        ? _taskCategoryForNewTask()
        : (task.category.isEmpty ? AppData.defaultCategory : task.category);

    if (!categories.contains(category)) {
      category = AppData.defaultCategory;
    }

    bool hasReminder = task?.reminderAt != null;
    DateTime? reminderDate = task?.reminderAt?.toLocal();
    TimeOfDay? reminderTime = task?.reminderAt == null
        ? null
        : TimeOfDay.fromDateTime(task!.reminderAt!.toLocal());
    RepeatFrequency repeatFrequency =
        task?.repeatFrequency ?? RepeatFrequency.none;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            DateTime? combinedReminder;

            if (hasReminder && reminderDate != null && reminderTime != null) {
              combinedReminder = DateTime(
                reminderDate!.year,
                reminderDate!.month,
                reminderDate!.day,
                reminderTime!.hour,
                reminderTime!.minute,
              );
            }

            return AlertDialog(
              title: Text(task == null ? 'Add Task' : 'Edit Task'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 440,
                ),
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
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categories.map((categoryName) {
                          return DropdownMenuItem(
                            value: categoryName,
                            child: Text(
                              _categoryDisplayName(categoryName),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              category = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Set reminder'),
                        value: hasReminder,
                        onChanged: (value) {
                          setDialogState(() {
                            hasReminder = value;
                            if (!hasReminder) {
                              reminderDate = null;
                              reminderTime = null;
                              repeatFrequency = RepeatFrequency.none;
                              customRepeatController.clear();
                            }
                          });
                        },
                      ),
                      if (hasReminder) ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool narrowButtons =
                                constraints.maxWidth < 360;

                            final Widget dateButton = OutlinedButton.icon(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: reminderDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 1),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 3650),
                                  ),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    reminderDate = picked;
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                reminderDate == null
                                    ? 'Date'
                                    : DateFormat.yMMMd().format(reminderDate!),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );

                            final Widget timeButton = OutlinedButton.icon(
                              onPressed: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: reminderTime ?? TimeOfDay.now(),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    reminderTime = picked;
                                  });
                                }
                              },
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                reminderTime == null
                                    ? 'Time'
                                    : reminderTime!.format(context),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );

                            if (narrowButtons) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  dateButton,
                                  const SizedBox(height: 8),
                                  timeButton,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: dateButton),
                                const SizedBox(width: 8),
                                Expanded(child: timeButton),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<RepeatFrequency>(
                          value: repeatFrequency,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Repeat',
                          ),
                          items: RepeatFrequency.values.map((repeat) {
                            return DropdownMenuItem(
                              value: repeat,
                              child: Text(_repeatLabel(repeat)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                repeatFrequency = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        if (repeatFrequency == RepeatFrequency.custom)
                          TextField(
                            controller: customRepeatController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Repeat every how many days?',
                            ),
                          ),
                        if (combinedReminder != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'Reminder: ${DateFormat.yMMMd().add_jm().format(combinedReminder)}',
                              style: const TextStyle(
                                color: Color(0xFF0A66D8),
                              ),
                            ),
                          ),
                      ],
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
                    DateTime? finalReminder;

                    if (hasReminder &&
                        reminderDate != null &&
                        reminderTime != null) {
                      finalReminder = DateTime(
                        reminderDate!.year,
                        reminderDate!.month,
                        reminderDate!.day,
                        reminderTime!.hour,
                        reminderTime!.minute,
                      );
                    }

                    if (task == null) {
                      context.read<AppCubit>().addTask(
                            title: titleController.text,
                            description: descriptionController.text,
                            category: category,
                            reminderAt: finalReminder,
                            repeatFrequency: finalReminder == null
                                ? RepeatFrequency.none
                                : repeatFrequency,
                            customRepeatDays: int.tryParse(
                              customRepeatController.text,
                            ),
                          );
                    } else {
                      context.read<AppCubit>().editTask(
                            taskId: task.id,
                            title: titleController.text,
                            description: descriptionController.text,
                            category: category,
                            reminderAt: finalReminder,
                            repeatFrequency: finalReminder == null
                                ? RepeatFrequency.none
                                : repeatFrequency,
                            customRepeatDays: int.tryParse(
                              customRepeatController.text,
                            ),
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
  }

  Future<void> _showSubtaskDialog(
    BuildContext context,
    TaskItem task, {
    SubtaskItem? subtask,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: subtask?.title ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(subtask == null ? 'Add Subtask' : 'Edit Subtask'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Subtask title *',
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
                if (subtask == null) {
                  context.read<AppCubit>().addSubtask(
                        taskId: task.id,
                        title: controller.text,
                      );
                } else {
                  context.read<AppCubit>().editSubtask(
                        taskId: task.id,
                        subtaskId: subtask.id,
                        title: controller.text,
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
  }

  static String _repeatLabel(RepeatFrequency repeat) {
    switch (repeat) {
      case RepeatFrequency.none:
        return 'Does not repeat';
      case RepeatFrequency.daily:
        return 'Daily';
      case RepeatFrequency.weekly:
        return 'Weekly';
      case RepeatFrequency.monthly:
        return 'Monthly';
      case RepeatFrequency.yearly:
        return 'Yearly';
      case RepeatFrequency.custom:
        return 'Custom';
    }
  }

  String _reminderText(TaskItem task) {
    if (task.reminderAt == null) {
      return '';
    }

    final String dateText =
        DateFormat.yMMMd().add_jm().format(task.reminderAt!.toLocal());

    if (task.repeatFrequency == RepeatFrequency.none) {
      return dateText;
    }

    if (task.repeatFrequency == RepeatFrequency.custom) {
      return '$dateText • repeats every ${task.customRepeatDays ?? 1} day(s)';
    }

    return '$dateText • repeats ${_repeatLabel(task.repeatFrequency).toLowerCase()}';
  }

  String _taskSubtitle(TaskItem task) {
    final List<String> parts = [];

    if (task.description.trim().isNotEmpty) {
      parts.add(task.description.trim());
    }

    if (task.category.trim().isNotEmpty &&
        task.category != AppData.defaultCategory) {
      parts.add(task.category.trim());
    }

    return parts.join(' | ');
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _taskBucket(TaskItem task) {
    if (task.reminderAt == null) {
      return 'Today';
    }

    final DateTime localReminder = task.reminderAt!.toLocal();
    final DateTime now = DateTime.now();
    final DateTime tomorrow = now.add(const Duration(days: 1));

    if (_isSameDate(localReminder, now)) {
      return 'Today';
    }

    if (_isSameDate(localReminder, tomorrow)) {
      return 'Tomorrow';
    }

    return 'Later';
  }

  Widget _buildTaskCard(
    BuildContext context,
    TaskItem task,
    List<String> categories,
  ) {
    final String subtitle = _taskSubtitle(task);

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      child: ExpansionTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) {
            context.read<AppCubit>().toggleTaskComplete(task.id);
          },
        ),
        title: Text(
          task.title,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            if (task.hasReminder)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: Color(0xFF0A66D8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _reminderText(task),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Color(0xFF0A66D8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (task.subtasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Subtasks: ${task.completedSubtaskCount}/${task.subtasks.length}',
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showTaskDialog(
                context,
                categories,
                task: task,
              );
            }

            if (value == 'delete') {
              context.read<AppCubit>().deleteTask(task.id);
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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Subtasks',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A3D91),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _showSubtaskDialog(context, task);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (task.subtasks.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No subtasks yet.'),
                  ),
                for (final subtask in task.subtasks)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: subtask.isCompleted,
                    title: Text(
                      subtask.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        decoration: subtask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    secondary: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showSubtaskDialog(
                            context,
                            task,
                            subtask: subtask,
                          );
                        }

                        if (value == 'delete') {
                          context.read<AppCubit>().deleteSubtask(
                                taskId: task.id,
                                subtaskId: subtask.id,
                              );
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ];
                      },
                    ),
                    onChanged: (_) {
                      context.read<AppCubit>().toggleSubtask(
                            taskId: task.id,
                            subtaskId: subtask.id,
                          );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaskSection(
    BuildContext context, {
    required String title,
    required List<TaskItem> tasks,
    required List<String> categories,
  }) {
    if (tasks.isEmpty) {
      return [];
    }

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A3D91),
          ),
        ),
      ),
      ...tasks.map(
        (task) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildTaskCard(context, task, categories),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final List<String> categories =
            state.data.categories.contains(AppData.defaultCategory)
                ? state.data.categories
                : [AppData.defaultCategory, ...state.data.categories];

        if (!categories.contains(selectedCategory)) {
          selectedCategory = AppData.defaultCategory;
        }

        final String activeCategory = selectedCategory;

        final List<TaskItem> tasks = state.data.tasks.where((task) {
          if (activeCategory == AppData.defaultCategory) {
            return true;
          }

          return task.category == activeCategory;
        }).toList()
          ..sort((a, b) {
            final DateTime aDate = a.reminderAt?.toLocal() ?? a.createdAt;
            final DateTime bDate = b.reminderAt?.toLocal() ?? b.createdAt;
            return aDate.compareTo(bDate);
          });

        final List<TaskItem> todayTasks =
            tasks.where((task) => _taskBucket(task) == 'Today').toList();

        final List<TaskItem> tomorrowTasks =
            tasks.where((task) => _taskBucket(task) == 'Tomorrow').toList();

        final List<TaskItem> laterTasks =
            tasks.where((task) => _taskBucket(task) == 'Later').toList();

        final int completedTaskCount =
            tasks.where((task) => task.isCompleted).length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 760;

            final Widget taskContent = Column(
              children: [
                _buildTaskHeader(
                  context: context,
                  isNarrow: isNarrow,
                  activeCategory: activeCategory,
                  categories: categories,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await context.read<AppCubit>().syncWithDrive();
                    },
                    child: tasks.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            children: const [
                              SizedBox(height: 240),
                              Center(
                                child: Text('No tasks here yet.'),
                              ),
                            ],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            children: [
                              ..._buildTaskSection(
                                context,
                                title: 'Today',
                                tasks: todayTasks,
                                categories: categories,
                              ),
                              ..._buildTaskSection(
                                context,
                                title: 'Tomorrow',
                                tasks: tomorrowTasks,
                                categories: categories,
                              ),
                              ..._buildTaskSection(
                                context,
                                title: 'Later',
                                tasks: laterTasks,
                                categories: categories,
                              ),
                            ],
                          ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$completedTaskCount ticked',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: completedTaskCount > 0
                            ? () {
                                context
                                    .read<AppCubit>()
                                    .clearCompletedTasks(activeCategory);
                              }
                            : null,
                        icon: const Icon(
                          Icons.cleaning_services_outlined,
                        ),
                        label: Text(isNarrow ? 'Clear' : 'Clear Ticked'),
                      ),
                    ],
                  ),
                ),
              ],
            );

            return Scaffold(
              backgroundColor: const Color(0xFFF4F8FF),
              appBar: AppBar(
                title: const Text('Tasks'),
                actions: [
                  IconButton(
                    onPressed: () {
                      _showAddCategoryDialog(context);
                    },
                    icon: const Icon(Icons.create_new_folder_outlined),
                    tooltip: 'Create category',
                  ),
                ],
              ),
              drawer: isNarrow
                  ? Drawer(
                      child: _buildCategoryPanel(
                        context: context,
                        state: state,
                        categories: categories,
                        activeCategory: activeCategory,
                        isDrawer: true,
                      ),
                    )
                  : null,
              body: isNarrow
                  ? taskContent
                  : Row(
                      children: [
                        _buildCategoryPanel(
                          context: context,
                          state: state,
                          categories: categories,
                          activeCategory: activeCategory,
                          isDrawer: false,
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: taskContent,
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
