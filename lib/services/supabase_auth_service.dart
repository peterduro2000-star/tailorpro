import 'package:supabase_flutter/supabase_flutter.dart';

/// Optional local UI state wrapper (safe to keep)
class LocalAuthState {
  final User? user;
  final Session? session;
  final bool isLoading;
  final String? error;

  LocalAuthState({
    this.user,
    this.session,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && session != null;

  LocalAuthState copyWith({
    User? user,
    Session? session,
    bool? isLoading,
    String? error,
  }) {
    return LocalAuthState(
      user: user ?? this.user,
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SupabaseAuthService {
  final SupabaseClient client;

  SupabaseAuthService({required this.client});

  // ─────────────────────────────────────────────
  // OTP LOGIN
  // ─────────────────────────────────────────────

  /// Send OTP to email address
  Future<void> sendOTP(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      await client.auth.signInWithOtp(
        email: normalizedEmail,
        shouldCreateUser: true,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verify OTP and return session
  Future<Session?> verifyOTP(String email, String otp) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final response = await client.auth.verifyOTP(
        email: normalizedEmail,
        token: otp,
        type: OtpType.email,
      );

      return response.session;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  /// Sign in with email and password.
  Future<Session?> signInWithPassword(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final response = await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      return response.session;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Password sign-in failed: $e');
    }
  }

  // ─────────────────────────────────────────────
  // AUTH HELPERS
  // ─────────────────────────────────────────────

  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;

  bool get isAuthenticated =>
      currentUser != null && currentSession != null;

  // ─────────────────────────────────────────────
  // LICENSE MANAGEMENT
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getLicenseKeyStatus(String userId) async {
    try {
      final response = await client
          .from('user_licenses')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (_) {
      return null;
    }
  }

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

  // ─────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // ─────────────────────────────────────────────
  // AUTH STREAM
  // ─────────────────────────────────────────────

  Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
