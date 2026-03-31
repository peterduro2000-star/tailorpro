import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/auth/auth_screen.dart';
import 'presentation/dashboard/dashboard.dart';
import 'providers/auth_provider.dart';
import 'services/supabase_auth_service.dart';
import 'services/deep_link_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yvwzentsmwwgcxmkdwjt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2d3plbnRzbXd3Z2N4bWtkd2p0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2NzMyNTMsImV4cCI6MjA5MDI0OTI1M30.h1VPqAUKkebAH2bmElbsZAntITUKXAlA6CFoPWT9fJg',
  );

  final supabaseAuthService = SupabaseAuthService(client: Supabase.instance.client);
  final deepLinkHandler = DeepLinkHandler();
  deepLinkHandler.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(authService: supabaseAuthService),
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
  @override
  void dispose() {
    widget.deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TailorPro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // We use a Navigator or a simple conditional, but with a unique Key
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // If loading the very first time, show a splash or progress
          if (auth.isLoading && !auth.otpSent && auth.currentUser == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (auth.licenseVerified) {
            return const Dashboard(key: ValueKey('dashboard_screen'));
          } else {
            return AuthScreen(
              key: const ValueKey('auth_screen'),
              onAuthSuccess: () {
                // We call this, but the Consumer above will handle the actual switch
                auth.checkLicenseKey();
              },
              getLocalData: () async {
                return []; // Add your SQLite logic here later
              },
            );
          }
        },
      ),
    );
  }
}