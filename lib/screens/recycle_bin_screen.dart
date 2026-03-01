import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../features/events/presentation/events_view_model.dart';
import '../providers/recycle_bin_provider.dart';
import '../utils/snackbar_helpers.dart';

class RecycleBinScreen extends ConsumerWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedEvents = ref.watch(recycleBinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          if (deletedEvents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () => _confirmEmptyBin(context, ref),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: deletedEvents.isEmpty
                ? const Center(child: Text('Recycle bin is empty'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: deletedEvents.length,
                    itemBuilder: (context, index) {
                      final event = deletedEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: event.color.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.event, color: event.color.color),
                          ),
                          title: Text(
                            event.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Deleted: ${DateFormat.yMMMd().add_jm().format(event.deletedAt ?? DateTime.now())}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.restore,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  ref
                                      .read(eventsProvider.notifier)
                                      .restoreEvent(event);
                                  ref
                                      .read(recycleBinProvider.notifier)
                                      .restoreFromBin(event);
                                  SnackbarHelpers.showSuccess(
                                    context,
                                    'Event restored',
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                onPressed: () => ref
                                    .read(recycleBinProvider.notifier)
                                    .permanentlyDelete(event),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyBin(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Bin?'),
        content: const Text(
          'All events in the recycle bin will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(recycleBinProvider.notifier).emptyBin();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
