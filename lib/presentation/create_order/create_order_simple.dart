@deprecated
// ⚠️ LEGACY TEST SCREEN
// Kept temporarily for reference
// Do NOT use for new features
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../models/payment_model.dart';
import '../../repositories/payment_repository.dart';
import '../../core/app_export.dart';
import '../../models/order_model.dart';
import '../../models/measurement_model.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/measurement_repository.dart';
import '../../widgets/custom_icon_widget.dart';

class CreateOrderSimple extends StatefulWidget {
  const CreateOrderSimple({super.key});

  @override
  State<CreateOrderSimple> createState() => _CreateOrderSimpleState();
}

class _CreateOrderSimpleState extends State<CreateOrderSimple> {
  final _formKey = GlobalKey<FormState>();
  final OrderRepository _orderRepository = OrderRepository();
  final MeasurementRepository _measurementRepository = MeasurementRepository();

  Map<String, dynamic>? _customerData;
  List<Measurement> _measurements = [];
  
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedStatus = Order.statusPending;
  String? _selectedItemType;
  int _quantity = 1;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  Measurement? _selectedMeasurement;
  bool _isLoading = true;

  final List<String> _itemTypes = [
    'Shirt',
    'Trouser',
    'Dress/Gown',
    'Agbada',
    'Kaftan',
    'Senator',
    'Native Wear',
    'Suit',
    'Jacket',
    'Skirt',
    'Blouse',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args != null && args is Map<String, dynamic>) {
      setState(() {
        _customerData = args;
      });
      
      // Load measurements for this customer
      if (args['id'] != null) {
        final measurements = await _measurementRepository.getCustomerMeasurements(args['id']);
        setState(() {
          _measurements = measurements;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveOrder() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (_customerData == null || _customerData!['id'] == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer data not found'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    debugPrint('Creating order for customer: ${_customerData!['id']}');
    
    final totalAmount = double.parse(_totalAmountController.text);
    final paidAmount = _paidAmountController.text.isEmpty 
        ? 0.0 
        : double.parse(_paidAmountController.text);
    
    final order = Order(
      customerId: _customerData!['id'],
      orderNumber: Order.generateOrderNumber(),
      orderTitle: _selectedItemType ?? 'Order',
      status: _selectedStatus,
      stage: Order.stagePending,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      deliveryDate: _dueDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      measurementId: _selectedMeasurement?.id,
      itemType: _selectedItemType,
      quantity: _quantity,
    );

    debugPrint('Order object created, attempting to save...');
    
    final savedOrder = await _orderRepository.createOrder(order);
    
    debugPrint('Order saved successfully with ID: ${savedOrder.id}');

    // CREATE PAYMENT RECORD IF DEPOSIT WAS PAID
    if (paidAmount > 0) {
      final payment = Payment(
        orderId: savedOrder.id!,
        customerId: _customerData!['id'],
        amount: paidAmount,
        paymentMethod: Payment.methodCash, // Default to cash, user can edit later
        paymentDate: DateTime.now(),
        notes: 'Initial deposit',
      );
      
      await PaymentRepository().createPayment(payment);
      debugPrint('Initial deposit payment record created: ₦$paidAmount');
    }

    if (mounted) {
      Navigator.of(context).pop(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${savedOrder.orderNumber} created successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e, stackTrace) {
    debugPrint('Error creating order: $e');
    debugPrint('Stack trace: $stackTrace');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Order')),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Order', style: theme.appBarTheme.titleTextStyle),
            if (_customerData != null)
              Text(
                _customerData!['name'] ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.appBarTheme.foregroundColor?.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Type
              Text(
                'Item Type *',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              DropdownButtonFormField<String>(
                value: _selectedItemType,
                decoration: InputDecoration(
                  hintText: 'Select item type',
                  prefixIcon: Icon(Icons.checkroom, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _itemTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedItemType = value;
                  });
                },
                validator: (value) => value == null ? 'Required' : null,
              ),

              SizedBox(height: 2.h),

              // Measurement (optional)
              if (_measurements.isNotEmpty) ...[
                Text(
                  'Use Measurement (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                DropdownButtonFormField<Measurement>(
                  value: _selectedMeasurement,
                  decoration: InputDecoration(
                    hintText: 'Select measurement',
                    prefixIcon: Icon(Icons.straighten, color: theme.colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: _measurements.map((m) {
                    final date = '${m.createdAt.day}/${m.createdAt.month}/${m.createdAt.year}';
                    return DropdownMenuItem(
                      value: m,
                      child: Text('${m.measurementType} - $date'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMeasurement = value;
                    });
                  },
                ),
                SizedBox(height: 2.h),
              ],

              // Quantity
              Text(
                'Quantity *',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: theme.colorScheme.primary,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _quantity.toString(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Total Amount
              Text(
                'Total Amount *',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _totalAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter total amount',
                  prefixText: '₦',
                  prefixIcon: Icon(Icons.payments, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),

              SizedBox(height: 2.h),

              // Paid Amount
              Text(
                'Paid Amount (Deposit)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter amount paid',
                  prefixText: '₦',
                  prefixIcon: Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) return 'Invalid amount';
                  }
                  return null;
                },
              ),

              SizedBox(height: 2.h),

              // Due Date
              Text(
                'Due Date *',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                      SizedBox(width: 3.w),
                      Text(
                        '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // Status
              Text(
                'Initial Status',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.flag, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: Order.allStatuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(Order.getStatusDisplay(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),

              SizedBox(height: 2.h),

              // Notes
              Text(
                'Notes (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add any special requirements or notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: _saveOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Create Order',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}