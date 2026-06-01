import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../models/payment_model.dart';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/payment_repository.dart';
import '../../../repositories/order_repository.dart';

class RecordPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> customer;
  final List<Order> customerOrders;
  final Payment? paymentToEdit;

  const RecordPaymentDialog({
    super.key,
    required this.customer,
    required this.customerOrders,
    this.paymentToEdit,
  });

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final PaymentRepository _paymentRepository = PaymentRepository();
  final OrderRepository _orderRepository = OrderRepository();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Order? _selectedOrder;
  String _selectedMethod = Payment.methodCash;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // If editing, populate fields
    if (widget.paymentToEdit != null) {
      _amountController.text = widget.paymentToEdit!.amount.toString();
      _notesController.text = widget.paymentToEdit!.notes ?? '';
      _selectedMethod = widget.paymentToEdit!.paymentMethod;
      _selectedDate = widget.paymentToEdit!.paymentDate;

      // Find the order
      _selectedOrder = widget.customerOrders.firstWhere(
        (o) => o.id == widget.paymentToEdit!.orderId,
        orElse: () => widget.customerOrders.first,
      );
    } else if (widget.customerOrders.isNotEmpty) {
      _selectedOrder = widget.customerOrders.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final amount = double.parse(_amountController.text);

      // Check for overpayment
      final currentPaidAmount = _selectedOrder!.paidAmount;
      final currentPaymentAmount = widget.paymentToEdit?.amount ?? 0.0;
      final newPaidAmount = currentPaidAmount - currentPaymentAmount + amount;

      if (newPaidAmount > _selectedOrder!.totalAmount) {
        final overpayment = newPaidAmount - _selectedOrder!.totalAmount;

        // Show overpayment warning
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Overpayment Detected'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Order Total: ₦${_selectedOrder!.totalAmount.toStringAsFixed(0)}'),
                Text(
                    'Currently Paid: ₦${currentPaidAmount.toStringAsFixed(0)}'),
                Text('This Payment: ₦${amount.toStringAsFixed(0)}'),
                const Divider(),
                Text(
                  'New Total: ₦${newPaidAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Overpayment: ₦${overpayment.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                    'The customer will have a credit balance. Continue?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Save Anyway'),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      // Create or update payment
      final payment = Payment(
        id: widget.paymentToEdit?.id,
        orderId: _selectedOrder!.id!,
        customerId: widget.customer['id'],
        amount: amount,
        paymentMethod: _selectedMethod,
        paymentDate: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final authProvider = context.read<AuthProvider>();

      if (widget.paymentToEdit == null) {
        // Creating new payment
        final savedPayment = await _paymentRepository.createPayment(payment);

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

        // Update order's paid_amount
        final updatedOrder = _selectedOrder!.copyWith(
          paidAmount: newPaidAmount,
        );
        await _orderRepository.updateOrder(updatedOrder);
      } else {
        // Updating existing payment
        await _paymentRepository.updatePayment(payment);

        if (authProvider.isAuthenticated) {
          try {
            await authProvider.cloudSync.savePaymentToCloud(
              payment,
              authProvider.currentUserId!,
            );
          } catch (e) {
            debugPrint('WARNING: Payment cloud sync failed: $e');
          }
        }

        // Update order's paid_amount: subtract old payment, add new payment
        final oldPaymentAmount = widget.paymentToEdit?.amount ?? 0.0;
        final newPaymentAmount = amount;
        final updatedOrder = _selectedOrder!.copyWith(
          paidAmount:
              _selectedOrder!.paidAmount - oldPaymentAmount + newPaymentAmount,
        );
        await _orderRepository.updateOrder(updatedOrder);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.paymentToEdit == null
                  ? 'Payment recorded successfully!'
                  : 'Payment updated successfully!',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.customerOrders.isEmpty) {
      return AlertDialog(
        title: const Text('No Orders'),
        content: const Text(
            'This customer has no orders yet. Create an order first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(
        widget.paymentToEdit == null ? 'Record Payment' : 'Edit Payment',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order selection
              Text(
                'Select Order',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              DropdownButtonFormField<Order>(
                value: _selectedOrder,
                isExpanded: true,
                itemHeight: 64,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  helperText: _selectedOrder == null
                      ? null
                      : 'Balance: ₦${_selectedOrder!.balance.toStringAsFixed(0)}',
                  helperStyle: theme.textTheme.bodySmall?.copyWith(
                    color: (_selectedOrder?.balance ?? 0) > 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
                selectedItemBuilder: (context) {
                  return widget.customerOrders.map((order) {
                    return Text(
                      '${order.orderNumber} - ${order.orderTitle}',
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }).toList();
                },
                items: widget.customerOrders.map((order) {
                  return DropdownMenuItem(
                    value: order,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.orderNumber} - ${order.orderTitle}',
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Balance: ₦${order.balance.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: order.balance > 0
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedOrder = value;
                  });
                },
              ),

              SizedBox(height: 2.h),

              // Amount
              Text(
                'Amount',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '₦',
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid amount';
                  if (double.parse(value) <= 0) {
                    return 'Must be greater than 0';
                  }
                  return null;
                },
              ),

              SizedBox(height: 2.h),

              // Payment method
              Text(
                'Payment Method',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Cash'),
                      value: Payment.methodCash,
                      groupValue: _selectedMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Transfer'),
                      value: Payment.methodTransfer,
                      groupValue: _selectedMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Payment date
              Text(
                'Payment Date',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 20, color: theme.colorScheme.primary),
                      SizedBox(width: 2.w),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down,
                          color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // Notes
              Text(
                'Notes (Optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g., Initial deposit, Final payment',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.all(3.w),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _savePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : Text(widget.paymentToEdit == null
                  ? 'Save Payment'
                  : 'Update Payment'),
        ),
      ],
    );
  }
}
