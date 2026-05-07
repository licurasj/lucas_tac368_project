import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_cubit.dart';
import 'app_state.dart';
import 'app_colors.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const HomeScreen({
    super.key,
    this.onNavigate,
  });

  Widget _summaryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final BorderRadius borderRadius = BorderRadius.circular(6);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 34),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _openPage(int index) {
    onNavigate?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hybrid Note App'),
            actions: [
              IconButton(
                onPressed: () {
                  context.read<AppCubit>().toggleDarkMode();
                },
                icon: Icon(
                  state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: state.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
              ),
              IconButton(
                onPressed: state.isSyncing
                    ? null
                    : () {
                        context.read<AppCubit>().syncWithDrive();
                      },
                icon: state.isSyncing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_sync),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () {
              return context.read<AppCubit>().syncWithDrive();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _summaryCard(
                  context: context,
                  icon: Icons.pending_actions,
                  title: 'Pending Tasks',
                  value: '${state.pendingTaskCount}',
                  onTap: () {
                    _openPage(1);
                  },
                ),
                _summaryCard(
                  context: context,
                  icon: Icons.done_all,
                  title: 'Completed Tasks',
                  value: '${state.completedTaskCount}',
                  onTap: () {
                    _openPage(1);
                  },
                ),
                _summaryCard(
                  context: context,
                  icon: Icons.book,
                  title: 'Journal Entries',
                  value: '${state.data.journalEntries.length}',
                  onTap: () {
                    _openPage(3);
                  },
                ),
                _summaryCard(
                  context: context,
                  icon: Icons.movie,
                  title: 'Watch/Read Items',
                  value: '${state.data.watchItems.length}',
                  onTap: () {
                    _openPage(4);
                  },
                ),
                _summaryCard(
                  context: context,
                  icon: Icons.shopping_cart,
                  title: 'Grocery Items',
                  value: '${state.data.groceryItems.length}',
                  onTap: () {
                    _openPage(2);
                  },
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Drive Sync',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: state.isDarkMode
                                    ? AppColors.darkText
                                    : AppColors.darkBlue,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.isSyncing
                              ? 'Syncing...'
                              : state.lastSyncedAt == null
                                  ? 'Not synced yet.'
                                  : 'Last synced: ${state.lastSyncedAt!.toLocal()}',
                        ),
                        if (!state.isSyncing && state.syncMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(state.syncMessage!),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: state.isSyncing
                              ? null
                              : () {
                                  if (state.isGoogleSignedIn) {
                                    context.read<AppCubit>().signOutOfGoogle();
                                  } else {
                                    context.read<AppCubit>().signInToGoogle();
                                  }
                                },
                          icon: Icon(
                            state.isGoogleSignedIn ? Icons.logout : Icons.login,
                          ),
                          label: Text(
                            state.isGoogleSignedIn ? 'Log out' : 'Sign in with Google',
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: state.isSyncing
                              ? null
                              : () {
                                  context.read<AppCubit>().syncWithDrive();
                                },
                          icon: state.isSyncing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_sync),
                          label: const Text('Sync to Google Drive'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
