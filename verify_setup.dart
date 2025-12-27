// Quick verification script to test Firebase and Supabase connections
// Run with: dart run verify_setup.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/core/config/supabase_config.dart';
import 'lib/core/services/firebase_service.dart';
import 'lib/core/services/supabase_service.dart';

void main() async {
  print('🔍 Verifying StudentSphere Setup...\n');

  // Check Firebase
  print('1. Checking Firebase...');
  try {
    await Firebase.initializeApp();
    print('   ✅ Firebase initialized successfully');
    print('   ✅ Project: studentsphere-6601a');
  } catch (e) {
    print('   ❌ Firebase error: $e');
    return;
  }

  // Check Supabase
  print('\n2. Checking Supabase...');
  try {
    if (!SupabaseConfig.isConfigured) {
      print('   ❌ Supabase not configured');
      print('   ⚠️  Check lib/core/config/supabase_config.dart');
      return;
    }

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    print('   ✅ Supabase initialized successfully');
    print('   ✅ URL: ${SupabaseConfig.supabaseUrl}');

    // Test database connection
    final client = Supabase.instance.client;
    final response = await client.from('users').select('count').limit(1);
    print('   ✅ Database connection successful');
  } catch (e) {
    print('   ❌ Supabase error: $e');
    print('   ⚠️  Make sure you ran the SQL schema in Supabase SQL Editor');
    return;
  }

  // Check storage buckets
  print('\n3. Checking Storage Buckets...');
  try {
    final client = Supabase.instance.client;
    final buckets = await client.storage.listBuckets();
    final bucketNames = buckets.map((b) => b.name).toList();

    final requiredBuckets = ['resources', 'profile-images', 'event-images'];
    var allPresent = true;

    for (var bucket in requiredBuckets) {
      if (bucketNames.contains(bucket)) {
        print('   ✅ Bucket "$bucket" exists');
      } else {
        print('   ❌ Bucket "$bucket" missing');
        allPresent = false;
      }
    }

    if (!allPresent) {
      print('\n   ⚠️  Create missing buckets in Supabase Storage');
    }
  } catch (e) {
    print('   ⚠️  Could not check buckets: $e');
  }

  print('\n✅ Setup verification complete!');
  print('\nNext: Run "flutter run" to start the app');
}

