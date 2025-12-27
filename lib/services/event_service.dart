import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';

class EventService {
  static const String _eventsKey = 'events';

  Future<List<Event>> getEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getStringList(_eventsKey) ?? [];
    return eventsJson.map((json) => Event.fromJson(jsonDecode(json))).toList();
  }

  Future<void> addEvent(Event event) async {
    final events = await getEvents();
    events.add(event);
    await _saveEvents(events);
  }

  Future<void> updateEvent(Event event) async {
    final events = await getEvents();
    final index = events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      events[index] = event;
      await _saveEvents(events);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final events = await getEvents();
    events.removeWhere((e) => e.id == eventId);
    await _saveEvents(events);
  }

  Future<bool> registerForEvent(String eventId, String studentId) async {
    final events = await getEvents();
    final event = events.firstWhere((e) => e.id == eventId);
    
    if (event.isFull || event.registeredParticipants.contains(studentId)) {
      return false;
    }

    final updatedEvent = event.copyWith(
      registeredParticipants: [...event.registeredParticipants, studentId],
    );
    
    final index = events.indexWhere((e) => e.id == eventId);
    events[index] = updatedEvent;
    await _saveEvents(events);
    return true;
  }

  Future<bool> unregisterFromEvent(String eventId, String studentId) async {
    final events = await getEvents();
    final event = events.firstWhere((e) => e.id == eventId);
    
    if (!event.registeredParticipants.contains(studentId)) {
      return false;
    }

    final updatedParticipants = List<String>.from(event.registeredParticipants)
      ..remove(studentId);
    
    final updatedEvent = event.copyWith(
      registeredParticipants: updatedParticipants,
    );
    
    final index = events.indexWhere((e) => e.id == eventId);
    events[index] = updatedEvent;
    await _saveEvents(events);
    return true;
  }

  Future<void> _saveEvents(List<Event> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = events.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_eventsKey, eventsJson);
  }
}

