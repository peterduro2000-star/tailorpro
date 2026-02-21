import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CustomerSelectionWidget extends StatefulWidget {
  final Map<String, dynamic>? selectedCustomer;
  final Function(Map<String, dynamic>) onCustomerSelected;

  const CustomerSelectionWidget({
    super.key,
    required this.selectedCustomer,
    required this.onCustomerSelected,
  });

  @override
  State<CustomerSelectionWidget> createState() =>
      _CustomerSelectionWidgetState();
}

class _CustomerSelectionWidgetState extends State<CustomerSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCustomers = [];

  final List<Map<String, dynamic>> _recentCustomers = [
    {
      "id": 1,
      "name": "Adebayo Johnson",
      "phone": "+234 803 456 7890",
      "gender": "Male",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1192981a2-1763292809719.png",
      "semanticLabel":
          "Professional headshot of a Nigerian man with short black hair wearing a blue shirt",
      "lastOrder": "2026-01-20",
      "totalOrders": 5,
    },
    {
      "id": 2,
      "name": "Chioma Okafor",
      "phone": "+234 805 123 4567",
      "gender": "Female",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1a0ea65bb-1763296441079.png",
      "semanticLabel":
          "Professional headshot of a Nigerian woman with braided hair wearing a yellow blouse",
      "lastOrder": "2026-01-18",
      "totalOrders": 8,
    },
    {
      "id": 3,
      "name": "Ibrahim Musa",
      "phone": "+234 807 890 1234",
      "gender": "Male",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1d0e5ef1f-1763292250024.png",
      "semanticLabel":
          "Professional headshot of a Nigerian man with short hair wearing a white kaftan",
      "lastOrder": "2026-01-15",
      "totalOrders": 3,
    },
    {
      "id": 4,
      "name": "Blessing Eze",
      "phone": "+234 809 234 5678",
      "gender": "Female",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1bbbef076-1763298267599.png",
      "semanticLabel":
          "Professional headshot of a Nigerian woman with natural hair wearing a green dress",
      "lastOrder": "2026-01-12",
      "totalOrders": 12,
    },
    {
      "id": 5,
      "name": "Emeka Nwosu",
      "phone": "+234 806 567 8901",
      "gender": "Male",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1674f7337-1763292472622.png",
      "semanticLabel":
          "Professional headshot of a Nigerian man with glasses wearing a black shirt",
      "lastOrder": "2026-01-10",
      "totalOrders": 6,
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredCustomers = _recentCustomers;
    _searchController.addListener(_filterCustomers);
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = query.isEmpty
          ? _recentCustomers
          : (_recentCustomers as List)
                .where((customer) {
                  final name = (customer["name"] as String).toLowerCase();
                  final phone = (customer["phone"] as String).toLowerCase();
                  return name.contains(query) || phone.contains(query);
                })
                .toList()
                .cast<Map<String, dynamic>>();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Customer', style: theme.textTheme.titleLarge),
              SizedBox(height: 1.h),
              Text(
                'Choose an existing customer or create a new one',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'search',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredCustomers.isEmpty
              ? _buildEmptyState(theme)
              : ListView.separated(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _filteredCustomers.length + 1,
                  separatorBuilder: (context, index) => SizedBox(height: 2.h),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildQuickAddButton(theme);
                    }

                    final customer = _filteredCustomers[index - 1];
                    final isSelected =
                        widget.selectedCustomer?["id"] == customer["id"];

                    return _buildCustomerCard(theme, customer, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuickAddButton(ThemeData theme) {
    return InkWell(
      onTap: () {
        Navigator.of(context, rootNavigator: true).pushNamed('/add-customer');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'add',
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Customer',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Create a new customer profile',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(
    ThemeData theme,
    Map<String, dynamic> customer,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        widget.onCustomerSelected(customer);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageWidget(
                    imageUrl: customer["avatar"] as String,
                    width: 15.w,
                    height: 15.w,
                    fit: BoxFit.cover,
                    semanticLabel: customer["semanticLabel"] as String,
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'check',
                          color: theme.colorScheme.onPrimary,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer["name"] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'phone',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          customer["phone"] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: customer["gender"] == "Male"
                              ? Colors.blue.withValues(alpha: 0.1)
                              : Colors.pink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          customer["gender"] as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: customer["gender"] == "Male"
                                ? Colors.blue
                                : Colors.pink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${customer["totalOrders"]} orders',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'person_search',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'No customers found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try a different search or add a new customer',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
