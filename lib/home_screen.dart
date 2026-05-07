import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_cubit.dart';
import 'app_state.dart';
import 'app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 34),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    );
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
              padding: const EdgeInsets.all(16),
              children: [
                _summaryCard(
                  icon: Icons.pending_actions,
                  title: 'Pending Tasks',
                  value: '${state.pendingTaskCount}',
                ),
                _summaryCard(
                  icon: Icons.done_all,
                  title: 'Completed Tasks',
                  value: '${state.completedTaskCount}',
                ),
                _summaryCard(
                  icon: Icons.book,
                  title: 'Journal Entries',
                  value: '${state.data.journalEntries.length}',
                ),
                _summaryCard(
                  icon: Icons.movie,
                  title: 'Watch/Read Items',
                  value: '${state.data.watchItems.length}',
                ),
                _summaryCard(
                  icon: Icons.shopping_cart,
                  title: 'Grocery Items',
                  value: '${state.data.groceryItems.length}',
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Google Drive Sync',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
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

                        // Only show syncMessage when NOT currently syncing.
                        // This prevents duplicate "Syncing..." text.
                        if (!state.isSyncing && state.syncMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(state.syncMessage!),
                        ],

                        const SizedBox(height: 12),

                        // This button is ONLY for login/logout.
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

                        // This button is ONLY for manual sync.
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
