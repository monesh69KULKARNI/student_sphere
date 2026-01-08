import 'package:flutter/foundation.dart';
import '../models/announcement_model.dart';
import 'supabase_database_service.dart';
import 'auth_service.dart';

class AnnouncementService {
  static Future<List<AnnouncementModel>> getAnnouncements({
    bool? isPublic,
    String? targetAudience,
  }) async {
    try {
      print('🔍 AnnouncementService.getAnnouncements()');
      print('  isPublic: $isPublic');
      print('  targetAudience: $targetAudience');
      
      final data = await SupabaseDatabaseService.getAnnouncements(
        isPublic: isPublic,
        targetAudience: targetAudience,
      );
      
      print('  Raw data count: ${data.length}');
      
      final announcements = data.map((item) => AnnouncementModel.fromMap(item)).toList();
      
      print('  Mapped to ${announcements.length} AnnouncementModel objects');
      return announcements;
    } catch (e) {
      debugPrint('❌ Error fetching announcements: $e');
      return [];
    }
  }

  static Future<String> createAnnouncement({
    required String title,
    required String content,
    required String authorName,
    String? targetAudience,
    bool isPublic = true,
    String priority = 'medium',
    String? attachmentUrl,
  }) async {
    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      // Debug prints
      print('🔍 Announcement Service Debug:');
      print('  Current User: ${currentUser?.uid} (${currentUser?.role.value})');
      print('  Title: $title');
      print('  Is Public: $isPublic');
      print('  Priority: $priority');
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final announcementData = {
        'title': title,
        'content': content,
        'author_id': currentUser.uid,
        'author_name': authorName,
        'created_at': DateTime.now().toIso8601String(),
        'is_public': isPublic,
        'target_audience': targetAudience,
        'read_by': [],
        'priority': priority,
        'attachment_url': attachmentUrl,
      };

      print('📤 Sending data: $announcementData');
      final result = await SupabaseDatabaseService.createAnnouncement(announcementData);
      print('✅ Announcement created with ID: $result');
      
      return result;
    } catch (e) {
      debugPrint('❌ Error creating announcement: $e');
      rethrow;
    }
  }

  static Future<void> markAsRead(String announcementId) async {
    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // This would need to be implemented in the database service
      // For now, we'll just log it
      debugPrint('📝 Marking announcement $announcementId as read for user ${currentUser.uid}');
    } catch (e) {
      debugPrint('❌ Error marking announcement as read: $e');
    }
  }

  static Future<List<AnnouncementModel>> getUserAnnouncements() async {
    try {
      print('🔍 AnnouncementService.getUserAnnouncements()');
      
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      print('  Current user: ${currentUser?.uid} (${currentUser?.role.value})');
      
      if (currentUser == null) {
        print('  No current user, returning empty list');
        return [];
      }

      // Get all announcements and filter based on user role
      final allAnnouncements = await getAnnouncements();
      
      print('  Total announcements available: ${allAnnouncements.length}');
      
      final userAnnouncements = allAnnouncements.where((announcement) {
        // Show public announcements
        if (announcement.isPublic) {
          print('  ✅ Public announcement: ${announcement.title}');
          return true;
        }
        
        // Show targeted announcements based on user role
        if (announcement.targetAudience != null) {
          print('  ✅ Targeted announcement: ${announcement.title} (target: ${announcement.targetAudience})');
          return true; // For now, show all targeted announcements
        }
        
        print('  ❌ Filtered out: ${announcement.title} (not public, no target)');
        return false;
      }).toList();
      
      print('  Final user announcements count: ${userAnnouncements.length}');
      return userAnnouncements;
    } catch (e) {
      debugPrint('❌ Error fetching user announcements: $e');
      return [];
    }
  }
}
