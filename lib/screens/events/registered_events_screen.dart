import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/event_model.dart';
import '../../core/services/event_service.dart';
import '../../core/providers/auth_provider.dart';
import 'event_detail_screen.dart';

class RegisteredEventsScreen extends StatelessWidget {
  const RegisteredEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final eventService = EventService();

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Events'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Please sign in to view your registered events',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final userId = authProvider.currentUser!.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Events'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.event_available),
                text: 'Registered',
              ),
              Tab(
                icon: Icon(Icons.volunteer_activism),
                text: 'Volunteering',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RegisteredEventsList(
              userId: userId,
              eventStream: eventService.getUserRegisteredEvents(userId),
              emptyMessage: 'You haven\'t registered for any events yet',
              emptyIcon: Icons.event_available,
            ),
            _RegisteredEventsList(
              userId: userId,
              eventStream: eventService.getUserVolunteerEvents(userId),
              emptyMessage: 'You aren\'t volunteering for any events yet',
              emptyIcon: Icons.volunteer_activism,
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisteredEventsList extends StatelessWidget {
  final String userId;
  final Stream<List<EventModel>> eventStream;
  final String emptyMessage;
  final IconData emptyIcon;

  const _RegisteredEventsList({
    required this.userId,
    required this.eventStream,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: eventStream,
      builder: (context, snapshot) {
        // Debug info
        debugPrint('🔄 StreamBuilder state: ${snapshot.connectionState}');
        if (snapshot.hasData) {
          debugPrint('📊 Stream data received: ${snapshot.data!.length} events');
        }
        if (snapshot.hasError) {
          debugPrint('❌ Stream error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your events...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading events',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Force refresh by rebuilding the stream
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisteredEventsScreen(),
                      ),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  emptyIcon,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse available events and register to see them here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to all events tab
                    DefaultTabController.of(context)?.animateTo(0);
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Explore Events'),
                ),
              ],
            ),
          );
        }

        // Sort events by start date
        events.sort((a, b) => a.startDate.compareTo(b.startDate));

        return RefreshIndicator(
          onRefresh: () async {
            // Trigger a manual refresh by rebuilding
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const RegisteredEventsScreen(),
              ),
            );
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventCard(event: event);
            },
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = event.endDate.isBefore(now);
    final isOngoing = now.isAfter(event.startDate) && now.isBefore(event.endDate);
    final isUpcoming = event.startDate.isAfter(now);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPast) {
      statusColor = Colors.grey;
      statusText = 'Completed';
      statusIcon = Icons.check_circle;
    } else if (isOngoing) {
      statusColor = Colors.green;
      statusText = 'Ongoing';
      statusIcon = Icons.play_circle;
    } else {
      statusColor = Colors.blue;
      statusText = 'Upcoming';
      statusIcon = Icons.upcoming;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.startDate.hour}:${event.startDate.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.category,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${event.registeredParticipants.length}/${event.maxParticipants} registered',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
