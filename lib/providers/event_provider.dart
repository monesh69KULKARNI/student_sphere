import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();
  List<Event> _events = [];
  bool _isLoading = false;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _events = await _eventService.getEvents();
      _events.sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEvent(Event event) async {
    await _eventService.addEvent(event);
    await loadEvents();
  }

  Future<void> updateEvent(Event event) async {
    await _eventService.updateEvent(event);
    await loadEvents();
  }

  Future<void> deleteEvent(String eventId) async {
    await _eventService.deleteEvent(eventId);
    await loadEvents();
  }

  Future<bool> registerForEvent(String eventId, String studentId) async {
    final success = await _eventService.registerForEvent(eventId, studentId);
    if (success) {
      await loadEvents();
    }
    return success;
  }

  Future<bool> unregisterFromEvent(String eventId, String studentId) async {
    final success = await _eventService.unregisterFromEvent(eventId, studentId);
    if (success) {
      await loadEvents();
    }
    return success;
  }
}

