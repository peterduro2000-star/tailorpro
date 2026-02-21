import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/database_helper.dart';
import '../../widgets/custom_icon_widget.dart';

/// Splash Screen for TailorPro application
/// Provides branded app launch experience while initializing core services
/// Displays app logo with fade-in animation during database initialization
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitializing = true;
  String _initializationStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeApp();
  }

  /// Setup fade-in animation for logo
  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  /// Initialize core app services
  Future<void> _initializeApp() async {
    try {
      // Update status: Initializing database
      setState(() {
        _initializationStatus = 'Setting up database...';
      });
      
      // Actually initialize the database
      await DatabaseHelper.instance.database;
      await Future.delayed(const Duration(milliseconds: 500));

      // Update status: Loading data
      setState(() {
        _initializationStatus = 'Loading customer records...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // Update status: Preparing templates
      setState(() {
        _initializationStatus = 'Preparing measurement templates...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // Ensure minimum splash display time (total ~2-3 seconds)
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isInitializing = false;
      });

      // Navigate to Customer List screen
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      // Handle initialization errors
      setState(() {
        _initializationStatus = 'Initialization failed';
        _isInitializing = false;
      });

      // Show error dialog after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  /// Show error dialog for initialization failures
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Text(
          'Failed to initialize the application.\n\nError: $error\n\nPlease check storage permissions and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isInitializing = true;
                _initializationStatus = 'Retrying...';
              });
              _initializeApp();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // App Logo with fade-in animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Logo Icon
                    Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(4.w),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'content_cut',
                          color: theme.colorScheme.primary,
                          size: 15.w,
                        ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // App Name
                    Text(
                      'TailorPro',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),

                    SizedBox(height: 1.h),

                    // Tagline
                    Text(
                      'Your Business, Simplified',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.9,
                        ),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Loading Indicator and Status
              if (_isInitializing)
                Column(
                  children: [
                    // Loading Indicator
                    SizedBox(
                      width: 10.w,
                      height: 10.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Initialization Status
                    Text(
                      _initializationStatus,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

              SizedBox(height: 4.h),

              // Version Info
              Text(
                'Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                ),
              ),

              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
}