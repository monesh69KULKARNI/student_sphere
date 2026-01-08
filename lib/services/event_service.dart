import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';

class EventService {
  final supabase = Supabase.instance.client;

  // FETCH user's own events
  Future<List<Event>> getEvents() async {
    try {
      final response = await supabase
          .from('events')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);

      if (response is List) {
        return response.map((json) => Event.fromJson(json)).toList();
      } else {
        print('Unexpected response type: ${response.runtimeType}');
        return [];
      }
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  // CREATE new event (NO image_url)
  Future<void> addEvent(Event event) async {
    try {
      await supabase.from('events').insert({
        'title': event.title,
        'description': event.description,
        'date': event.date.toIso8601String(),
        'location': event.location ?? '',
        'user_id': supabase.auth.currentUser!.id,
        'max_participants': event.maxParticipants ?? 10,
        'registered_participants': [],
      });
    } catch (e) {
      print('Error adding event: $e');
      rethrow;
    }
  }

  // UPDATE event (NO image_url)
  Future<void> updateEvent(Event event) async {
    try {
      await supabase
          .from('events')
          .update({
        'title': event.title,
        'description': event.description,
        'date': event.date.toIso8601String(),
        'location': event.location ?? '',
        'max_participants': event.maxParticipants ?? 10,
      })
          .eq('id', event.id)
          .eq('user_id', supabase.auth.currentUser!.id);
    } catch (e) {
      print('Error updating event: $e');
    }
  }

  // DELETE event
  Future<void> deleteEvent(String eventId) async {
    try {
      await supabase
          .from('events')
          .delete()
          .eq('id', eventId)
          .eq('user_id', supabase.auth.currentUser!.id);
    } catch (e) {
      print('Error deleting event: $e');
    }
  }

  // REGISTER for event
  Future<bool> registerForEvent(String eventId, String studentId) async {
    try {
      final eventData = await supabase
          .from('events')
          .select('registered_participants, max_participants')
          .eq('id', eventId)
          .maybeSingle();

      if (eventData == null) return false;

      List<String> participants = [];
      final rawParticipants = eventData['registered_participants'] ?? [];

      if (rawParticipants is List) {
        participants = rawParticipants.map((e) => e.toString()).toList();
      }

      final maxParticipants = eventData['max_participants'] ?? 10;
      if (participants.contains(studentId) || participants.length >= maxParticipants) {
        return false;
      }

      participants.add(studentId);
      await supabase
          .from('events')
          .update({'registered_participants': participants})
          .eq('id', eventId);

      return true;
    } catch (e) {
      print('Error registering: $e');
      return false;
    }
  }

  // UNREGISTER from event
  Future<bool> unregisterFromEvent(String eventId, String studentId) async {
    try {
      final eventData = await supabase
          .from('events')
          .select('registered_participants')
          .eq('id', eventId)
          .maybeSingle();

      if (eventData == null) return false;

      List<String> participants = [];
      final rawParticipants = eventData['registered_participants'] ?? [];

      if (rawParticipants is List) {
        participants = rawParticipants.map((e) => e.toString()).toList();
      }

      if (!participants.contains(studentId)) {
        return false;
      }

      participants.remove(studentId);
      await supabase
          .from('events')
          .update({'registered_participants': participants})
          .eq('id', eventId);

      return true;
    } catch (e) {
      print('Error unregistering: $e');
      return false;
    }
  }
}
