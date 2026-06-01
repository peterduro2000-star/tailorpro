import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../repositories/customer_repository.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/customer_header_widget.dart';
import './widgets/measurement_tab_widget.dart';
import './widgets/orders_tab_widget.dart';
import './widgets/payments_tab_widget.dart';

/// Customer Profile screen with comprehensive customer management
/// Displays customer information, measurements, orders, and payment tracking
class CustomerProfile extends StatefulWidget {
  const CustomerProfile({super.key});

  @override
  State<CustomerProfile> createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  
  final CustomerRepository _customerRepository = CustomerRepository();
  Map<String, dynamic>? _customerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (args is Map<String, dynamic>) {
      setState(() {
        _customerData = args;
        _isLoading = false;
      });
      
      // If we have an ID, fetch fresh data from database
      if (args['id'] != null) {
        _refreshCustomerData(args['id']);
      }
    }
  }

  Future<void> _refreshCustomerData(int customerId) async {
    try {
      final customerWithOrders = await _customerRepository.getCustomerWithOrderCount(customerId);
      
      if (customerWithOrders.isNotEmpty && mounted) {
        setState(() {
          _customerData = customerWithOrders;
        });
      }
    } catch (e) {
      debugPrint('Failed to refresh customer data: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch phone dialer'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final customerName = _customerData?['name'] ?? 'there';
    final String message = Uri.encodeComponent(
      'Hello $customerName, this is regarding your tailoring order.',
    );
    
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open WhatsApp'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading || _customerData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Customer Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _customerData!['name'] ?? 'Customer Profile',
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            size: 6.w,
            color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'edit',
              size: 6.w,
              color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
            ),
            onPressed: _editCustomer,
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          CustomerHeaderWidget(
            customer: _customerData!,
            onCall: () => _makePhoneCall(_customerData!['phone'] ?? ''),
            onWhatsApp: () => _openWhatsApp(_customerData!['phone'] ?? ''),
          ),
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Measurements'),
                Tab(text: 'Orders'),
                Tab(text: 'Payments'),
              ],
              labelColor: theme.tabBarTheme.labelColor,
              unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor,
              indicatorColor: theme.tabBarTheme.indicatorColor,
              labelStyle: theme.tabBarTheme.labelStyle,
              unselectedLabelStyle: theme.tabBarTheme.unselectedLabelStyle,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                MeasurementTabWidget(
                  customer: _customerData!,
                ),
                OrdersTabWidget(
                  customer: _customerData!,
                ),
                PaymentsTabWidget(
                  customer: _customerData!,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 2 
          ? null  // Hide FAB on Payments tab
          : FloatingActionButton.extended(
              onPressed: _handleFabAction,
              icon: CustomIconWidget(
                iconName: 'add',
                size: 6.w,
                color: theme.floatingActionButtonTheme.foregroundColor ?? theme.colorScheme.onPrimary,
              ),
              label: Text(
                _getFabLabel(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.floatingActionButtonTheme.foregroundColor ?? theme.colorScheme.onPrimary,
                ),
              ),
            ),
    );
  }

  String _getFabLabel() {
    switch (_currentTabIndex) {
      case 0:
        return 'Add Measurement';
      case 1:
        return 'Create Order';
      case 2:
        return 'Record Payment';
      default:
        return 'Add';
    }
  }

  void _handleFabAction() {
    switch (_currentTabIndex) {
      case 0:
        _addMeasurement();
        break;
      case 1:
        _createOrder();
        break;
      case 2:
        _recordPayment();
        break;
    }
  }

  void _editCustomer() async {
    final result = await Navigator.of(context, rootNavigator: true)
        .pushNamed('/add-customer', arguments: _customerData);
    
    if (result == true && _customerData?['id'] != null) {
      await _refreshCustomerData(_customerData!['id']);
    }
  }

  void _addMeasurement() {
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/measurements',
      arguments: _customerData,
    );
  }

  void _createOrder() async {
    final result = await Navigator.of(context, rootNavigator: true).pushNamed(
      '/create-order',
      arguments: _customerData,
    );
    
    if (result == true) {
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _recordPayment() {
    // Just show a message - the Payments tab has its own button
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use "Record Payment" button in the tab above'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}