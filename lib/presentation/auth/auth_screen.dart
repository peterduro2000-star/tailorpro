import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/license_model.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  final Future<List<Map<String, dynamic>>> Function() getLocalData;

  const AuthScreen({
    Key? key,
    required this.onAuthSuccess,
    required this.getLocalData,
  }) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _licenseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3 && _pageController.hasClients) {
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0 && _pageController.hasClients) {
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
        appBar: AppBar(title: const Text('Sign In - Step 1/4'), elevation: 0),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 48, color: Colors.blue),
              const SizedBox(height: 24),
              const Text('Enter Your Email', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('We\'ll send a one-time code to verify', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !authProvider.isLoading,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'your.email@example.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  errorText: authProvider.error,
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
                              const SnackBar(content: Text('Enter email address')),
                            );
                            return;
                          }
                          await authProvider.requestOTP(_emailController.text);
                          if (mounted && authProvider.otpSent) {
                            _nextStep();
                          }
                        },
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 2: OTP verification
  Widget _buildOTPStep(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) => Scaffold(
        appBar: AppBar(title: const Text('Verify Code - Step 2/4'), elevation: 0),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.code, size: 48, color: Colors.blue),
              const SizedBox(height: 24),
              const Text('Enter Verification Code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Sent to ${authProvider.email}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                enabled: !authProvider.isLoading,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '000000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  errorText: authProvider.error,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_otpController.text.length != 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter 6-digit code')),
                            );
                            return;
                          }
                          final verified = await authProvider.verifyOTP(_otpController.text);
                          if (verified && mounted) _nextStep();
                        },
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: authProvider.isLoading ? null : _previousStep,
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 3: Migrate local data
  Widget _buildMigrationStep(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) => Scaffold(
        appBar: AppBar(title: const Text('Backup Data - Step 3/4'), elevation: 0),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload, size: 48, color: Colors.blue),
              const SizedBox(height: 24),
              const Text('Backup Your Data', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Move your clients and measurements to the cloud', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(authProvider.migratedRecordsCount > 0 ? Icons.check_circle : Icons.info, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.migratedRecordsCount > 0 ? 'Migration Complete' : 'Ready to backup',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (authProvider.migratedRecordsCount > 0)
                            Text(
                              '${authProvider.migratedRecordsCount} records backed up',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
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
                  onPressed: authProvider.isLoading || authProvider.migratedRecordsCount > 0
                      ? null
                      : () async {
                          final localData = await widget.getLocalData();
                          if (mounted) {
                            await authProvider.migrateLocalData(localData);
                            if (mounted && authProvider.migratedRecordsCount > 0) {
                              await Future.delayed(const Duration(seconds: 1));
                              _nextStep();
                            }
                          }
                        },
                  child: authProvider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(authProvider.migratedRecordsCount > 0 ? 'Migrated ✓' : 'Backup Now'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: authProvider.isLoading ? null : _nextStep,
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 4: License - with loading state
  Widget _buildLicenseStep(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) => Scaffold(
        appBar: AppBar(title: const Text('License - Step 4/4'), elevation: 0),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.lock, size: 48, color: Colors.blue),
                const SizedBox(height: 24),
                const Text('Choose Your Plan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Select a license tier or continue with Free', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 32),

                // LOADING STATE: Show spinner while license initializes
                if (authProvider.license == null) ...[
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text('Setting up your license...', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),
                ] else if (!authProvider.licenseVerified) ...[
                  // Show tier cards
                  _buildTierCard(context, 'Free', '₦0', 'Up to 5 clients', Colors.grey, () {
                    widget.onAuthSuccess();
                  }),
                  const SizedBox(height: 12),
                  _buildTierCard(context, 'Basic', '₦3,000', 'Up to 50 clients', Colors.blue, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter your license key below')),
                    );
                  }),
                  const SizedBox(height: 12),
                  _buildTierCard(context, 'Professional', '₦6,000', 'Up to 500 clients', Colors.purple, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter your license key below')),
                    );
                  }),
                  const SizedBox(height: 12),
                  _buildTierCard(context, 'Monthly', '₦500/month', 'Up to 50 clients (30 days)', Colors.orange, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter your license key below')),
                    );
                  }),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Have a license key?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _licenseController,
                    enabled: !authProvider.isLoading,
                    decoration: InputDecoration(
                      labelText: 'License Key',
                      hintText: 'TP-XX-XXXXXXXX-XXXXXXXXXX-XXXXXXXX',
                      prefixIcon: const Icon(Icons.vpn_key),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      errorText: authProvider.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              if (_licenseController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enter a license key')),
                                );
                                return;
                              }
                              final success = await authProvider.activateLicenseKey(_licenseController.text);
                              if (success && mounted) {
                                widget.onAuthSuccess();
                              }
                            },
                      child: authProvider.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Activate Key'),
                    ),
                  ),
                ] else ...[
                  // License already verified - show success
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          '${authProvider.licenseTier?.displayName ?? "License"} Activated',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${authProvider.remainingClients} spots available',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
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
      ),
    );
  }

  Widget _buildTierCard(BuildContext context, String title, String price, String description, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(price, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            Icon(Icons.arrow_forward, color: color),
          ],
        ),
      ),
    );
  }
}