import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../features/events/presentation/events_view_model.dart';
import '../widgets/premium_empty_state.dart';
import 'event_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allEventsMap = ref.watch(eventsProvider);
    // Flatten map to list
    final allEvents = allEventsMap.values.expand((element) => element).toList();

    // Filter
    final results = _query.isEmpty
        ? <Event>[]
        : allEvents
              .where(
                (e) =>
                    e.title.toLowerCase().contains(_query.toLowerCase()) ||
                    (e.location?.toLowerCase().contains(_query.toLowerCase()) ??
                        false) ||
                    (e.notes?.toLowerCase().contains(_query.toLowerCase()) ??
                        false),
              )
              .toList();

    // Sort by date
    results.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          showCursor: true, // Stops the blinking cursor

          decoration: const InputDecoration(
            hintText: 'Search events...',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: theme.textTheme.titleLarge,
          onChanged: (val) {
            setState(() {
              _query = val;
            });
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? const PremiumEmptyState(
              icon: Icons.search_rounded,
              title: 'Search Events',
              message: 'Find events by title, location, or notes.',
            )
          : results.isEmpty
          ? PremiumEmptyState(
              icon: Icons.event_busy_rounded,
              title: 'No Results Found',
              message: 'We couldn\'t find anything matching "$_query".',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final event = results[index];
                return ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailScreen(event: event),
                    ),
                  ),
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: (event.customColor ?? event.color.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${DateFormat('MMM d, yyyy').format(event.startTime)} • ${DateFormat('h:mm a').format(event.startTime)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: event.location != null
                      ? const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        )
                      : null,
                );
              },
            ),
    );
  }
}
