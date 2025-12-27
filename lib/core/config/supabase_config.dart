/// Supabase Configuration
/// 
/// Replace these values with your actual Supabase project credentials.
/// You can find these in your Supabase project settings:
/// https://app.supabase.com/project/YOUR_PROJECT/settings/api
class SupabaseConfig {
  // Your Supabase project URL
  // Format: https://YOUR_PROJECT_REF.supabase.co
  static const String supabaseUrl = 'https://dqeahphtfvqiqaprkwmi.supabase.co';
  
  // Your Supabase anon/public key
  // This is safe to use in client-side code
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZWFocGh0ZnZxaXFhcHJrd21pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY4MjAzODYsImV4cCI6MjA4MjM5NjM4Nn0.4npyF_q-rEp8OZXrfSyA--jM-RTOgkiVaj3itwFF4oo';
  
  // Storage bucket names (create these in Supabase Storage)
  static const String bucketResources = 'resources';
  static const String bucketProfileImages = 'profile-images';
  static const String bucketEventImages = 'event-images';
  
  // Check if configuration is valid
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL' &&
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
           !supabaseUrl.contains('YOUR_') &&
           !supabaseAnonKey.contains('YOUR_');
  }
}

