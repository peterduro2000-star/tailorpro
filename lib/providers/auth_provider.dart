import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';
import '../services/license_service.dart';
import '../models/license_model.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService authService;
  late final LicenseService licenseService;

  // --- Auth State ---
  User? _currentUser;
  Session? _currentSession;
  bool _isLoading = false;
  String? _error;
  String? _email;
  bool _otpSent = false;
  
  // --- License State ---
  License? _license;
  bool _licenseVerified = false;
  String? _licenseStatus;
  int _migratedRecordsCount = 0;
  
  // --- Prevent double initialization ---
  bool _initializingLicense = false;

  AuthProvider({required this.authService}) {
    licenseService = LicenseService(client: authService.client);
    _initializeAuthState();
  }

  // --- Getters ---
  User? get currentUser => _currentUser;
  Session? get currentSession => _currentSession;
  bool get isAuthenticated => _currentUser != null && _currentSession != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get email => _email;
  bool get otpSent => _otpSent;
  
  License? get license => _license;
  bool get licenseVerified => _licenseVerified;
  LicenseTier? get licenseTier => _license?.tier;
  String? get licenseStatus => _licenseStatus;
  int get remainingClients => _license?.remainingClients ?? 0;
  int get maxClients => _license?.tier.maxClients ?? 0;
  int get clientsUsed => _license?.clientsUsed ?? 0;
  int get migratedRecordsCount => _migratedRecordsCount;

  /// Initialize auth state and listen for login/logout
  void _initializeAuthState() {
    final session = authService.currentSession;
    final user = authService.currentUser;

    // If already logged in, initialize license (fire-and-forget)
    if (session != null && user != null) {
      _currentSession = session;
      _currentUser = user;
      _email = user.email;
      _initializeLicenseInBackground();
    }

    // Listen to auth state changes
    authService.authStateChanges.listen((event) {
      final newUser = event.session?.user;
      final changed = newUser?.id != _currentUser?.id;
      
      _currentUser = newUser;
      _currentSession = event.session;
      
      if (changed) {
        if (_currentUser != null) {
          _initializeLicenseInBackground();
        } else {
          // User logged out
          _license = null;
          _licenseVerified = false;
        }
        notifyListeners();
      }
    });
  }

  /// Initialize license in background without blocking UI (fire-and-forget)
  void _initializeLicenseInBackground() {
    if (_initializingLicense || _currentUser == null) return;
    
    _initializingLicense = true;

    // DON'T AWAIT - just fire it off
    licenseService.getLicense(_currentUser!.id).then((existingLicense) {
      if (existingLicense != null) {
        _license = existingLicense;
        _licenseVerified = existingLicense.isActive;
        _licenseStatus = 'Active - ${existingLicense.tier.displayName}';
        notifyListeners();
        _initializingLicense = false;
        return;
      }

      // No license - create Free Tier
      licenseService.createFreeTierLicense(_currentUser!.id).then((newLicense) {
        _license = newLicense;
        _licenseVerified = newLicense != null;
        if (newLicense != null) {
          _licenseStatus = 'Active - ${newLicense.tier.displayName}';
        }
        notifyListeners();
        _initializingLicense = false;
      }).catchError((e) {
        _error = 'Failed to create license: $e';
        _licenseVerified = false;
        notifyListeners();
        _initializingLicense = false;
      });
    }).catchError((e) {
      _error = 'Failed to fetch license: $e';
      _licenseVerified = false;
      notifyListeners();
      _initializingLicense = false;
    });
  }

  /// Called by main.dart - doesn't block
  Future<void> checkLicenseKey() async {
    _initializeLicenseInBackground();
  }

  /// Step 1: Request OTP/Magic Link
  Future<void> requestOTP(String email) async {
    _clearError();
    _isLoading = true;
    _email = email;
    notifyListeners();

    try {
      await authService.sendOTP(email);
      _otpSent = true;
      _error = null;
    } catch (e) {
      _otpSent = false;
      final errString = e.toString();
      _error = errString.contains('429') ? "Too many requests. Wait 60 seconds." : errString;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Step 2: Verify OTP
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
        _error = null;
        
        // Initialize license in background (don't wait)
        _initializeLicenseInBackground();
        
        notifyListeners();
        return true;
      } else {
        _error = 'Verification failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Step 3: Migrate local data
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
      await authService.recordDataMigration(_currentUser!.id, localRecords.length);
      
      _error = null;
    } catch (e) {
      _error = 'Migration failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Activate a paid license key
  Future<bool> activateLicenseKey(String licenseKey) async {
    if (_currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      _license = await licenseService.activateLicenseKey(_currentUser!.id, licenseKey);
      
      if (_license != null) {
        _licenseVerified = true;
        _licenseStatus = 'Activated - ${_license!.tier.displayName}';
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to activate license';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Check if user can add more clients
  Future<bool> canAddMoreClients() async {
    if (_currentUser == null) return false;
    return await licenseService.canAddMoreClients(_currentUser!.id);
  }

  /// Track client addition
  Future<void> recordClientAddition() async {
    if (_currentUser == null) return;
    try {
      await licenseService.incrementClientCount(_currentUser!.id);
      _license = await licenseService.getLicense(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Track client deletion
  Future<void> recordClientDeletion() async {
    if (_currentUser == null) return;
    try {
      await licenseService.decrementClientCount(_currentUser!.id);
      _license = await licenseService.getLicense(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      await authService.signOut();
      _currentUser = null;
      _currentSession = null;
      _email = null;
      _otpSent = false;
      _license = null;
      _licenseVerified = false;
      _licenseStatus = null;
      _migratedRecordsCount = 0;
      _initializingLicense = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}