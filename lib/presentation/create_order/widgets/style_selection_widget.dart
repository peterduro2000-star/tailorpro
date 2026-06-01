import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _selectedStyleName;
  File? _pickedImage;

  final List<String> _categories = ['All', 'Traditional', 'Casual', 'Formal'];
  final List<String> _genders = ['All', 'Male', 'Female', 'Unisex'];

  final List<Map<String, dynamic>> _styles = [
    {"id": 1,  "name": "Agbada Set",      "category": "Traditional", "gender": "Male",   "icon": "man"},
    {"id": 2,  "name": "Senator Suit",    "category": "Formal",      "gender": "Male",   "icon": "business_center"},
    {"id": 3,  "name": "Ankara Gown",     "category": "Traditional", "gender": "Female", "icon": "woman"},
    {"id": 4,  "name": "Iro and Buba",    "category": "Traditional", "gender": "Female", "icon": "dry_cleaning"},
    {"id": 5,  "name": "Kaftan",          "category": "Casual",      "gender": "Male",   "icon": "person"},
    {"id": 6,  "name": "Ankara Dress",    "category": "Casual",      "gender": "Female", "icon": "checkroom"},
    {"id": 7,  "name": "Dashiki",         "category": "Casual",      "gender": "Unisex", "icon": "style"},
    {"id": 8,  "name": "Buba & Sokoto",   "category": "Traditional", "gender": "Male",   "icon": "accessibility_new"},
    {"id": 9,  "name": "Skirt & Blouse",  "category": "Casual",      "gender": "Female", "icon": "female"},
    {"id": 10, "name": "Native Suit",     "category": "Formal",      "gender": "Male",   "icon": "cases"},
    {"id": 11, "name": "Lace Blouse",     "category": "Formal",      "gender": "Female", "icon": "favorite_border"},
    {"id": 12, "name": "Boubou",          "category": "Traditional", "gender": "Unisex", "icon": "crop_free"},
  ];

  List<Map<String, dynamic>> get _filteredStyles {
    return _styles.where((style) {
      final categoryMatch =
          _selectedCategory == 'All' || style["category"] == _selectedCategory;
      final genderMatch =
          _selectedGender == 'All' || style["gender"] == _selectedGender;
      return categoryMatch && genderMatch;
    }).toList();
  }

  void _selectStyle(Map<String, dynamic> style) {
    setState(() {
      _selectedStyleName = style["name"] as String;
    });
    _notifyParent();
  }

  void _notifyParent() {
    if (_selectedStyleName == null) return;
    final style = _styles.firstWhere(
      (s) => s["name"] == _selectedStyleName,
      orElse: () => {},
    );
    widget.onStyleSelected({
      ...style,
      "imagePath": _pickedImage?.path,
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
      _notifyParent();
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Style Photo', style: theme.textTheme.titleMedium),
                SizedBox(height: 2.h),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'camera_alt',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'photo_library',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_pickedImage != null)
                  ListTile(
                    leading: CustomIconWidget(
                      iconName: 'delete_outline',
                      color: theme.colorScheme.error,
                      size: 24,
                    ),
                    title: Text(
                      'Remove Photo',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _pickedImage = null);
                      _notifyParent();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + filters
        Container(
          padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.5.h),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Style', style: theme.textTheme.titleLarge),
              SizedBox(height: 0.5.h),
              Text(
                'Filter by category and gender, then tap a style',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2.h),
              _buildFilterRow(
                theme,
                filters: _categories,
                selected: _selectedCategory,
                selectedColor: theme.colorScheme.primaryContainer,
                selectedLabelColor: theme.colorScheme.primary,
                onSelected: (val) => setState(() => _selectedCategory = val),
              ),
              SizedBox(height: 1.h),
              _buildFilterRow(
                theme,
                filters: _genders,
                selected: _selectedGender,
                selectedColor: theme.colorScheme.secondaryContainer,
                selectedLabelColor: theme.colorScheme.secondary,
                onSelected: (val) => setState(() => _selectedGender = val),
              ),
            ],
          ),
        ),

        // Style chips + photo
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(4.w),
            children: [
              _filteredStyles.isEmpty
                  ? _buildEmptyState(theme)
                  : Wrap(
                      spacing: 2.w,
                      runSpacing: 1.5.h,
                      children: _filteredStyles.map((style) {
                        final isSelected =
                            _selectedStyleName == style["name"];
                        return _buildStyleChip(theme, style, isSelected);
                      }).toList(),
                    ),

              SizedBox(height: 3.h),

              Text('Style Photo', style: theme.textTheme.titleMedium),
              SizedBox(height: 0.5.h),
              Text(
                'Optional — add a reference photo for this style',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 1.5.h),
              _buildPhotoSection(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(
    ThemeData theme, {
    required List<String> filters,
    required String selected,
    required Color selectedColor,
    required Color selectedLabelColor,
    required Function(String) onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selected == filter;
          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => onSelected(filter),
              backgroundColor: theme.colorScheme.surface,
              selectedColor: selectedColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? selectedLabelColor
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected
                    ? selectedLabelColor
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStyleChip(
    ThemeData theme,
    Map<String, dynamic> style,
    bool isSelected,
  ) {
    final gender = style["gender"] as String;
    final genderColor = gender == "Male"
        ? Colors.blue
        : gender == "Female"
            ? Colors.pink
            : theme.colorScheme.tertiary;

    return InkWell(
      onTap: () => _selectStyle(style),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.35),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: style["icon"] as String,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
            SizedBox(width: 1.5.w),
            Text(
              style["name"] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            SizedBox(width: 1.5.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: genderColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                gender,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: genderColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 1.5.w),
              CustomIconWidget(
                iconName: 'check_circle',
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    if (_pickedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _pickedImage!,
              width: double.infinity,
              height: 20.h,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 1.w,
            right: 1.w,
            child: GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'edit',
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: double.infinity,
        height: 15.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.4),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'add_a_photo',
              color: theme.colorScheme.onSurfaceVariant,
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              'Add Photo (Optional)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Camera or Gallery',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7),
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
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'style',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 56,
            ),
            SizedBox(height: 2.h),
            Text(
              'No styles found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Try a different filter combination',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}