import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class SupabaseDatabaseService {
  static SupabaseClient? get _client => SupabaseService.client;

  // Users table operations
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    if (_client == null) return null;
    try {
      final response = await _client!
          .from('users')
          .select()
          .eq('uid', uid)
          .single();
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  static Future<void> createUser(Map<String, dynamic> userData) async {
    if (_client == null) throw Exception('Supabase not initialized');
    try {
      await _client!.from('users').insert(userData);
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  static Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    if (_client == null) throw Exception('Supabase not initialized');
    try {
      await _client!.from('users').update(updates).eq('uid', uid);
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  // Events table operations
  static Stream<List<Map<String, dynamic>>> getEventsStream({
    bool? isPublic,
    String? category,
    bool upcomingOnly = false,
  }) {
    if (_client == null) {
      return Stream.value([]);
    }

    try {
      var query = _client!.from('events').select();

      // Build the query with all conditions
      var finalQuery = _client!.from('events').select();
      
      if (isPublic != null) {
        finalQuery = finalQuery.eq('is_public', isPublic);
      }

      if (category != null) {
        finalQuery = finalQuery.eq('category', category);
      }

      if (upcomingOnly) {
        finalQuery = finalQuery.gt('start_date', DateTime.now().toIso8601String());
      }

      // Apply ordering and return the stream
      return finalQuery
          .order('start_date')
          .stream(primaryKey: ['id'])
          .map((data) => List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error getting events stream: $e');
      return Stream.value([]);
    }
  }

  static Future<List<Map<String, dynamic>>> getEvents({
    bool? isPublic,
    String? category,
    bool upcomingOnly = false,
  }) async {
    if (_client == null) return [];
    try {
      var query = _client!.from('events').select();

      if (isPublic != null) {
        query = query.eq('is_public', isPublic);
      }

      if (category != null) {
        query = query.eq('category', category);
      }

      if (upcomingOnly) {
        query = query.gt('start_date', DateTime.now().toIso8601String());
      }

      final orderedQuery = query.order('start_date');

      final response = await orderedQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting events: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getEvent(String eventId) async {
    if (_client == null) return null;
    try {
      final response = await _client!
          .from('events')
          .select()
          .eq('id', eventId)
          .single();
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting event: $e');
      return null;
    }
  }

  static Future<String> createEvent(Map<String, dynamic> eventData) async {
    if (_client == null) throw Exception('Supabase not initialized');
    try {
      final response = await _client!.from('events').insert(eventData).select().single();
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating event: $e');
      rethrow;
    }
  }

  static Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    if (_client == null) throw Exception('Supabase not initialized');
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _client!.from('events').update(updates).eq('id', eventId);
    } catch (e) {
      debugPrint('Error updating event: $e');
      rethrow;
    }
  }

  static Future<void> deleteEvent(String eventId) async {
    if (_client == null) throw Exception('Supabase not initialized');
    try {
      await _client!.from('events').delete().eq('id', eventId);
    } catch (e) {
      debugPrint('Error deleting event: $e');
      rethrow;
    }
  }

  // Announcements table operations
  static Future<List<Map<String, dynamic>>> getAnnouncements({
    bool? isPublic,
    String? targetAudience,
  }) async {
    if (_client == null) return [];
    try {
      var query = _client!.from('announcements').select();

      if (isPublic != null) {
        query = query.eq('is_public', isPublic);
      }

      if (targetAudience != null) {
        query = query.eq('target_audience', targetAudience);
      }

      final orderedQuery = query.order('created_at', ascending: false);

      final response = await orderedQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting announcements: $e');
      return [];
    }
  }

  static Future<String> createAnnouncement(Map<String, dynamic> announcementData) async {
    if (_client == null) throw Exception('Supabase not initialized');
    try {
      final response = await _client!
          .from('announcements')
          .insert(announcementData)
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating announcement: $e');
      rethrow;
    }
  }

  // Resources table operations
  static Future<List<Map<String, dynamic>>> getResources({
    String? category,
    String? subject,
    String? course,
  }) async {
    if (_client == null) return [];
    try {
      var query = _client!.from('resources').select();

      if (category != null) {
        query = query.eq('category', category);
      }

      if (subject != null) {
        query = query.eq('subject', subject);
      }

      if (course != null) {
        query = query.eq('course', course);
      }

      final orderedQuery = query.order('uploaded_at', ascending: false);

      final response = await orderedQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting resources: $e');
      return [];
    }
  }

  static Future<String> createResource(Map<String, dynamic> resourceData) async {
    if (_client == null) throw Exception('Supabase not initialized');
    try {
      final response = await _client!
          .from('resources')
          .insert(resourceData)
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating resource: $e');
      rethrow;
    }
  }

  // Achievements table operations
  static Future<List<Map<String, dynamic>>> getAchievements({String? studentId}) async {
    if (_client == null) return [];
    try {
      var query = _client!.from('achievements').select();

      if (studentId != null) {
        query = query.eq('student_id', studentId);
      }

      final orderedQuery = query.order('awarded_at', ascending: false);

      final response = await orderedQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return [];
    }
  }

  static Future<String> createAchievement(Map<String, dynamic> achievementData) async {
    if (_client == null) throw Exception('Supabase not initialized');
    try {
      final response = await _client!
          .from('achievements')
          .insert(achievementData)
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating achievement: $e');
      rethrow;
    }
  }

  // Careers table operations
  static Future<List<Map<String, dynamic>>> getCareers({
    String? type,
    bool? isActive,
  }) async {
    if (_client == null) return [];
    try {
      var query = _client!.from('careers').select();

      if (type != null) {
        query = query.eq('type', type);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final orderedQuery = query.order('posted_at', ascending: false);

      final response = await orderedQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting careers: $e');
      return [];
    }
  }

  static Future<String> createCareer(Map<String, dynamic> careerData) async {
    if (_client == null) throw Exception('Supabase not initialized');
    try {
      final response = await _client!
          .from('careers')
          .insert(careerData)
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating career: $e');
      rethrow;
    }
  }
}

