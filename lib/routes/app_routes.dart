import 'package:flutter/material.dart';

import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/dashboard/dashboard.dart';
import '../presentation/customer_list/customer_list.dart';
import '../presentation/customer_profile/customer_profile.dart';
import '../presentation/add_customer/add_customer.dart';
import '../presentation/measurements/measurements.dart';
import '../presentation/create_order/create_order_simple.dart';
import '../presentation/orders_list/orders_list_screen.dart';
import '../presentation/financial_summary/financial_summary_screen.dart';
import '../presentation/settings/settings_screen.dart';  // ADD THIS

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String dashboard = '/dashboard';
  static const String customerList = '/customer-list';
  static const String customerProfile = '/customer-profile';
  static const String addCustomer = '/add-customer';
  static const String measurements = '/measurements';
  static const String createOrder = '/create-order';
  static const String ordersList = '/orders-list';
  static const String financialSummary = '/financial-summary';
  static const String settings = '/settings';  // ADD THIS

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    dashboard: (context) => const Dashboard(),
    customerList: (context) => const CustomerList(),
    customerProfile: (context) => const CustomerProfile(),
    addCustomer: (context) => const AddCustomer(),
    measurements: (context) => const Measurements(),
    createOrder: (context) => const CreateOrderSimple(),
    ordersList: (context) => const OrdersListScreen(),
    financialSummary: (context) => const FinancialSummaryScreen(),
    settings: (context) => const SettingsScreen(),  // ADD THIS
  };
}