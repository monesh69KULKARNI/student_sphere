import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/firebase_service.dart';
import 'core/services/supabase_service.dart';
import 'core/providers/auth_provider.dart';
import 'screens/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase → ONLY authentication
  await FirebaseService.initialize();

  // Supabase → database & storage
  await SupabaseService.initialize();

  runApp(const StudentSphereApp());
}

class StudentSphereApp extends StatelessWidget {
  const StudentSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ///  IMPORTANT: NO initialize(), NO manual auth setup here
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'StudentSphere',
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ),

          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        /// 🚀 AuthWrapper controls navigation
        home: const AuthWrapper(),
      ),
    );
  }
}
