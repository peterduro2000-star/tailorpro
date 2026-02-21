import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../repositories/order_repository.dart';
import '../../models/order_model.dart';
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

  // Order data state
  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _selectedMeasurement;
  Map<String, dynamic>? _selectedFabric;
  Map<String, dynamic>? _selectedStyle;

  // Controllers for pricing
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  double _totalAmount = 0.0;
  double _advancePayment = 0.0;

  final List<String> _stepTitles = [
    'Customer',
    'Measurements',
    'Fabric',
    'Style',
    'Pricing',
  ];

  @override
  void initState() {
    super.initState();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedCustomer != null;
      case 1:
        return _selectedMeasurement != null;
      case 2:
        return _selectedFabric != null;
      case 3:
        return _selectedStyle != null;
      case 4:
        return _totalAmount > 0;
      default:
        return false;
    }
  }

  void _calculateBalance() {
    setState(() {
      _totalAmount = double.tryParse(_totalPriceController.text) ?? 0.0;
      _advancePayment = double.tryParse(_depositController.text) ?? 0.0;
    });
  }

  void _nextStep() {
    if (_canProceed && _currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 4 && _canProceed) {
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
        onEdit: (step) {
          Navigator.pop(context);
          setState(() {
            _currentStep = step;
          });
          _pageController.jumpToPage(step);
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
      // 1. Construct the Order object from your state
      // Note: Assuming your Order model uses these field names
      final newOrder = Order(
        customerId: _selectedCustomer!['id'],
        measurementId: _selectedMeasurement!['id'],
        notes: "Fabric: ${_selectedFabric?['name'] ?? 'Standard'}",
        styleDetails: _selectedStyle!,
        totalAmount: _totalAmount,
        paidAmount: _advancePayment,
        status: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 14)), // Default 2 weeks
      );

      // 2. Call the repository to insert into SQLite
      await _orderRepository.createOrder(newOrder);

      // 3. Success! Cleanup UI
      if (!mounted) return;
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
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/customer-list');
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
    _totalPriceController.dispose();
    _depositController.dispose();
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
            color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
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
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
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
                PricingSectionWidget(
                  totalPriceController: _totalPriceController,
                  depositController: _depositController,
                  onCalculate: _calculateBalance,
                ),
              ],
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
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
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
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
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
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
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
              _currentStep == 4 ? 'Review Order' : 'Next',
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