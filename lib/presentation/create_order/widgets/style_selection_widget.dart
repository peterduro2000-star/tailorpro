import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StyleSelectionWidget extends StatefulWidget {
  final Map<String, dynamic>? selectedStyle;
  final Function(Map<String, dynamic>) onStyleSelected;

  const StyleSelectionWidget({
    super.key,
    required this.selectedStyle,
    required this.onStyleSelected,
  });

  @override
  State<StyleSelectionWidget> createState() => _StyleSelectionWidgetState();
}

class _StyleSelectionWidgetState extends State<StyleSelectionWidget> {
  String _selectedCategory = 'All';
  String _selectedGender = 'All';

  final List<String> _categories = ['All', 'Traditional', 'Casual', 'Formal'];
  final List<String> _genders = ['All', 'Male', 'Female'];

  final List<Map<String, dynamic>> _styles = [
    {
      "id": 1,
      "name": "Agbada Set",
      "category": "Traditional",
      "gender": "Male",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1d1e04dfd-1765559592247.png",
      "semanticLabel":
          "Traditional Nigerian agbada outfit in white with gold embroidery",
      "isFavorite": true,
    },
    {
      "id": 2,
      "name": "Senator Suit",
      "category": "Formal",
      "gender": "Male",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_14fdd72c3-1769215541226.png",
      "semanticLabel": "Elegant navy blue senator suit with matching cap",
      "isFavorite": false,
    },
    {
      "id": 3,
      "name": "Ankara Gown",
      "category": "Traditional",
      "gender": "Female",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_18d0c0edb-1768476847981.png",
      "semanticLabel": "Colorful ankara print long gown with peplum waist",
      "isFavorite": true,
    },
    {
      "id": 4,
      "name": "Iro and Buba",
      "category": "Traditional",
      "gender": "Female",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1ccd17c32-1766567561622.png",
      "semanticLabel": "Traditional iro and buba set in purple lace fabric",
      "isFavorite": false,
    },
    {
      "id": 5,
      "name": "Kaftan",
      "category": "Casual",
      "gender": "Male",
      "image":
          "https://images.unsplash.com/photo-1605763052285-ee53bf0b7f39",
      "semanticLabel": "Casual white kaftan with blue embroidery details",
      "isFavorite": false,
    },
    {
      "id": 6,
      "name": "Ankara Dress",
      "category": "Casual",
      "gender": "Female",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1a096985e-1769215541240.png",
      "semanticLabel": "Short ankara print dress with off-shoulder design",
      "isFavorite": true,
    },
  ];

  List<Map<String, dynamic>> get _filteredStyles {
    return (_styles as List)
        .where((style) {
          final categoryMatch =
              _selectedCategory == 'All' ||
              style["category"] == _selectedCategory;
          final genderMatch =
              _selectedGender == 'All' || style["gender"] == _selectedGender;
          return categoryMatch && genderMatch;
        })
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
              Text('Select Style', style: theme.textTheme.titleLarge),
              SizedBox(height: 1.h),
              Text(
                'Browse and choose from style database',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2.h),
              _buildCategoryFilters(theme),
              SizedBox(height: 1.h),
              _buildGenderFilters(theme),
            ],
          ),
        ),
        Expanded(
          child: _filteredStyles.isEmpty
              ? _buildEmptyState(theme)
              : GridView.builder(
                  padding: EdgeInsets.all(4.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 2.h,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _filteredStyles.length,
                  itemBuilder: (context, index) {
                    final style = _filteredStyles[index];
                    final isSelected =
                        widget.selectedStyle?["id"] == style["id"];

                    return _buildStyleCard(theme, style, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: (_categories as List)
            .map((category) {
              final isSelected = _selectedCategory == category;

              return Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: FilterChip(
                  label: Text(category as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
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

  Widget _buildGenderFilters(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: (_genders as List)
            .map((gender) {
              final isSelected = _selectedGender == gender;

              return Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: FilterChip(
                  label: Text(gender as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedGender = gender;
                    });
                  },
                  backgroundColor: theme.colorScheme.surface,
                  selectedColor: theme.colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.secondary
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

  Widget _buildStyleCard(
    ThemeData theme,
    Map<String, dynamic> style,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        widget.onStyleSelected(style);
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
                      imageUrl: style["image"] as String,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      semanticLabel: style["semanticLabel"] as String,
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
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: style["isFavorite"] == true
                              ? 'favorite'
                              : 'favorite_border',
                          color: style["isFavorite"] == true
                              ? Colors.red
                              : Colors.white,
                          size: 16,
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
                    style["name"] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          style["category"] as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: style["gender"] == "Male"
                              ? Colors.blue.withValues(alpha: 0.1)
                              : Colors.pink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          style["gender"] as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: style["gender"] == "Male"
                                ? Colors.blue
                                : Colors.pink,
                            fontWeight: FontWeight.w500,
                          ),
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
              iconName: 'style',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'No styles found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try different filters or add new styles',
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
