import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/payment_repository.dart';
import '../../models/order_model.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import './widgets/customer_selection_widget.dart';
import './widgets/fabric_selection_widget.dart';
import './widgets/measurement_selection_widget.dart';
import './widgets/order_summary_widget.dart';
import './widgets/pricing_section_widget.dart';
import './widgets/style_selection_widget.dart';

class CreateOrder extends StatefulWidget {
  const CreateOrder({super.key});

  @override
  State<CreateOrder> createState() => _CreateOrderState();
}

class _CreateOrderState extends State<CreateOrder> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Inject the Repository
  final OrderRepository _orderRepository = OrderRepository();
  final CustomerRepository _customerRepository = CustomerRepository();

  // Order data state
  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _selectedMeasurement;
  Map<String, dynamic>? _selectedFabric;
  Map<String, dynamic>? _selectedStyle;
  bool _didReadRouteArgs = false;
  bool _hasPresetCustomer = false;
  bool _isLoadingCustomer = false;

  // Controllers for pricing
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _advancePaymentController =
      TextEditingController();
  double _totalAmount = 0.0;
  double _advancePayment = 0.0;
  String? _pricingError;

  List<String> get _stepTitles => _hasPresetCustomer
      ? [
          'Measurements',
          'Fabric',
          'Style',
          'Pricing',
        ]
      : [
          'Customer',
          'Measurements',
          'Fabric',
          'Style',
          'Pricing',
        ];

  int get _lastStepIndex => _stepTitles.length - 1;

  int get _pricingStepIndex => _hasPresetCustomer ? 3 : 4;

  int _logicalStep(int step) => _hasPresetCustomer ? step + 1 : step;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didReadRouteArgs) return;
    _didReadRouteArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final customerId = args['customerId'] ?? args['id'];
      if (customerId != null) {
        _selectedCustomer = args['id'] == null
            ? {
                ...args,
                'id': customerId,
              }
            : args;
        _hasPresetCustomer = true;
      }
    } else if (args is int) {
      _loadPresetCustomer(args);
    }
  }

  Future<void> _loadPresetCustomer(int customerId) async {
    setState(() => _isLoadingCustomer = true);
    final customer = await _customerRepository.getCustomerById(customerId);
    if (!mounted) return;
    setState(() {
      _selectedCustomer = customer?.toDisplayMap() ?? {'id': customerId};
      _hasPresetCustomer = true;
      _isLoadingCustomer = false;
    });
  }

  int _pageForSummaryStep(int summaryStep) {
    if (!_hasPresetCustomer) return summaryStep;
    return summaryStep <= 0 ? 0 : summaryStep - 1;
  }

  void _goToSummaryStep(int summaryStep) {
    final page = _pageForSummaryStep(summaryStep);
    setState(() {
      _currentStep = page;
    });
    _pageController.jumpToPage(page);
  }

  List<Widget> _buildStepPages() {
    return [
      if (!_hasPresetCustomer)
        CustomerSelectionWidget(
          selectedCustomer: _selectedCustomer,
          onCustomerSelected: (customer) {
            setState(() {
              _selectedCustomer = customer;
            });
          },
        ),
      MeasurementSelectionWidget(
        customer: _selectedCustomer,
        selectedMeasurement: _selectedMeasurement,
        onMeasurementSelected: (measurement) {
          setState(() {
            _selectedMeasurement = measurement;
          });
        },
      ),
      FabricSelectionWidget(
        selectedFabric: _selectedFabric,
        onFabricSelected: (fabric) {
          setState(() {
            _selectedFabric = fabric;
          });
        },
      ),
      StyleSelectionWidget(
        selectedStyle: _selectedStyle,
        onStyleSelected: (style) {
          setState(() {
            _selectedStyle = style;
          });
        },
      ),
      SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: PricingSectionWidget(
          totalAmountController: _totalAmountController,
          advancePaymentController: _advancePaymentController,
          pricingError: _pricingError,
          currentBalance: _totalAmount - _advancePayment,
          onCalculate: _calculateBalance,
        ),
      ),
    ];
  }

  Widget _buildLoadingCustomer(ThemeData theme) {
    return Center(
      child: CircularProgressIndicator(
        color: theme.colorScheme.primary,
      ),
    );
  }

  bool get _canProceed {
    switch (_logicalStep(_currentStep)) {
      case 0:
        return _selectedCustomer != null;
      case 1:
        return _selectedMeasurement != null;
      case 2:
        return _selectedFabric != null;
      case 3:
        return _selectedStyle != null;
      case 4:
        return _isPricingValid;
      default:
        return false;
    }
  }

  bool get _isPricingValid {
    if (_totalAmount <= 0) return false;
    if (_advancePayment < 0) return false;
    if (_advancePayment > _totalAmount) return false;
    return _pricingError == null;
  }

  void _calculateBalance() {
    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
    final advancePayment =
        double.tryParse(_advancePaymentController.text) ?? 0.0;

    String? pricingError;
    if (_totalAmountController.text.isNotEmpty && totalAmount <= 0) {
      pricingError = 'Order total must be greater than zero.';
    } else if (advancePayment < 0) {
      pricingError = 'Initial deposit cannot be negative.';
    } else if (advancePayment > totalAmount && totalAmount > 0) {
      pricingError = 'Initial deposit cannot be more than the total amount.';
    }

    setState(() {
      _totalAmount = totalAmount;
      _advancePayment = advancePayment;
      _pricingError = pricingError;
    });
  }

  void _nextStep() {
    if (_canProceed && _currentStep < _lastStepIndex) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == _lastStepIndex && _canProceed) {
      _showOrderSummary();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showOrderSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderSummaryWidget(
        customer: _selectedCustomer!,
        measurement: _selectedMeasurement!,
        fabric: _selectedFabric!,
        style: _selectedStyle!,
        totalAmount: _totalAmount,
        advancePayment: _advancePayment,
        allowCustomerEdit: !_hasPresetCustomer,
        onEdit: (step) {
          Navigator.pop(context);
          _goToSummaryStep(step);
        },
        onConfirm: _createOrder,
      ),
    );
  }

  // UPDATED: Logic to actually save data using your repository
  Future<void> _createOrder() async {
    // Show a loading dialog so the user knows the DB is working
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authProvider = context.read<AuthProvider>();

      // 1. Construct the Order object from your state
      final newOrder = Order(
        customerId: _selectedCustomer!['id'],
        orderNumber: Order.generateOrderNumber(),
        orderTitle: (_selectedStyle?['name'] as String?) ?? 'Custom Outfit',
        measurementId: _selectedMeasurement!['id'],
        notes: "Fabric: ${_selectedFabric?['name'] ?? 'Standard'}",
        fabricDetails: _selectedFabric?['name'] as String?,
        fabricImagePath: _selectedFabric?['imagePath'] as String?,
        styleImagePath: _selectedStyle?['imagePath'] as String?,
        itemType: _selectedStyle?['category'] as String?,
        totalAmount: _totalAmount,
        paidAmount: _advancePayment,
        status: Order.statusPending,
        stage: Order.stagePending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deliveryDate: DateTime.now().add(const Duration(days: 14)),
      );

      // 2. Call the repository to insert into SQLite
      final createdOrder = await _orderRepository.createOrder(newOrder);

      // 2b. Sync order to cloud if logged in
      if (authProvider.isAuthenticated) {
        try {
          await authProvider.cloudSync.saveOrderToCloud(
            createdOrder,
            authProvider.currentUserId!,
          );
        } catch (e) {
          debugPrint('WARNING: Order cloud sync failed: $e');
        }
      }

      if (_advancePayment > 0) {
        final payment = Payment(
          orderId: createdOrder.id!,
          customerId: _selectedCustomer!['id'],
          amount: _advancePayment,
          paymentMethod: Payment.methodCash,
          paymentDate: DateTime.now(),
          notes: 'Initial deposit',
        );

        final savedPayment = await PaymentRepository().createPayment(payment);

        if (authProvider.isAuthenticated) {
          try {
            await authProvider.cloudSync.savePaymentToCloud(
              savedPayment,
              authProvider.currentUserId!,
            );
          } catch (e) {
            debugPrint('WARNING: Payment cloud sync failed: $e');
          }
        }
      }

      // 3. Success! Cleanup UI
      if (!mounted) return;
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      Navigator.pop(context); // Remove loading spinner
      Navigator.pop(context); // Remove BottomSheet

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order created and saved successfully!'),
          backgroundColor: Color(0xFF388E3C),
          duration: Duration(seconds: 2),
        ),
      );

      // 4. Redirect to Customer List
      Future.delayed(const Duration(milliseconds: 500), () {
        rootNavigator.pushReplacementNamed('/customer-list');
      });
    } catch (e) {
      // If something goes wrong with the DB, let the user know
      if (mounted) Navigator.pop(context); // Remove spinner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _totalAmountController.dispose();
    _advancePaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 2,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.appBarTheme.foregroundColor ??
                theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: _currentStep > 0
              ? _previousStep
              : () => Navigator.of(context).pop(),
        ),
        title: Text('Create Order', style: theme.appBarTheme.titleTextStyle),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushReplacementNamed('/customer-list');
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(theme),
          Expanded(
            child: _isLoadingCustomer
                ? _buildLoadingCustomer(theme)
                : PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _buildStepPages(),
                  ),
          ),
          _buildBottomButton(theme),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive || isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        border: Border.all(
                          color: isActive || isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? Center(
                              child: CustomIconWidget(
                                iconName: 'check',
                                color: theme.colorScheme.onPrimary,
                                size: 16,
                              ),
                            )
                          : Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    if (index < _stepTitles.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _stepTitles[index],
                  style: TextStyle(
                    color: isActive || isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.sp,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomButton(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton(
            onPressed: _canProceed ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canProceed
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: _canProceed ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _currentStep == _pricingStepIndex ? 'Review Order' : 'Next',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
