import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/customer_model.dart';
import '../../repositories/customer_repository.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/customer_card_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/offline_indicator_widget.dart';
import './widgets/search_bar_widget.dart';

/// Customer List screen - Primary dashboard for managing tailoring clients
/// Implements offline-first data display with search, quick actions, and navigation
class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  final TextEditingController _searchController = TextEditingController();
  final CustomerRepository _customerRepository = CustomerRepository();
  
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = false;
  DateTime _lastSyncTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);

    try {
      final customersWithOrders = await _customerRepository.getAllCustomersWithOrderCounts();
      
      setState(() {
        _customers = customersWithOrders;
        _filteredCustomers = customersWithOrders;
        _lastSyncTime = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load customers: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final name = (customer["name"] as String? ?? "").toLowerCase();
          final phone = (customer["phone"] as String? ?? "").toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || phone.contains(searchLower);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterCustomers('');
  }

  Future<void> _refreshCustomers() async {
    await _loadCustomers();
  }

  void _navigateToAddCustomer() async {
    final result = await Navigator.of(context, rootNavigator: true)
        .pushNamed('/add-customer');
    
    // Reload customers if a new one was added
    if (result == true) {
      await _loadCustomers();
    }
  }

  void _navigateToCustomerProfile(Map<String, dynamic> customer) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/customer-profile', arguments: customer);
  }

  void _editCustomer(Map<String, dynamic> customer) async {
    final result = await Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/add-customer', arguments: customer);
    
    // Reload customers if edited
    if (result == true) {
      await _loadCustomers();
    }
  }

  void _viewCustomerOrders(Map<String, dynamic> customer) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/customer-profile', arguments: customer);
  }

  void _deleteCustomer(Map<String, dynamic> customer) async {
    final customerId = customer["id"] as int;
    
    // Store for undo
    final deletedCustomer = customer;
    
    // Optimistically remove from UI
    setState(() {
      _customers.removeWhere((c) => c["id"] == customerId);
      _filteredCustomers.removeWhere((c) => c["id"] == customerId);
    });

    // Delete from database
    try {
      await _customerRepository.deleteCustomer(customerId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${customer["name"]} deleted successfully'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                // Restore customer
                try {
                  final restoredCustomer = Customer(
                    name: deletedCustomer["name"],
                    phone: deletedCustomer["phone"],
                    gender: deletedCustomer["gender"],
                    email: deletedCustomer["email"],
                    notes: deletedCustomer["notes"],
                  );
                  await _customerRepository.createCustomer(restoredCustomer);
                  await _loadCustomers();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to restore customer'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Restore on error
      await _loadCustomers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete customer'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TailorPro',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            onPressed: _refreshCustomers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            onPressed: () {},
            tooltip: 'More options',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : Column(
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  onChanged: _filterCustomers,
                  onClear: _clearSearch,
                ),
                OfflineIndicatorWidget(lastSyncTime: _lastSyncTime),
                Expanded(
                  child: _filteredCustomers.isEmpty
                      ? _searchController.text.isNotEmpty
                            ? _buildNoResultsWidget(theme)
                            : EmptyStateWidget(
                                onAddCustomer: _navigateToAddCustomer,
                              )
                      : RefreshIndicator(
                          onRefresh: _refreshCustomers,
                          color: theme.colorScheme.primary,
                          child: ListView.builder(
                            padding: EdgeInsets.only(bottom: 10.h),
                            itemCount: _filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              return CustomerCardWidget(
                                customer: customer,
                                onTap: () =>
                                    _navigateToCustomerProfile(customer),
                                onEdit: () => _editCustomer(customer),
                                onViewOrders: () =>
                                    _viewCustomerOrders(customer),
                                onDelete: () => _deleteCustomer(customer),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddCustomer,
        icon: CustomIconWidget(
          iconName: 'add',
          color: theme.colorScheme.onPrimary,
          size: 24,
        ),
        label: Text('Add Customer'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildNoResultsWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'No customers found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your search',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}