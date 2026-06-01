import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';

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

  Future<void> _initializeApp() async {
    try {
      setState(() => _initializationStatus = 'Checking permissions...');
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _initializationStatus = 'Setting up database...');
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() => _initializationStatus = 'Loading customer records...');
      await Future.delayed(const Duration(milliseconds: 700));

      setState(() => _initializationStatus = 'Preparing templates...');
      await Future.delayed(const Duration(milliseconds: 500));

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _isInitializing = false);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true)
          .pushReplacementNamed('/customer-list');
    } catch (e) {
      setState(() {
        _initializationStatus = 'Initialization failed';
        _isInitializing = false;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showErrorDialog();
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Error'),
        content: const Text(
          'Failed to initialize the application. Please try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
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

              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(4.w),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'content_cut', // scissors icon
                          color: theme.colorScheme.primary,
                          size: 15.w,
                        ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    Text(
                      'TailorPro',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 1.h),

                    Text(
                      'Your Business, Simplified',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              if (_isInitializing)
                Column(
                  children: [
                    SizedBox(
                      width: 10.w,
                      height: 10.w,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _initializationStatus,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 4.h),

              Text(
                'Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.6),
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