import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase Service - Only for Authentication
/// All database operations use Supabase
class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseMessaging get messaging => FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      
      // Request notification permissions
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      debugPrint('Please configure Firebase by:');
      debugPrint('1. Running: flutterfire configure');
      debugPrint('2. Or manually adding google-services.json from Firebase Console');
      rethrow;
    }
  }
}

