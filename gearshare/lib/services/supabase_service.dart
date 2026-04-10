import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://nhataoydgtqovvznijrx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oYXRhb3lkZ3Rxb3Z2em5panJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MjQzMTQsImV4cCI6MjA5MTMwMDMxNH0.0jsJsdCOLxVciiYxB6cehdtQCPAC78DFzGGpU5RzpwM';

  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Sign Up - with proper user data persistence
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Register user with Supabase Auth and include metadata
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
      );

      // The user record should be created automatically by a PostgreSQL trigger
      // If the trigger doesn't work, manually insert the user data
      if (response.user != null) {
        try {
          // Try to insert user data (in case trigger fails)
          await client.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'name': name,
            'phone': phone,
          });
        } catch (e) {
          // If insert fails (e.g., due to trigger already creating it), ignore
          print('User data insert note: ${e.toString()}');
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get Current User
  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  // Get User Data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Stream Auth State Changes
  Stream<AuthState> authStateChanges() {
    return client.auth.onAuthStateChange;
  }
}
