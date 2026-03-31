import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SupabaseAuthService {
  final SupabaseClient client;

  SupabaseAuthService({required this.client});

  /// Send OTP to email address
  Future<void> sendOTP(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      await client.auth.signInWithOtp(
        email: normalizedEmail,
        shouldCreateUser: true,
        emailRedirectTo: 'tailorpro://login-callback',
      );
    } catch (e) {
      // Fallback for projects where the redirect URL is not yet allow-listed.
      final errorText = e.toString().toLowerCase();
      if (errorText.contains('redirect') || errorText.contains('not allowed')) {
        try {
          await client.auth.signInWithOtp(
            email: email.trim().toLowerCase(),
            shouldCreateUser: true,
          );
          return;
        } catch (_) {
          // Keep original error for clearer setup troubleshooting.
        }
      }
      throw Exception('Failed to send sign-in email: $e');
    }
  }

  /// Verify OTP and sign in user
  Future<Session?> verifyOTP(String email, String otp) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final response = await client.auth.verifyOTP(
        email: normalizedEmail,
        token: otp,
        type: OtpType.email,
      );
      return response.session;
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  /// Get current authenticated user
  User? get currentUser => client.auth.currentUser;

  /// Get current session
  Session? get currentSession => client.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get user's license key status
  Future<Map<String, dynamic>?> getLicenseKeyStatus(String userId) async {
    try {
      final response = await client
          .from('user_licenses')
          .select()
          .eq('user_id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Store/update license key for user
  Future<void> saveLicenseKey(String userId, String licenseKey) async {
    try {
      await client.from('user_licenses').upsert({
        'user_id': userId,
        'license_key': licenseKey,
        'activated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save license key: $e');
    }
  }

  /// Record local data migration timestamp
  Future<void> recordDataMigration(String userId, int recordCount) async {
    try {
      await client.from('user_migrations').insert({
        'user_id': userId,
        'migrated_records': recordCount,
        'migrated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to record migration: $e');
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Stream for auth state changes
  Stream<supabase.AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}

/// Standalone AuthState class
class AuthState {
  final User? user;
  final Session? session;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.session,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && session != null;

  AuthState copyWith({
    User? user,
    Session? session,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
