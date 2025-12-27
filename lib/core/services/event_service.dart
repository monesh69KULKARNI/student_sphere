import '../models/event_model.dart';
import 'supabase_database_service.dart';

class EventService {
  // Get all events (with optional filters)
  Stream<List<EventModel>> getEvents({
    bool? isPublic,
    String? category,
    bool upcomingOnly = false,
  }) {
    return SupabaseDatabaseService.getEventsStream(
      isPublic: isPublic,
      category: category,
      upcomingOnly: upcomingOnly,
    ).map((dataList) {
      return dataList.map((data) => EventModel.fromMap(_convertSupabaseToModel(data))).toList();
    });
  }

  // Get single event
  Future<EventModel?> getEvent(String eventId) async {
    try {
      final data = await SupabaseDatabaseService.getEvent(eventId);
      if (data == null) return null;
      return EventModel.fromMap(_convertSupabaseToModel(data));
    } catch (e) {
      return null;
    }
  }

  // Create event
  Future<String> createEvent(EventModel event) async {
    try {
      final eventData = _convertModelToSupabase(event.toMap());
      return await SupabaseDatabaseService.createEvent(eventData);
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Update event
  Future<void> updateEvent(EventModel event) async {
    try {
      final updates = _convertModelToSupabase(event.toMap());
      await SupabaseDatabaseService.updateEvent(event.id, updates);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await SupabaseDatabaseService.deleteEvent(eventId);
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Register for event
  Future<bool> registerForEvent(String eventId, String userId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null || event.isFull) return false;

      if (event.registeredParticipants.contains(userId)) return false;

      final updatedParticipants = [...event.registeredParticipants, userId];
      await SupabaseDatabaseService.updateEvent(
        eventId,
        {'registered_participants': updatedParticipants},
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Unregister from event
  Future<bool> unregisterFromEvent(String eventId, String userId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null) return false;

      final updatedParticipants = List<String>.from(event.registeredParticipants)
        ..remove(userId);

      await SupabaseDatabaseService.updateEvent(
        eventId,
        {'registered_participants': updatedParticipants},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Volunteer for event
  Future<bool> volunteerForEvent(String eventId, String userId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null || !event.requiresVolunteers || event.volunteersFull) {
        return false;
      }

      if (event.volunteers.contains(userId)) return false;

      final updatedVolunteers = [...event.volunteers, userId];
      await SupabaseDatabaseService.updateEvent(
        eventId,
        {'volunteers': updatedVolunteers},
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Convert Supabase snake_case to model camelCase
  Map<String, dynamic> _convertSupabaseToModel(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'title': data['title'],
      'description': data['description'],
      'startDate': data['start_date'],
      'endDate': data['end_date'],
      'location': data['location'],
      'organizerId': data['organizer_id'],
      'organizerName': data['organizer_name'],
      'maxParticipants': data['max_participants'],
      'registeredParticipants': List<String>.from(data['registered_participants'] ?? []),
      'volunteers': List<String>.from(data['volunteers'] ?? []),
      'requiresVolunteers': data['requires_volunteers'] ?? false,
      'maxVolunteers': data['max_volunteers'] ?? 0,
      'imageUrl': data['image_url'],
      'isPublic': data['is_public'] ?? true,
      'category': data['category'],
      'createdAt': data['created_at'],
      'updatedAt': data['updated_at'],
    };
  }

  // Convert model camelCase to Supabase snake_case
  Map<String, dynamic> _convertModelToSupabase(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'title': data['title'],
      'description': data['description'],
      'start_date': data['startDate'],
      'end_date': data['endDate'],
      'location': data['location'],
      'organizer_id': data['organizerId'],
      'organizer_name': data['organizerName'],
      'max_participants': data['maxParticipants'],
      'registered_participants': data['registeredParticipants'],
      'volunteers': data['volunteers'],
      'requires_volunteers': data['requiresVolunteers'],
      'max_volunteers': data['maxVolunteers'],
      'image_url': data['imageUrl'],
      'is_public': data['isPublic'],
      'category': data['category'],
      'created_at': data['createdAt'],
      'updated_at': data['updatedAt'],
    };
  }
}
