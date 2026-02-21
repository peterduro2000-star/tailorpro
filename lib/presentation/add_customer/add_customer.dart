import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/customer_model.dart';
import '../../repositories/customer_repository.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/gender_selector_widget.dart';
import './widgets/notes_input_widget.dart';
import './widgets/phone_input_widget.dart';

/// Add Customer screen for quick customer profile creation
/// Implements mobile-optimized form with inline validation
class AddCustomer extends StatefulWidget {
  const AddCustomer({super.key});

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final CustomerRepository _customerRepository = CustomerRepository();

  String? _selectedGender;
  String? _nameError;
  String? _phoneError;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  bool _isEditMode = false;
  Customer? _existingCustomer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if editing existing customer
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _isEditMode = true;
      _populateCustomerData(args);
    }
  }

  void _populateCustomerData(Map<String, dynamic> customerData) {
    _nameController.text = customerData['name'] ?? '';
    
    // Remove +234 prefix for display
    String phone = customerData['phone'] ?? '';
    if (phone.startsWith('+234')) {
      phone = '0${phone.substring(4)}';
    }
    _phoneController.text = phone;
    
    _selectedGender = customerData['gender'];
    _notesController.text = customerData['notes'] ?? '';
    
    // Store existing customer for update
    if (customerData['id'] != null) {
      _existingCustomer = Customer(
        id: customerData['id'],
        name: customerData['name'],
        phone: customerData['phone'],
        gender: customerData['gender'],
        email: customerData['email'],
        notes: customerData['notes'],
        createdAt: customerData['createdAt'] is DateTime 
            ? customerData['createdAt'] 
            : DateTime.now(),
        updatedAt: customerData['updatedAt'] is DateTime 
            ? customerData['updatedAt'] 
            : DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().length == 11 &&
        _selectedGender != null;
  }

  void _validateName(String value) {
    setState(() {
      _hasUnsavedChanges = true;
      if (value.trim().isEmpty) {
        _nameError = 'Name is required';
      } else if (value.trim().length < 2) {
        _nameError = 'Name must be at least 2 characters';
      } else {
        _nameError = null;
      }
    });
  }

  void _validatePhone(String value) {
    setState(() {
      _hasUnsavedChanges = true;
      if (value.trim().isEmpty) {
        _phoneError = 'Phone number is required';
      } else if (value.trim().length != 11) {
        _phoneError = 'Phone number must be 11 digits';
      } else if (!value.startsWith('0')) {
        _phoneError = 'Phone number must start with 0';
      } else {
        _phoneError = null;
      }
    });
  }

  void _onGenderSelected(String gender) {
    setState(() {
      _selectedGender = gender;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveCustomer() async {
    if (!_isFormValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String formattedPhone = '+234${_phoneController.text.substring(1)}';

      // Check if phone number already exists (for new customers or if phone changed)
      if (!_isEditMode || (_existingCustomer?.phone != formattedPhone)) {
        final exists = await _customerRepository.customerExists(formattedPhone);
        if (exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('A customer with this phone number already exists'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (_isEditMode && _existingCustomer != null) {
        // Update existing customer
        final updatedCustomer = _existingCustomer!.copyWith(
          name: _nameController.text.trim(),
          phone: formattedPhone,
          gender: _selectedGender!,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );
        
        await _customerRepository.updateCustomer(updatedCustomer);
        
        if (mounted) {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(true); // Return true to indicate success
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Customer "${_nameController.text.trim()}" updated successfully',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Create new customer
        final newCustomer = Customer(
          name: _nameController.text.trim(),
          phone: formattedPhone,
          gender: _selectedGender!,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        );

        await _customerRepository.createCustomer(newCustomer);

        if (mounted) {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(true); // Return true to indicate success
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Customer "${_nameController.text.trim()}" added successfully',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save customer: ${e.toString()}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Customer' : 'Add Customer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          elevation: 0,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 2.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          onChanged: _validateName,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter customer name',
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 3.w),
                              child: CustomIconWidget(
                                iconName: 'person',
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            errorText: _nameError,
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.colorScheme.error,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.colorScheme.error,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 2.h,
                            ),
                          ),
                        ),
                        SizedBox(height: 3.h),
                        PhoneInputWidget(
                          controller: _phoneController,
                          errorText: _phoneError,
                          onChanged: _validatePhone,
                        ),
                        SizedBox(height: 3.h),
                        GenderSelectorWidget(
                          selectedGender: _selectedGender,
                          onGenderSelected: _onGenderSelected,
                        ),
                        SizedBox(height: 3.h),
                        NotesInputWidget(
                          controller: _notesController,
                          onChanged: (value) {
                            setState(() {
                              _hasUnsavedChanges = true;
                            });
                          },
                        ),
                        SizedBox(height: 4.h),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 6.h,
                        child: ElevatedButton(
                          onPressed: _isFormValid && !_isLoading
                              ? _saveCustomer
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            disabledBackgroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.12),
                            disabledForegroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  _isEditMode ? 'Update Customer' : 'Save Customer',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SizedBox(
                        width: double.infinity,
                        height: 6.h,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final shouldPop = await _onWillPop();
                                  if (shouldPop && mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(
                              color: theme.colorScheme.outline,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}