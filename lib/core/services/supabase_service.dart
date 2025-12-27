import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    try {
      // Check if configuration is valid
      if (!SupabaseConfig.isConfigured) {
        debugPrint('⚠️ Supabase not configured. Please update lib/core/config/supabase_config.dart');
        debugPrint('   Supabase is optional - app will work without it for basic features.');
        debugPrint('   File storage features will be disabled.');
        return;
      }

      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      debugPrint('❌ Supabase initialization error: $e');
      debugPrint('   App will continue without Supabase (file storage disabled)');
      _isInitialized = false;
    }
  }

  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!_isInitialized || _client == null) {
      debugPrint('⚠️ Supabase not initialized. File storage features are disabled.');
      return null;
    }
    return _client;
  }

  static bool get isAvailable => _isInitialized && _client != null;

  // Storage methods
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    String? contentType,
  }) async {
    if (!isAvailable) {
      throw Exception('Supabase not initialized. Please configure Supabase credentials.');
    }

    try {
      final response = await _client!.storage.from(bucket).uploadBinary(
        path,
        Uint8List.fromList(fileBytes),
        fileOptions: FileOptions(
          contentType: contentType ?? 'application/octet-stream',
          upsert: true,
        ),
      );

      if (response.isEmpty) {
        final publicUrl = _client!.storage.from(bucket).getPublicUrl(path);
        return publicUrl;
      }
      
      throw Exception('Failed to upload file');
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  static Future<String> getPublicUrl(String bucket, String path) async {
    if (!isAvailable) {
      throw Exception('Supabase not initialized.');
    }
    return _client!.storage.from(bucket).getPublicUrl(path);
  }

  static Future<void> deleteFile(String bucket, String path) async {
    if (!isAvailable) {
      throw Exception('Supabase not initialized.');
    }
    await _client!.storage.from(bucket).remove([path]);
  }
}

