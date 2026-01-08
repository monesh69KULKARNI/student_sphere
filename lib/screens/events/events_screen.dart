import 'package:flutter/material.dart';
import 'events_list_screen.dart';
import 'registered_events_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Events'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.list),
                text: 'All Events',
              ),
              Tab(
                icon: Icon(Icons.event_available),
                text: 'My Events',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EventsListScreen(isPublicOnly: false),
            RegisteredEventsScreen(),
          ],
        ),
      ),
    );
  }
}

