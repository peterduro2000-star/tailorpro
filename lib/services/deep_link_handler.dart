import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();

  factory DeepLinkHandler() {
    return _instance;
  }

  DeepLinkHandler._internal();

  late AppLinks _appLinks;
  StreamSubscription? _deepLinkSubscription;

  void initialize() {
    _appLinks = AppLinks();
    _listenToDeepLinks();
  }

  void _listenToDeepLinks() {
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('Deep link received: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    final isSupabaseCallback =
        uri.host.contains('supabase.co') && uri.path.contains('/auth/v1/callback');
    final isAppRedirect = uri.scheme == 'tailorpro' && uri.host == 'login-callback';

    if (isSupabaseCallback || isAppRedirect) {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        print('Exchanging code for session');
        _exchangeCodeForSession(code);
      }
    }
  }

  Future<void> _exchangeCodeForSession(String code) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Exchange the code for a session
      await supabase.auth.exchangeCodeForSession(code);
      
      print('✅ Session established from deep link');
    } catch (e) {
      print('❌ Failed to exchange code for session: $e');
    }
  }

  void dispose() {
    _deepLinkSubscription?.cancel();
  }
}
