import 'package:flutter/foundation.dart';
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
      debugPrint('🔐 Attempting to register user $userId for event $eventId');
      
      final event = await getEvent(eventId);
      if (event == null) {
        debugPrint('❌ Event not found: $eventId');
        return false;
      }
      
      if (event.isFull) {
        debugPrint('❌ Event is full: $eventId');
        return false;
      }

      if (event.registeredParticipants.contains(userId)) {
        debugPrint('⚠️ User already registered for event: $eventId');
        return false;
      }

      final updatedParticipants = [...event.registeredParticipants, userId];
      debugPrint('📝 Updating registered participants: ${updatedParticipants.length} (was ${event.registeredParticipants.length})');
      
      await SupabaseDatabaseService.updateEvent(
        eventId,
        {
          'registered_participants': updatedParticipants,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Successfully registered user $userId for event $eventId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to register for event: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Unregister from event
  Future<bool> unregisterFromEvent(String eventId, String userId) async {
    try {
      debugPrint('🔐 Attempting to unregister user $userId from event $eventId');
      
      final event = await getEvent(eventId);
      if (event == null) {
        debugPrint('❌ Event not found: $eventId');
        return false;
      }

      // Check if user is actually registered
      if (!event.registeredParticipants.contains(userId)) {
        debugPrint('⚠️ User $userId is not registered for event $eventId');
        return false;
      }

      final updatedParticipants = List<String>.from(event.registeredParticipants)
        ..remove(userId);

      debugPrint('📝 Updating registered participants: ${updatedParticipants.length} (was ${event.registeredParticipants.length})');
      
      await SupabaseDatabaseService.updateEvent(
        eventId,
        {
          'registered_participants': updatedParticipants,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      
      debugPrint('✅ Successfully unregistered user $userId from event $eventId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to unregister from event: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
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

  // Get user's registered events
  Stream<List<EventModel>> getUserRegisteredEvents(String userId) {
    return SupabaseDatabaseService.getEventsStream().map((dataList) {
      debugPrint('🔄 Processing events stream for user $userId, total events: ${dataList.length}');
      
      final userEvents = dataList
          .where((data) {
            final participants = _parseStringList(data['registered_participants']);
            final isRegistered = participants.contains(userId);
            if (isRegistered) {
              debugPrint('✅ User registered for event: ${data['title']}');
            }
            return isRegistered;
          })
          .map((data) {
            try {
              return EventModel.fromMap(_convertSupabaseToModel(data));
            } catch (e) {
              debugPrint('❌ Error parsing event ${data['id']}: $e');
              return null;
            }
          })
          .where((event) => event != null)
          .cast<EventModel>()
          .toList();
      
      debugPrint('📊 User registered events count: ${userEvents.length}');
      return userEvents;
    });
  }

  // Get user's volunteer events
  Stream<List<EventModel>> getUserVolunteerEvents(String userId) {
    return SupabaseDatabaseService.getEventsStream().map((dataList) {
      debugPrint('🔄 Processing volunteer events stream for user $userId, total events: ${dataList.length}');
      
      final userEvents = dataList
          .where((data) {
            final volunteers = _parseStringList(data['volunteers']);
            final isVolunteering = volunteers.contains(userId);
            if (isVolunteering) {
              debugPrint('✅ User volunteering for event: ${data['title']}');
            }
            return isVolunteering;
          })
          .map((data) {
            try {
              return EventModel.fromMap(_convertSupabaseToModel(data));
            } catch (e) {
              debugPrint('❌ Error parsing event ${data['id']}: $e');
              return null;
            }
          })
          .where((event) => event != null)
          .cast<EventModel>()
          .toList();
      
      debugPrint('📊 User volunteer events count: ${userEvents.length}');
      return userEvents;
    });
  }

  // Helper method to safely parse string lists from database
  List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    
    if (data is List) {
      return List<String>.from(data.map((e) => e.toString()));
    }
    
    if (data is String) {
      // Handle JSON string or comma-separated string
      if (data.trim().isEmpty) return [];
      
      // Try parsing as JSON array first
      if (data.startsWith('[') && data.endsWith(']')) {
        try {
          // Remove brackets and split by comma
          final content = data.substring(1, data.length - 1);
          if (content.trim().isEmpty) return [];
          
          final items = content.split(',');
          return items.map((e) => e.trim().replaceAll('"', '').replaceAll("'", "")).where((e) => e.isNotEmpty).toList();
        } catch (e) {
          // Fallback to simple split
        }
      }
      
      // Fallback: split by comma
      return data.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    
    return [];
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
      'maxParticipants': _parseInt(data['max_participants']),
      'registeredParticipants': _parseStringList(data['registered_participants']),
      'volunteers': _parseStringList(data['volunteers']),
      'requiresVolunteers': _parseBool(data['requires_volunteers']),
      'maxVolunteers': _parseInt(data['max_volunteers']),
      'imageUrl': data['image_url'],
      'isPublic': _parseBool(data['is_public']),
      'category': data['category'],
      'allowedRoles': _parseStringList(data['allowed_roles']),
      'createdAt': data['created_at'],
      'updatedAt': data['updated_at'],
    };
  }

  // Helper method to safely parse integers from database
  int _parseInt(dynamic data) {
    if (data == null) return 0;
    if (data is int) return data;
    if (data is String) return int.tryParse(data) ?? 0;
    return 0;
  }

  // Helper method to safely parse booleans from database
  bool _parseBool(dynamic data) {
    if (data == null) return false;
    if (data is bool) return data;
    if (data is String) {
      final str = data.toLowerCase().trim();
      return str == 'true' || str == '1' || str == 'yes';
    }
    if (data is int) return data != 0;
    return false;
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
      'allowed_roles': data['allowedRoles'],
      'created_at': data['createdAt'],
      'updated_at': data['updatedAt'],
    };
  }
}
