import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/license_model.dart';
import '../../presentation/purchase/purchase_screen.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  final Future<List<Map<String, dynamic>>> Function() getLocalData;
  final int initialStep;

  const AuthScreen({
    Key? key,
    required this.onAuthSuccess,
    required this.getLocalData,
    this.initialStep = 0,
  }) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _obscurePassword = true;
  Timer? _otpCountdownTimer;
  int _otpCountdown = 0;

  String get _otpCode =>
      _otpControllers.map((controller) => controller.text).join();

  bool get _isOtpComplete =>
      _otpControllers.every((controller) => controller.text.length == 1);

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, 3);
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    _otpCountdownTimer?.cancel();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _currentStep++;
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _startOtpCountdown() {
    _otpCountdownTimer?.cancel();
    setState(() {
      _otpCountdown = 30;
    });

    _otpCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_otpCountdown <= 1) {
        timer.cancel();
        setState(() {
          _otpCountdown = 0;
        });
      } else {
        setState(() {
          _otpCountdown--;
        });
      }
    });
  }

  Future<void> _resendOtp(AuthProvider authProvider) async {
    if (_emailController.text.isEmpty || _otpCountdown > 0) return;

    await authProvider.requestOTP(_emailController.text);
    if (authProvider.otpSent && mounted) {
      _startOtpCountdown();
    }
  }

  String _maskedEmail(String? email) {
    final value = (email ?? _emailController.text).trim();
    final atIndex = value.indexOf('@');
    if (atIndex <= 0) return value;

    final local = value.substring(0, atIndex);
    final domain = value.substring(atIndex);
    final visiblePrefix = local.length <= 2 ? local : local.substring(0, 2);
    return '$visiblePrefix****$domain';
  }

  void _handleOtpChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 1) {
      _fillOtpFromPaste(digits);
      return;
    }

    if (digits.isEmpty) {
      if (_otpControllers[index].text.isNotEmpty) {
        _otpControllers[index].clear();
      }
      setState(() {});
      return;
    }

    if (_otpControllers[index].text != digits) {
      _otpControllers[index].value = TextEditingValue(
        text: digits,
        selection: const TextSelection.collapsed(offset: 1),
      );
    }

    if (index < _otpFocusNodes.length - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    } else {
      _otpFocusNodes[index].unfocus();
    }
    setState(() {});
  }

  void _fillOtpFromPaste(String digits) {
    final code = digits.substring(0, digits.length.clamp(0, 6).toInt());
    for (var i = 0; i < _otpControllers.length; i++) {
      final digit = i < code.length ? code[i] : '';
      _otpControllers[i].value = TextEditingValue(
        text: digit,
        selection: TextSelection.collapsed(offset: digit.length),
      );
    }

    final focusIndex = code.length >= 6 ? 5 : code.length;
    _otpFocusNodes[focusIndex].requestFocus();
    if (code.length >= 6) {
      _otpFocusNodes[focusIndex].unfocus();
    }
    setState(() {});
  }

  KeyEventResult _handleOtpKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }

    if (_otpControllers[index].text.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].clear();
      setState(() {});
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentStep = index),
        children: [
          _buildEmailStep(context),
          _buildOTPStep(context),
          _buildMigrationStep(context),
          _buildLicenseStep(context),
        ],
      ),
    );
  }

  /// Step 1: Email input
  Widget _buildEmailStep(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) => Scaffold(
        appBar: AppBar(title: const Text('Get Started'), elevation: 0),
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Get Started',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Enter your email to receive a verification code',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !authProvider.isLoading,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'your.email@example.com',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      errorText: authProvider.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'New users will be created automatically',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    enabled: !authProvider.isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password (optional)',
                      hintText: 'Enter password if you have one',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              if (_emailController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Enter email address')));
                                return;
                              }
                              await authProvider
                                  .requestOTP(_emailController.text);
                              if (authProvider.otpSent && mounted) {
                                _startOtpCountdown();
                                _nextStep();
                              }
                            },
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Continue'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              if (_emailController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Enter email address')));
                                return;
                              }
                              if (_passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Enter password')));
                                return;
                              }
                              final signedIn =
                                  await authProvider.signInWithPassword(
                                _emailController.text,
                                _passwordController.text,
                              );
                              if (signedIn && mounted) _nextStep();
                            },
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Sign in with Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Step 2: OTP verification
  Widget _buildOTPStep(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          appBar: AppBar(title: const Text('Verify Email'), elevation: 0),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Verify Your Email',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter the 6-digit code sent to ${_maskedEmail(authProvider.email)}',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          _otpControllers.length,
                          (index) => SizedBox(
                            width: 48,
                            child: Focus(
                              onKeyEvent: (_, event) =>
                                  _handleOtpKey(index, event),
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _otpFocusNodes[index],
                                keyboardType: TextInputType.number,
                                textInputAction: index == 5
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                                enabled: !authProvider.isLoading,
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  counterText: '',
                                  errorText: null,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (value) =>
                                    _handleOtpChanged(index, value),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (authProvider.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          authProvider.error!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          onPressed: authProvider.isLoading || !_isOtpComplete
                              ? null
                              : () async {
                                  final verified =
                                      await authProvider.verifyOTP(_otpCode);
                                  if (verified && mounted) _nextStep();
                                },
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Verify Code'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _otpCountdown > 0
                          ? Text(
                              'Resend code in ${_otpCountdown}s',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "Didn't receive the code? ",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                TextButton(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : () => _resendOtp(authProvider),
                                  style: TextButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Resend'),
                                ),
                              ],
                            ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed:
                            authProvider.isLoading ? null : _previousStep,
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Step 3: Migrate local data
  Widget _buildMigrationStep(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) => Scaffold(
        appBar: AppBar(title: const Text('Backup Data'), elevation: 0),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload, size: 48, color: Colors.blue),
              const SizedBox(height: 24),
              const Text('Backup Your Data',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Move your clients and measurements to the cloud',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200)),
                child: Row(
                  children: [
                    Icon(
                        authProvider.migratedRecordsCount > 0
                            ? Icons.check_circle
                            : Icons.info,
                        color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              authProvider.migratedRecordsCount > 0
                                  ? 'Migration Complete'
                                  : 'Ready to backup',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          if (authProvider.migratedRecordsCount > 0)
                            Text(
                                '${authProvider.migratedRecordsCount} records backed up',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ||
                          authProvider.migratedRecordsCount > 0
                      ? null
                      : () async {
                          final localData = await widget.getLocalData();
                          if (mounted) {
                            await authProvider.migrateLocalData(localData);
                            if (mounted &&
                                authProvider.migratedRecordsCount > 0) {
                              await Future.delayed(const Duration(seconds: 1));
                              _nextStep();
                            }
                          }
                        },
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(authProvider.migratedRecordsCount > 0
                          ? 'Migrated ✓'
                          : 'Backup Now'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: authProvider.isLoading ? null : _nextStep,
                  child: const Text('Skip for now')),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 4: License - SIMPLIFIED (no double-initialization)
  Widget _buildLicenseStep(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final shouldShowUpgradeOptions = !authProvider.licenseVerified ||
            authProvider.licenseTier == LicenseTier.free;

        return Scaffold(
          appBar: AppBar(title: const Text('License'), elevation: 0),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  const Icon(Icons.lock, size: 48, color: Colors.blue),
                  const SizedBox(height: 24),
                  const Text('Choose Your Plan',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Select a license tier or continue with Free',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 32),
                  if (shouldShowUpgradeOptions) ...[
                    if (authProvider.licenseTier == LicenseTier.free) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Free Tier Active',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${authProvider.remainingClients} of ${authProvider.maxClients} customer spots left',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Only show Free tier for Phase 1
                    _buildTierCard(
                        context, 'Free', '₦0', 'Up to 5 clients', Colors.grey,
                        () {
                      widget.onAuthSuccess(); // Continue with free tier
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Upgrade with Google Play'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PurchaseScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Pro features coming soon!',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic)),
                  ] else ...[
                    // License already verified - show success
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200)),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 48),
                          const SizedBox(height: 12),
                          Text(
                              '${authProvider.licenseTier?.displayName ?? 'License'} Activated',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                              '${authProvider.remainingClients} spots available',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => widget.onAuthSuccess(),
                        child: const Text('Continue to Dashboard'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTierCard(BuildContext context, String title, String price,
      String description, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(price,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            Icon(Icons.arrow_forward, color: color),
          ],
        ),
      ),
    );
  }
}
