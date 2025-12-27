import 'package:flutter/material.dart';

class AnnouncementsListScreen extends StatelessWidget {
  final bool isPublicOnly;

  const AnnouncementsListScreen({super.key, this.isPublicOnly = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: const Center(
        child: Text('Announcements list - Coming soon'),
      ),
    );
  }
}

