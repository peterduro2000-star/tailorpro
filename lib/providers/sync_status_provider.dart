import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central, app-wide synchronization state.
///
/// This is intentionally decoupled from any screen and from the actual sync
/// machinery (which lives in [AuthProvider] / the cloud sync services). Screens
/// and widgets only read this provider to render an accurate status; the sync
/// orchestrator reports transitions back into it.
enum SyncStatus {
  /// Device is online and the last cloud sync succeeded (or is up to date).
  online,

  /// No network connectivity is available.
  offline,

  /// A cloud synchronization is currently in progress.
  syncing,

  /// The last cloud synchronization attempt failed.
  failed,
}

class SyncStatusProvider extends ChangeNotifier {
  static const String _kLastSync = 'last_successful_sync';

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  SyncStatus _status = SyncStatus.online;
  DateTime? _lastSuccessfulSync;

  SyncStatusProvider({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  SyncStatus get status => _status;

  /// The timestamp of the last *successful* cloud synchronization with Supabase.
  ///
  /// `null` means a real sync has never completed (e.g. fresh install, or the
  /// app has never contacted Supabase).
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;

  bool get isOffline => _status == SyncStatus.offline;
  bool get isSyncing => _status == SyncStatus.syncing;
  bool get isFailed => _status == SyncStatus.failed;
  bool get isOnline => _status == SyncStatus.online;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kLastSync);
    if (stored != null) {
      _lastSuccessfulSync = DateTime.tryParse(stored);
    }

    // Establish initial connectivity state, then listen for changes.
    _applyConnectivity(await _connectivity.checkConnectivity());

    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    notifyListeners();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _applyConnectivity(results);
  }

  void _applyConnectivity(List<ConnectivityResult> results) {
    final hasConnection =
        results.any((r) => r != ConnectivityResult.none);

    if (!hasConnection) {
      // No network is unambiguous — we are offline.
      _setStatus(SyncStatus.offline);
      return;
    }

    // Reconnected. Only clear the offline state; do not silently override a
    // transient `syncing` or an explicit `failed` (which requires a retry).
    if (_status == SyncStatus.offline) {
      _setStatus(SyncStatus.online);
    }
  }

  /// Called by the sync orchestrator just before a cloud sync begins.
  void markSyncing() {
    _setStatus(SyncStatus.syncing);
  }

  /// Called by the sync orchestrator after a successful cloud sync.
  ///
  /// Persists the timestamp so "Last synced X ago" survives app restarts.
  Future<void> markSuccess() async {
    _lastSuccessfulSync = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastSync, _lastSuccessfulSync!.toIso8601String());
    } catch (_) {
      // Persistence is best-effort; in-memory state is the source of truth.
    }
    _setStatus(SyncStatus.online);
  }

  /// Called by the sync orchestrator when a cloud sync throws.
  void markFailed() {
    _setStatus(SyncStatus.failed);
  }

  void _setStatus(SyncStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
