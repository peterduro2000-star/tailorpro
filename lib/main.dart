import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sizer/sizer.dart';
import 'models/license_model.dart';
import 'presentation/auth/auth_screen.dart';
import 'presentation/dashboard/dashboard.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_routes.dart';
import 'services/supabase_auth_service.dart';
import 'services/deep_link_handler.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  final supabaseAuthService =
      SupabaseAuthService(client: Supabase.instance.client);
  final deepLinkHandler = DeepLinkHandler();
  deepLinkHandler.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: supabaseAuthService),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: MyApp(deepLinkHandler: deepLinkHandler),
    ),
  );
}

class MyApp extends StatefulWidget {
  final DeepLinkHandler deepLinkHandler;

  const MyApp({required this.deepLinkHandler, super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _allowFreeTierDashboardInStaging = false;

  @override
  void dispose() {
    widget.deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        final themeProvider = context.watch<ThemeProvider>();

        return MaterialApp(
          title: 'TailorPro',
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (!auth.isAuthenticated) {
                return AuthScreen(
                  key: const ValueKey('auth_screen'),
                  onAuthSuccess: () {
                    _allowFreeTierDashboardInStaging = false;
                  },
                  getLocalData: () async => [],
                );
              }

              // For free app: authenticated users can access dashboard immediately
              // License system runs in background for future monetization
              return const Dashboard(
                key: ValueKey('dashboard_screen'),
              );
            },
          ),
        );
      },
    );
  }
}

class _LicenseLoadingScreen extends StatefulWidget {
  final AuthProvider auth;

  const _LicenseLoadingScreen({required this.auth});

  @override
  State<_LicenseLoadingScreen> createState() => _LicenseLoadingScreenState();
}

class _LicenseLoadingScreenState extends State<_LicenseLoadingScreen> {
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _startLicenseInitialization();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.auth.addListener(_authListener);
  }

  void _authListener() {
    if (widget.auth.licenseVerified && mounted) {
      setState(() {});
    }
  }

  void _startLicenseInitialization() {
    // Timeout after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !widget.auth.licenseVerified) {
        setState(() {
          _timedOut = true;
        });
      }
    });
  }

  @override
  void dispose() {
    widget.auth.removeListener(_authListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_timedOut) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading license...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'License check is taking too long',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _timedOut = false;
                });
                _startLicenseInitialization();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
