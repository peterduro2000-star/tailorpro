import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _selectedType;
  File? _pickedImage;

  final List<Map<String, dynamic>> _fabricTypes = [
    {"name": "Ankara Print",   "icon": "style"},
    {"name": "Lace Fabric",    "icon": "texture"},
    {"name": "Aso Oke",        "icon": "grid_on"},
    {"name": "Adire",          "icon": "water_drop"},
    {"name": "George Fabric",  "icon": "auto_awesome"},
    {"name": "Plain Cotton",   "icon": "crop_square"},
    {"name": "Velvet",         "icon": "blur_on"},
    {"name": "Chiffon",        "icon": "air"},
    {"name": "Satin",          "icon": "star_border"},
    {"name": "Denim",          "icon": "table_rows"},
  ];

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

  void _notifyParent() {
    if (_selectedType == null) return;
    widget.onFabricSelected({
      "name": _selectedType,
      "imagePath": _pickedImage?.path,
    });
  }

  void _selectType(String type) {
    setState(() {
      _selectedType = type;
    });
    _notifyParent();
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
                Text('Add Fabric Photo', style: theme.textTheme.titleMedium),
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
                if (_pickedImage != null) ...[
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
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Fabric Type', style: theme.textTheme.titleLarge),
              SizedBox(height: 0.5.h),
              Text(
                'Tap a fabric type, then optionally add a photo',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Fabric type grid
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(4.w),
            children: [
              Wrap(
                spacing: 2.w,
                runSpacing: 1.5.h,
                children: _fabricTypes.map((fabric) {
                  final isSelected = _selectedType == fabric["name"];
                  return _buildFabricChip(theme, fabric, isSelected);
                }).toList(),
              ),

              SizedBox(height: 3.h),

              // Optional photo section
              Text('Fabric Photo', style: theme.textTheme.titleMedium),
              SizedBox(height: 0.5.h),
              Text(
                'Optional — add a photo for reference',
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

  Widget _buildFabricChip(
    ThemeData theme,
    Map<String, dynamic> fabric,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => _selectType(fabric["name"] as String),
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
              iconName: fabric["icon"] as String,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
            SizedBox(width: 1.5.w),
            Text(
              fabric["name"] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
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
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
            width: 1.5,
            style: BorderStyle.none, // dashed feel via dotted workaround below
          ),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}