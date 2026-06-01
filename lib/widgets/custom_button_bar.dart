import 'package:flutter/material.dart';


/// A reusable bottom navigation bar widget for the tailoring business management app.
/// Implements the "Bottom-Heavy Action Placement" touch architecture for one-handed operation.
///
/// This widget is parameterized and does not contain hardcoded navigation logic,
/// making it reusable across different implementations (simple navigation, PageView, etc.).
///
/// Navigation items are based on the Mobile Navigation Hierarchy:
/// - Customer List (Home Icon): Primary dashboard
/// - Add Customer (Plus Icon): Quick customer creation
/// - Create Order (Shopping Bag Icon): Order workflow
/// - Measurements (Ruler Icon): Measurement capture
/// - Customer Profile (Person Icon): Detailed customer view
class CustomBottomBar extends StatelessWidget {
  /// The currently selected index
  final int currentIndex;

  /// Callback function when a navigation item is tapped
  final Function(int) onTap;

  /// Optional background color override
  final Color? backgroundColor;

  /// Optional selected item color override
  final Color? selectedItemColor;

  /// Optional unselected item color override
  final Color? unselectedItemColor;

  /// Optional elevation override
  final double? elevation;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor:
          backgroundColor ?? theme.bottomNavigationBarTheme.backgroundColor,
      selectedItemColor:
          selectedItemColor ?? theme.bottomNavigationBarTheme.selectedItemColor,
      unselectedItemColor:
          unselectedItemColor ??
          theme.bottomNavigationBarTheme.unselectedItemColor,
      selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
      unselectedLabelStyle: theme.bottomNavigationBarTheme.unselectedLabelStyle,
      elevation: elevation ?? 8.0,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: 24),
          activeIcon: Icon(Icons.home, size: 24),
          label: 'Customers',
          tooltip: 'Customer List',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_add_outlined, size: 24),
          activeIcon: Icon(Icons.person_add, size: 24),
          label: 'Add Customer',
          tooltip: 'Add New Customer',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined, size: 24),
          activeIcon: Icon(Icons.shopping_bag, size: 24),
          label: 'New Order',
          tooltip: 'Create Order',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.straighten_outlined, size: 24),
          activeIcon: Icon(Icons.straighten, size: 24),
          label: 'Measurements',
          tooltip: 'Measurement Capture',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline, size: 24),
          activeIcon: Icon(Icons.person, size: 24),
          label: 'Profile',
          tooltip: 'Customer Profile',
        ),
      ],
    );
  }
}

/// Navigation helper class to map bottom bar indices to route paths
class BottomBarNavigation {
  /// Map of bottom bar indices to their corresponding route paths
  static const Map<int, String> routes = {
    0: '/customer-list', // Customer List (Home)
    1: '/add-customer', // Add Customer
    2: '/create-order', // Create Order
    3: '/measurements', // Measurements
    4: '/customer-profile', // Customer Profile
  };

  /// Get the route path for a given index
  static String getRoute(int index) {
    return routes[index] ?? '/customer-list';
  }

  /// Get the index for a given route path
  static int getIndex(String route) {
    return routes.entries
        .firstWhere(
          (entry) => entry.value == route,
          orElse: () => const MapEntry(0, '/customer-list'),
        )
        .key;
  }

  /// Navigate to a specific index using the provided context
  static void navigateToIndex(BuildContext context, int index) {
    final route = getRoute(index);
    Navigator.pushReplacementNamed(context, route);
  }
}
