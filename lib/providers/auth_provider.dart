import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_auth_service.dart';
import '../services/license_service.dart';
import '../services/license_persistence_service.dart';
import '../services/license_verification_service.dart';
import '../services/license_manager.dart';
import '../services/database_helper.dart';
import '../services/cloud_sync_service.dart';
import '../services/data_sync_service.dart';
import '../providers/sync_status_provider.dart';
import '../models/license_model.dart';

/// Central provider managing authentication state, license state, and
/// background sync for TailorPro.
///
/// Lifecycle:
///   1. App start  → [_initialize] restores an existing session if present.
///   2. OTP login  → [verifyOTP] creates a fresh, user-scoped service set.
///   3. Sign out   → all user data cleared; services torn down.
///   4. User switch→ [requestOTP] detects the change, clears the previous
///                   user's data, then the new session rebuilds everything.
class AuthProvider extends ChangeNotifier {
  // ─── Injected ────────────────────────────────────────────────────────────────
  final SupabaseAuthService authService;
  final SyncStatusProvider syncStatus;

  // Persistence keys for pending OTP flow
  static const String _kPendingEmail = 'pending_auth_email';
  static const String _kPendingTimestamp = 'pending_auth_timestamp';

  // ─── User-scoped services (recreated on every login) ─────────────────────────
  LicenseService? _licenseService;
  LicensePersistenceService? _persistenceService;
  LicenseVerificationService? _verificationService;
  LicenseManager? _licenseManager;
  CloudSyncService? _cloudSyncService;
  DataSyncService? _dataSyncService;

  // ─── Auth state ───────────────────────────────────────────────────────────────
  User? _currentUser;
  Session? _currentSession;
  bool _isLoading = false;
  String? _error;
  String? _email;
  bool _otpSent = false;

  // ─── License state ────────────────────────────────────────────────────────────
  License? _license;
  bool _licenseVerified = false;
  bool _licenseInitialized = false;
  bool _initializingLicense = false;
  String? _licenseStatus;
  bool _isInGracePeriod = false;
  int _daysInGracePeriod = 0;

  // ─── Sync state ───────────────────────────────────────────────────────────────
  bool _syncing = false;
  int _migratedRecordsCount = 0;

  // ─── Constructor ──────────────────────────────────────────────────────────────

  AuthProvider({
    required this.authService,
    required this.syncStatus,
  }) {
    _initialize();
  }

  // ─── Getters ──────────────────────────────────────────────────────────────────

  User? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.id;
  Session? get currentSession => _currentSession;
  bool get isAuthenticated => _currentUser != null && _currentSession != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get email => _email;
  bool get otpSent => _otpSent;
  bool get syncing => _syncing;

  License? get license => _license;
  bool get licenseVerified => _licenseVerified;
  bool get licenseInitialized => _licenseInitialized;
  LicenseTier? get licenseTier => _license?.tier;
  LicenseTier? get effectiveLicenseTier => _license?.effectiveTier;
  String? get licenseStatus => _licenseStatus;
  int get remainingClients =>
      _license?.canAddMoreClients ?? false ? _license!.remainingClients : 0;
  int get maxClients => _license?.tier.maxClients ?? LicenseTier.free.maxClients;
  int get clientsUsed => _license?.clientsUsed ?? 0;
  bool get isInGracePeriod => _isInGracePeriod;
  int get daysInGracePeriod => _daysInGracePeriod;
  
  // ─── Helper getters that delegate to LicenseManager (for backward compatibility) ─
  /// Current effective tier (may be free due to expiry).
  LicenseTier get effectiveTier => _license?.effectiveTier ?? LicenseTier.free;
  
  /// Maximum clients for current effective tier.
  int get activeMaxClients => effectiveTier.maxClients;
  
  /// True if user has premium access (not free tier).
  bool get hasPremiumAccess => effectiveTier != LicenseTier.free;
  String get licenseExpiryFormatted => _license?.expiryDateFormatted ?? 'N/A';
  int get migratedRecordsCount => _migratedRecordsCount;

  // Non-nullable getter for screens — safe to call only when authenticated.
  // Screens should always be behind an auth guard, so this will never throw
  // in normal use.
  CloudSyncService get cloudSync {
    assert(_cloudSyncService != null,
        'cloudSync accessed before user session was ready');
    return _cloudSyncService!;
  }

  // Nullable variant for optional/conditional access.
  CloudSyncService? get cloudSyncOrNull => _cloudSyncService;

  // LicenseManager getter — provides unified entitlement decisions.
  LicenseManager? get licenseManager => _licenseManager;

  // ─── Initialisation ───────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    final session = authService.currentSession;
    final user = authService.currentUser;

    // Restore pending OTP state if app was killed during login
    await _restorePendingAuth();

    if (session != null && user != null) {
      _currentSession = session;
      _currentUser = user;
      _email = user.email;
      await _onUserSessionReady(user);
    }

    // Listen for future auth events (token refresh, sign-out, user switch).
    authService.authStateChanges.listen(_onAuthStateChange);
  }

  Future<void> _onAuthStateChange(AuthState event) async {
    final newUser = event.session?.user;
    final userChanged = newUser?.id != _currentUser?.id;

    _currentUser = newUser;
    _currentSession = event.session;

    if (userChanged) {
      if (_currentUser != null) {
        await _onUserSessionReady(_currentUser!);
      } else {
        await _onUserSignedOut();
      }
      notifyListeners();
    }
  }

  /// Called whenever we have a confirmed, authenticated user.
  ///
  /// Builds the full user-scoped service graph, loads the cached license,
  /// starts background verification, and triggers a cloud sync.
  Future<void> _onUserSessionReady(User user) async {
    // 1. Build user-scoped services.
    await _buildScopedServices(user.id);

    // 2. Show cached license immediately (fast path for offline / returning users).
    _loadCachedLicense();

    // 3. Start server verification in the background.
    _verificationService!.startPeriodicVerification();

    // 4. Initialize license from server if not yet done.
    _initializeLicenseInBackground();

    // 5. Sync cloud → local.
    _triggerCloudSync(user.id);
  }

  /// Builds (or rebuilds) all services scoped to the given [userId].
  ///
  /// This is the single place where the user ID is injected — if it's called
  /// again for a different user, the old services are fully replaced.
  Future<void> _buildScopedServices(String userId) async {
    // Tear down old services first.
    _verificationService?.stopPeriodicVerification();

    final prefs = await SharedPreferences.getInstance();

    final licenseService = LicenseService(client: authService.client);
    final persistenceService = LicensePersistenceService(
      prefs: prefs,
      userId: userId,   // ← user-scoped keys; no data leakage between accounts
    );
    final verificationService = LicenseVerificationService(
      licenseService: licenseService,
      persistenceService: persistenceService,
    );
    final licenseManager = LicenseManager(
      verificationService: verificationService,
    );
    final cloudSyncService = CloudSyncService(
      client: authService.client,
      dbHelper: DatabaseHelper.instance,
    );
    final dataSyncService = DataSyncService(
      cloudSyncService: cloudSyncService,
      dbHelper: DatabaseHelper.instance,
    );

    _licenseService = licenseService;
    _persistenceService = persistenceService;
    _verificationService = verificationService;
    _licenseManager = licenseManager;
    _cloudSyncService = cloudSyncService;
    _dataSyncService = dataSyncService;

    // Reset license init flags for this user.
    _licenseInitialized = false;
    _initializingLicense = false;
  }

  // ─── License loading ──────────────────────────────────────────────────────────

  /// Synchronous fast-path: read whatever is already in the local cache.
  void _loadCachedLicense() {
    if (_persistenceService == null) return;
    final cached = _persistenceService!.loadLicense();
    if (cached != null) {
      _license = cached;
    }
    _updateLicenseState();
    notifyListeners();
  }

  /// Async slow-path: verify with server and persist the result.
  void _initializeLicenseInBackground() {
    if (_initializingLicense || _licenseInitialized) return;
    if (_licenseService == null || _persistenceService == null) return;

    _initializingLicense = true;

    _fetchOrCreateLicense().then((_) {
      _initializingLicense = false;
    });
  }

  Future<void> _fetchOrCreateLicense() async {
    try {
      License? license = await _licenseService!.getCurrentLicense();

      // First-time user — create a free tier record on the server.
      license ??= await _licenseService!.ensureFreeLicense();

      if (license != null) {
        _license = license;
        _licenseInitialized = true;
        await _persistenceService!.saveLicense(license);
        await _persistenceService!.saveVerificationDate(DateTime.now());
        await _persistenceService!.resetOfflineDayCount();
        _updateLicenseState();
        notifyListeners();
      }
    } catch (e) {
      // Server unreachable — cached license is already shown; nothing to do.
      // The 24-hour periodic check will retry automatically.
    }
  }

  void _updateLicenseState() {
    final lic = _license;
    if (lic == null) {
      _licenseVerified = false;
      _isInGracePeriod = false;
      _daysInGracePeriod = 0;
      _licenseStatus = null;
      return;
    }

    _licenseVerified = lic.isUsable;
    _isInGracePeriod = lic.isInGracePeriod;
    _daysInGracePeriod = lic.daysInGracePeriod;

    if (lic.isExpired && lic.isInGracePeriod) {
      _licenseStatus = 'Grace period — ${lic.daysInGracePeriod} day(s) left';
    } else if (lic.isExpired) {
      _licenseStatus = 'Expired — downgraded to Free';
    } else if (lic.expiresAt == null) {
      _licenseStatus = '${lic.tier.displayName} (lifetime)';
    } else {
      _licenseStatus = '${lic.tier.displayName} — expires ${lic.expiryDateFormatted}';
    }
  }

  /// Checks if there is a recent pending OTP request and restores it.
  Future<void> _restorePendingAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingEmail = prefs.getString(_kPendingEmail);
      final timestampStr = prefs.getString(_kPendingTimestamp);

      if (pendingEmail != null && timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        // Only restore if the OTP was requested in the last 15 minutes
        if (DateTime.now().difference(timestamp).inMinutes < 15) {
          _email = pendingEmail;
          _otpSent = true;
          notifyListeners();
        } else {
          await _clearPendingAuth();
        }
      }
    } catch (_) {
      // Fail silently, just means user has to re-enter email
    }
  }

  Future<void> _clearPendingAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingEmail);
    await prefs.remove(_kPendingTimestamp);
  }

  // ─── OTP flow ─────────────────────────────────────────────────────────────────

  Future<void> requestOTP(String email) async {
    _clearError();

    // Detect account switch.
    final currentUser = authService.currentUser;
    if (currentUser != null && currentUser.email != email) {
      await _handleAccountSwitch();
    }

    _isLoading = true;
    _email = email;
    notifyListeners();

    try {
      await authService.sendOTP(email);
      _otpSent = true;
      
      // Persist for process-death recovery
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPendingEmail, email);
      await prefs.setString(_kPendingTimestamp, DateTime.now().toIso8601String());
    } catch (e) {
      _otpSent = false;
      final msg = e.toString();
      _error = msg.contains('429')
          ? 'Too many requests. Please wait 60 seconds.'
          : msg;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String otp) async {
    if (_email == null) {
      _error = 'Email not set';
      notifyListeners();
      return false;
    }

    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final session = await authService.verifyOTP(_email!, otp);

      if (session != null) {
        _currentSession = session;
        _currentUser = session.user;
        _otpSent = false;
        await _clearPendingAuth();
        await _onUserSessionReady(session.user);
        notifyListeners();
        return true;
      }

      _error = 'Verification failed. Check the code and try again.';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithPassword(String email, String password) async {
    _clearError();

    final currentUser = authService.currentUser;
    if (currentUser != null && currentUser.email != email) {
      await _handleAccountSwitch();
    }

    _isLoading = true;
    _email = email;
    notifyListeners();

    try {
      final session = await authService.signInWithPassword(email, password);

      if (session != null) {
        _currentSession = session;
        _currentUser = session.user;
        _otpSent = false;
        await _onUserSessionReady(session.user);
        notifyListeners();
        return true;
      }

      _error = 'Sign in failed. Check the email and password.';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── License key activation ───────────────────────────────────────────────────

  Future<bool> activateLicenseKey(String licenseKey) async {
    if (_currentUser == null || _licenseService == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final license = await _licenseService!.activateLicenseKey(licenseKey);
      _license = license;
      _licenseInitialized = true;
      await _persistenceService!.saveLicense(license);
      await _persistenceService!.saveVerificationDate(DateTime.now());
      _updateLicenseState();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> activateIapPurchase({
    required String edgeFunctionUrl,
    required String purchaseToken,
    required String productId,
  }) async {
    if (_currentUser == null ||
        _licenseManager == null ||
        _persistenceService == null) {
      throw Exception('Not authenticated');
    }

    final license = await _licenseManager!.activateIapPurchase(
      edgeFunctionUrl: edgeFunctionUrl,
      purchaseToken: purchaseToken,
      productId: productId,
    );

    _license = license;
    _licenseInitialized = true;
    await _persistenceService!.saveLicense(license);
    await _persistenceService!.saveVerificationDate(DateTime.now());
    _updateLicenseState();
    notifyListeners();
  }

  Future<void> refreshLicense() async {
    if (_licenseService == null || _persistenceService == null) return;
    await _fetchOrCreateLicense();
  }

  // ─── Client count management ──────────────────────────────────────────────────

  /// Server-authoritative check — never rely on the local cache for this.
  Future<bool> canAddMoreClients() async {
    if (_licenseService != null) {
      try {
        return await _licenseService!.canAddMoreClients();
      } catch (_) {
        // If offline, fall back to cached value conservatively.
        return _license?.canAddMoreClients ?? false;
      }
    }

    return _license?.canAddMoreClients ?? false;
  }

  Future<void> recordClientAddition() async {
    if (_licenseService == null || _persistenceService == null) return;
    try {
      await _licenseService!.incrementClientCount();
      await _refreshLicenseFromServer();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> recordClientDeletion() async {
    if (_licenseService == null || _persistenceService == null) return;
    try {
      await _licenseService!.decrementClientCount();
      await _refreshLicenseFromServer();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch a fresh copy of the license from the server and update local state.
  Future<void> _refreshLicenseFromServer() async {
    final fresh = await _licenseService!.getCurrentLicense();
    if (fresh != null) {
      _license = fresh;
      await _persistenceService!.saveLicense(fresh);
      _updateLicenseState();
      notifyListeners();
    }
  }

  // ─── Data migration ───────────────────────────────────────────────────────────

  Future<void> migrateLocalData(List<Map<String, dynamic>> localRecords) async {
    if (_currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      for (final record in localRecords) {
        record['user_id'] = _currentUser!.id;
      }
      _migratedRecordsCount = localRecords.length;
      await authService.recordDataMigration(
          _currentUser!.id, localRecords.length);
    } catch (e) {
      _error = 'Migration failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Sign out ─────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      _verificationService?.stopPeriodicVerification();
      await authService.signOut();
      await _persistenceService?.clearLicense();
      await DatabaseHelper.instance.clearDatabase();
      _onUserSignedOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Cloud sync ───────────────────────────────────────────────────────────────

  void _triggerCloudSync(String userId) {
    if (_syncing || _dataSyncService == null) return;

    _syncing = true;
    syncStatus.markSyncing();
    notifyListeners();

    _dataSyncService!.syncCloudToLocal(userId).then((_) {
      _syncing = false;
      syncStatus.markSuccess();
      notifyListeners();
    }).catchError((_) {
      // Sync failure is non-fatal — app works offline.
      _syncing = false;
      syncStatus.markFailed();
      notifyListeners();
    });
  }

  /// Public entry point to (re)trigger a cloud → local synchronization,
  /// e.g. from a "Tap to retry" affordance. No-op when not authenticated or
  /// when a sync is already running.
  void startCloudSync() {
    if (_currentUser != null) {
      _triggerCloudSync(_currentUser!.id);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  /// Clear per-user data on logout without touching auth state.
  Future<void> _onUserSignedOut() async {
    _currentUser = null;
    _currentSession = null;
    _email = null;
    _otpSent = false;
    _license = null;
    _licenseVerified = false;
    _licenseInitialized = false;
    _initializingLicense = false;
    _licenseStatus = null;
    _isInGracePeriod = false;
    _daysInGracePeriod = 0;
    _migratedRecordsCount = 0;
    _syncing = false;
    _error = null;
  }

  /// Full teardown when a different account logs in on the same device.
  Future<void> _handleAccountSwitch() async {
    _verificationService?.stopPeriodicVerification();
    await authService.client.auth.signOut();

    // Clear the previous user's cached license using whatever persistence
    // service is currently mounted (still scoped to the old user).
    await _persistenceService?.clearLicense();
    await DatabaseHelper.instance.clearDatabase();

    await _onUserSignedOut();
  }

  void _clearError() => _error = null;

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _verificationService?.stopPeriodicVerification();
    super.dispose();
  }
}
