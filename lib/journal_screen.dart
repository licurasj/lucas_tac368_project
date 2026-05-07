import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'app_cubit.dart';
import 'app_state.dart';
import 'journal_entry.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() {
    return _JournalScreenState();
  }
}

class _JournalScreenState extends State<JournalScreen> {
  final Set<int> _expandedYears = {};
  final Set<String> _expandedMonths = {};

  Future<void> _showJournalDialog(
    BuildContext context, {
    JournalEntry? entry,
  }) async {
    final TextEditingController titleController = TextEditingController(
      text: entry?.title ?? '',
    );
    final TextEditingController bodyController = TextEditingController(
      text: entry?.body ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final Size screenSize = MediaQuery.of(dialogContext).size;

        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: SizedBox(
            width: screenSize.width * 0.88,
            height: screenSize.height * 0.84,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry == null
                              ? 'Add Journal Entry'
                              : 'Edit Journal Entry',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A3D91),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: bodyController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        labelText: 'Entry',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          if (entry == null) {
                            context.read<AppCubit>().addJournalEntry(
                                  title: titleController.text,
                                  body: bodyController.text,
                                );
                          } else {
                            context.read<AppCubit>().editJournalEntry(
                                  entryId: entry.id,
                                  title: titleController.text,
                                  body: bodyController.text,
                                );
                          }

                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Do not dispose these local controllers here. Android can rebuild the
    // closing dialog/TextField for a frame after showDialog completes, especially
    // while the keyboard is hiding. Disposing immediately caused
    // "TextEditingController was used after being disposed" crashes.
  }

  Future<void> _showReadJournalDialog(
    BuildContext context,
    JournalEntry entry,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final Size screenSize = MediaQuery.of(dialogContext).size;
        final String dateText =
            DateFormat.yMMMMd().add_jm().format(entry.createdAt.toLocal());

        return Dialog(
          insetPadding: const EdgeInsets.all(28),
          child: SizedBox(
            width: screenSize.width * 0.82,
            height: screenSize.height * 0.78,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A3D91),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        entry.body,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Future<void>.delayed(
                            const Duration(milliseconds: 120),
                            () {
                              if (!mounted) {
                                return;
                              }

                              _showJournalDialog(
                                context,
                                entry: entry,
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEntryTile(BuildContext context, JournalEntry entry) {
    final String dateText =
        DateFormat.MMMd().format(entry.createdAt.toLocal());

    return ListTile(
      title: Text(entry.title),
      subtitle: Text(
        dateText,
        style: const TextStyle(color: Colors.blueGrey),
      ),
      onTap: () {
        _showReadJournalDialog(context, entry);
      },
      trailing: Wrap(
        spacing: 2,
        children: [
          IconButton(
            onPressed: () {
              _showJournalDialog(
                context,
                entry: entry,
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () {
              context.read<AppCubit>().deleteJournalEntry(entry.id);
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  String _monthLabel(int month) {
    return DateFormat.MMMM().format(DateTime(2000, month));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final List<JournalEntry> entries = [...state.data.journalEntries]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final Map<int, Map<int, List<JournalEntry>>> grouped = {};

        for (final JournalEntry entry in entries) {
          final DateTime localDate = entry.createdAt.toLocal();
          final int year = localDate.year;
          final int month = localDate.month;

          grouped.putIfAbsent(year, () => {});
          grouped[year]!.putIfAbsent(month, () => []);
          grouped[year]![month]!.add(entry);
        }

        final List<int> years = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return Scaffold(
          backgroundColor: const Color(0xFFF4F8FF),
          appBar: AppBar(
            title: const Text('Journal'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showJournalDialog(context);
            },
            child: const Icon(Icons.add),
          ),
          body: entries.isEmpty
              ? const Center(
                  child: Text('No journal entries yet.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: years.length,
                  itemBuilder: (context, yearIndex) {
                    final int year = years[yearIndex];
                    final Map<int, List<JournalEntry>> monthsMap =
                        grouped[year]!;
                    final List<int> months = monthsMap.keys.toList()
                      ..sort((a, b) => b.compareTo(a));

                    final bool showMonths = months.length > 1;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ExpansionTile(
                        key: PageStorageKey('year_$year'),
                        initiallyExpanded: _expandedYears.contains(year),
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              _expandedYears.add(year);
                            } else {
                              _expandedYears.remove(year);
                            }
                          });
                        },
                        title: Text(
                          '$year',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A3D91),
                          ),
                        ),
                        children: showMonths
                            ? months.map((month) {
                                final String monthKey = '$year-$month';
                                final List<JournalEntry> monthEntries =
                                    monthsMap[month]!
                                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                                return ExpansionTile(
                                  key: PageStorageKey('month_$monthKey'),
                                  initiallyExpanded:
                                      _expandedMonths.contains(monthKey),
                                  onExpansionChanged: (expanded) {
                                    setState(() {
                                      if (expanded) {
                                        _expandedMonths.add(monthKey);
                                      } else {
                                        _expandedMonths.remove(monthKey);
                                      }
                                    });
                                  },
                                  title: Text(
                                    _monthLabel(month),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  children: monthEntries
                                      .map(
                                        (entry) =>
                                            _buildEntryTile(context, entry),
                                      )
                                      .toList(),
                                );
                              }).toList()
                            : monthsMap[months.first]!
                                .map(
                                  (entry) => _buildEntryTile(context, entry),
                                )
                                .toList(),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
