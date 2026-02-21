import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FabricSelectionWidget extends StatefulWidget {
  final Map<String, dynamic>? selectedFabric;
  final Function(Map<String, dynamic>) onFabricSelected;

  const FabricSelectionWidget({
    super.key,
    required this.selectedFabric,
    required this.onFabricSelected,
  });

  @override
  State<FabricSelectionWidget> createState() => _FabricSelectionWidgetState();
}

class _FabricSelectionWidgetState extends State<FabricSelectionWidget> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Available', 'Low Stock'];

  final List<Map<String, dynamic>> _fabrics = [
    {
      "id": 1,
      "name": "Ankara Print",
      "color": "Blue & Gold",
      "image":
          "https://images.unsplash.com/photo-1700553465915-bcf2712dcf45",
      "semanticLabel":
          "Vibrant blue and gold African ankara fabric with geometric patterns",
      "quantity": "5 yards",
      "status": "Available",
    },
    {
      "id": 2,
      "name": "Lace Fabric",
      "color": "White",
      "image":
          "https://images.unsplash.com/photo-1525169087805-031a4da0623c",
      "semanticLabel":
          "Elegant white lace fabric with floral embroidery patterns",
      "quantity": "3 yards",
      "status": "Available",
    },
    {
      "id": 3,
      "name": "Aso Oke",
      "color": "Purple & Gold",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1e4d1f9b1-1767959598577.png",
      "semanticLabel":
          "Traditional purple and gold Nigerian aso oke fabric with striped patterns",
      "quantity": "2 yards",
      "status": "Low Stock",
    },
    {
      "id": 4,
      "name": "Ankara Print",
      "color": "Red & Yellow",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_18fb7d03a-1768322509267.png",
      "semanticLabel":
          "Bold red and yellow African ankara fabric with circular patterns",
      "quantity": "4 yards",
      "status": "Available",
    },
    {
      "id": 5,
      "name": "Lace Fabric",
      "color": "Cream",
      "image":
          "https://images.unsplash.com/photo-1707398255052-a65b676b95c3",
      "semanticLabel":
          "Delicate cream lace fabric with intricate floral designs",
      "quantity": "6 yards",
      "status": "Available",
    },
    {
      "id": 6,
      "name": "Ankara Print",
      "color": "Green & Orange",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_13b6e2cb6-1765354968164.png",
      "semanticLabel":
          "Vibrant green and orange African ankara fabric with abstract patterns",
      "quantity": "1 yard",
      "status": "Low Stock",
    },
  ];

  List<Map<String, dynamic>> get _filteredFabrics {
    if (_selectedFilter == 'All') {
      return _fabrics;
    }
    return (_fabrics as List)
        .where((fabric) => fabric["status"] == _selectedFilter)
        .toList()
        .cast<Map<String, dynamic>>();
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
              Text('Select Fabric', style: theme.textTheme.titleLarge),
              SizedBox(height: 1.h),
              Text(
                'Choose fabric from available stock',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2.h),
              _buildFilterChips(theme),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(4.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 0.75,
            ),
            itemCount: _filteredFabrics.length,
            itemBuilder: (context, index) {
              final fabric = _filteredFabrics[index];
              final isSelected = widget.selectedFabric?["id"] == fabric["id"];

              return _buildFabricCard(theme, fabric, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: (_filters as List)
            .map((filter) {
              final isSelected = _selectedFilter == filter;

              return Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: FilterChip(
                  label: Text(filter as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  backgroundColor: theme.colorScheme.surface,
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              );
            })
            .toList()
            .cast<Widget>(),
      ),
    );
  }

  Widget _buildFabricCard(
    ThemeData theme,
    Map<String, dynamic> fabric,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        widget.onFabricSelected(fabric);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: CustomImageWidget(
                      imageUrl: fabric["image"] as String,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      semanticLabel: fabric["semanticLabel"] as String,
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 2.w,
                      right: 2.w,
                      child: Container(
                        width: 8.w,
                        height: 8.w,
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
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 2.w,
                    left: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: fabric["status"] == "Available"
                            ? const Color(0xFF388E3C).withValues(alpha: 0.9)
                            : const Color(0xFFF57C00).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        fabric["status"] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fabric["name"] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    fabric["color"] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'inventory_2',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        fabric["quantity"] as String,
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
}
