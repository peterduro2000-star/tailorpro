import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/measurement_model.dart';
import '../../repositories/measurement_repository.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/custom_measurement_widget.dart';
import './widgets/gender_toggle_widget.dart';
import './widgets/measurement_category_widget.dart';
import './widgets/measurement_history_widget.dart';
import './widgets/measurement_input_widget.dart';

class Measurements extends StatefulWidget {
  const Measurements({super.key});

  @override
  State<Measurements> createState() => _MeasurementsState();
}

class _MeasurementsState extends State<Measurements> {
  final MeasurementRepository _measurementRepository = MeasurementRepository();
  
  Map<String, dynamic>? _customerData;
  String _selectedGender = 'Male';
  String _selectedUnit = 'inches';
  final Map<String, String> _validationErrors = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _measurementHistory = [];

  // Male measurement controllers
  final TextEditingController _maleChestController = TextEditingController();
  final TextEditingController _maleWaistController = TextEditingController();
  final TextEditingController _maleHipController = TextEditingController();
  final TextEditingController _maleShoulderController = TextEditingController();
  final TextEditingController _maleNeckController = TextEditingController();
  final TextEditingController _maleShirtLengthController = TextEditingController();
  final TextEditingController _maleTrouserLengthController = TextEditingController();
  final TextEditingController _maleSleeveController = TextEditingController();
  final TextEditingController _maleArmholeController = TextEditingController();
  final TextEditingController _maleThighController = TextEditingController();

  // Female measurement controllers
  final TextEditingController _femaleBustController = TextEditingController();
  final TextEditingController _femaleWaistController = TextEditingController();
  final TextEditingController _femaleHipController = TextEditingController();
  final TextEditingController _femaleShoulderController = TextEditingController();
  final TextEditingController _femaleNeckController = TextEditingController();
  final TextEditingController _femaleDressLengthController = TextEditingController();
  final TextEditingController _femaleSkirtLengthController = TextEditingController();
  final TextEditingController _femaleSleeveController = TextEditingController();
  final TextEditingController _femaleArmholeController = TextEditingController();
  final TextEditingController _femaleUnderBustController = TextEditingController();

  // Custom measurements
  final List<Map<String, TextEditingController>> _customMeasurements = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomerData();
    });
  }

  void _loadCustomerData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args != null && args is Map<String, dynamic>) {
      setState(() {
        _customerData = args;
        _selectedGender = args['gender'] ?? 'Male';
      });
      
      // Load measurement history
      if (args['id'] != null) {
        await _loadMeasurementHistory(args['id']);
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMeasurementHistory(int customerId) async {
    try {
      final measurements = await _measurementRepository.getCustomerMeasurements(customerId);
      
      setState(() {
        _measurementHistory = measurements.map((m) => m.toDisplayMap()).toList();
      });
    } catch (e) {
      debugPrint('Error loading measurements: $e');
    }
  }

  @override
  void dispose() {
    _maleChestController.dispose();
    _maleWaistController.dispose();
    _maleHipController.dispose();
    _maleShoulderController.dispose();
    _maleNeckController.dispose();
    _maleShirtLengthController.dispose();
    _maleTrouserLengthController.dispose();
    _maleSleeveController.dispose();
    _maleArmholeController.dispose();
    _maleThighController.dispose();
    _femaleBustController.dispose();
    _femaleWaistController.dispose();
    _femaleHipController.dispose();
    _femaleShoulderController.dispose();
    _femaleNeckController.dispose();
    _femaleDressLengthController.dispose();
    _femaleSkirtLengthController.dispose();
    _femaleSleeveController.dispose();
    _femaleArmholeController.dispose();
    _femaleUnderBustController.dispose();
    for (var measurement in _customMeasurements) {
      measurement['name']?.dispose();
      measurement['value']?.dispose();
    }
    super.dispose();
  }

  void _onGenderChanged(String gender) {
    setState(() {
      _selectedGender = gender;
      _validationErrors.clear();
    });
  }

  void _addCustomMeasurement() {
    setState(() {
      _customMeasurements.add({
        'name': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _removeCustomMeasurement(int index) {
    setState(() {
      _customMeasurements[index]['name']?.dispose();
      _customMeasurements[index]['value']?.dispose();
      _customMeasurements.removeAt(index);
    });
  }

  void _copyMeasurements(Map<String, dynamic> history) {
    setState(() {
      final values = history['values'] as Map<String, double>?;
      if (values == null) return;

      if (_selectedGender == 'Male') {
        _maleChestController.text = values['Chest']?.toString() ?? '';
        _maleWaistController.text = values['Waist']?.toString() ?? '';
        _maleHipController.text = values['Hip']?.toString() ?? '';
        _maleShoulderController.text = values['Shoulder']?.toString() ?? '';
        _maleNeckController.text = values['Neck']?.toString() ?? '';
        _maleShirtLengthController.text = values['Shirt Length']?.toString() ?? '';
        _maleTrouserLengthController.text = values['Trouser Length']?.toString() ?? '';
        _maleSleeveController.text = values['Sleeve Length']?.toString() ?? '';
        _maleArmholeController.text = values['Armhole']?.toString() ?? '';
        _maleThighController.text = values['Thigh']?.toString() ?? '';
      } else {
        _femaleBustController.text = values['Bust']?.toString() ?? '';
        _femaleWaistController.text = values['Waist']?.toString() ?? '';
        _femaleHipController.text = values['Hip']?.toString() ?? '';
        _femaleShoulderController.text = values['Shoulder']?.toString() ?? '';
        _femaleNeckController.text = values['Neck']?.toString() ?? '';
        _femaleDressLengthController.text = values['Dress Length']?.toString() ?? '';
        _femaleSkirtLengthController.text = values['Skirt Length']?.toString() ?? '';
        _femaleSleeveController.text = values['Sleeve Length']?.toString() ?? '';
        _femaleArmholeController.text = values['Armhole']?.toString() ?? '';
        _femaleUnderBustController.text = values['Under Bust']?.toString() ?? '';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Measurements copied successfully'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _validateMeasurements() {
    setState(() {
      _validationErrors.clear();
    });

    bool isValid = true;

    if (_selectedGender == 'Male') {
      if (_maleChestController.text.isEmpty) {
        _validationErrors['chest'] = 'Required';
        isValid = false;
      }
      if (_maleWaistController.text.isEmpty) {
        _validationErrors['waist'] = 'Required';
        isValid = false;
      }
      if (_maleShirtLengthController.text.isEmpty) {
        _validationErrors['shirtLength'] = 'Required';
        isValid = false;
      }
    } else {
      if (_femaleBustController.text.isEmpty) {
        _validationErrors['bust'] = 'Required';
        isValid = false;
      }
      if (_femaleWaistController.text.isEmpty) {
        _validationErrors['waist'] = 'Required';
        isValid = false;
      }
      if (_femaleDressLengthController.text.isEmpty) {
        _validationErrors['dressLength'] = 'Required';
        isValid = false;
      }
    }

    if (!isValid) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return isValid;
  }

  Future<void> _saveMeasurements() async {
    if (!_validateMeasurements()) {
      return;
    }

    if (_customerData == null || _customerData!['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Customer data not found'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    try {
      // Collect all measurements
      final Map<String, double> measurementValues = {};

      if (_selectedGender == 'Male') {
        if (_maleChestController.text.isNotEmpty) {
          measurementValues['Chest'] = double.parse(_maleChestController.text);
        }
        if (_maleWaistController.text.isNotEmpty) {
          measurementValues['Waist'] = double.parse(_maleWaistController.text);
        }
        if (_maleHipController.text.isNotEmpty) {
          measurementValues['Hip'] = double.parse(_maleHipController.text);
        }
        if (_maleShoulderController.text.isNotEmpty) {
          measurementValues['Shoulder'] = double.parse(_maleShoulderController.text);
        }
        if (_maleNeckController.text.isNotEmpty) {
          measurementValues['Neck'] = double.parse(_maleNeckController.text);
        }
        if (_maleShirtLengthController.text.isNotEmpty) {
          measurementValues['Shirt Length'] = double.parse(_maleShirtLengthController.text);
        }
        if (_maleTrouserLengthController.text.isNotEmpty) {
          measurementValues['Trouser Length'] = double.parse(_maleTrouserLengthController.text);
        }
        if (_maleSleeveController.text.isNotEmpty) {
          measurementValues['Sleeve Length'] = double.parse(_maleSleeveController.text);
        }
        if (_maleArmholeController.text.isNotEmpty) {
          measurementValues['Armhole'] = double.parse(_maleArmholeController.text);
        }
        if (_maleThighController.text.isNotEmpty) {
          measurementValues['Thigh'] = double.parse(_maleThighController.text);
        }
      } else {
        if (_femaleBustController.text.isNotEmpty) {
          measurementValues['Bust'] = double.parse(_femaleBustController.text);
        }
        if (_femaleWaistController.text.isNotEmpty) {
          measurementValues['Waist'] = double.parse(_femaleWaistController.text);
        }
        if (_femaleHipController.text.isNotEmpty) {
          measurementValues['Hip'] = double.parse(_femaleHipController.text);
        }
        if (_femaleShoulderController.text.isNotEmpty) {
          measurementValues['Shoulder'] = double.parse(_femaleShoulderController.text);
        }
        if (_femaleNeckController.text.isNotEmpty) {
          measurementValues['Neck'] = double.parse(_femaleNeckController.text);
        }
        if (_femaleDressLengthController.text.isNotEmpty) {
          measurementValues['Dress Length'] = double.parse(_femaleDressLengthController.text);
        }
        if (_femaleSkirtLengthController.text.isNotEmpty) {
          measurementValues['Skirt Length'] = double.parse(_femaleSkirtLengthController.text);
        }
        if (_femaleSleeveController.text.isNotEmpty) {
          measurementValues['Sleeve Length'] = double.parse(_femaleSleeveController.text);
        }
        if (_femaleArmholeController.text.isNotEmpty) {
          measurementValues['Armhole'] = double.parse(_femaleArmholeController.text);
        }
        if (_femaleUnderBustController.text.isNotEmpty) {
          measurementValues['Under Bust'] = double.parse(_femaleUnderBustController.text);
        }
      }

      // Add custom measurements
      for (var custom in _customMeasurements) {
        final name = custom['name']?.text ?? '';
        final value = custom['value']?.text ?? '';
        if (name.isNotEmpty && value.isNotEmpty) {
          measurementValues[name] = double.parse(value);
        }
      }

      // Create measurement object
final measurement = Measurement(
  customerId: _customerData!['id'],
  measurementType: _selectedGender,
  measurements: measurementValues,
);

      // Save to database
      await _measurementRepository.createMeasurement(measurement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Measurements saved successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving measurements: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearAllMeasurements() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            'Clear All Measurements?',
            style: theme.textTheme.titleLarge,
          ),
          content: Text(
            'This will clear all entered measurements. This action cannot be undone.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_selectedGender == 'Male') {
                    _maleChestController.clear();
                    _maleWaistController.clear();
                    _maleHipController.clear();
                    _maleShoulderController.clear();
                    _maleNeckController.clear();
                    _maleShirtLengthController.clear();
                    _maleTrouserLengthController.clear();
                    _maleSleeveController.clear();
                    _maleArmholeController.clear();
                    _maleThighController.clear();
                  } else {
                    _femaleBustController.clear();
                    _femaleWaistController.clear();
                    _femaleHipController.clear();
                    _femaleShoulderController.clear();
                    _femaleNeckController.clear();
                    _femaleDressLengthController.clear();
                    _femaleSkirtLengthController.clear();
                    _femaleSleeveController.clear();
                    _femaleArmholeController.clear();
                    _femaleUnderBustController.clear();
                  }
                  for (var measurement in _customMeasurements) {
                    measurement['name']?.clear();
                    measurement['value']?.clear();
                  }
                  _validationErrors.clear();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All measurements cleared'),
                    backgroundColor: theme.colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Measurements'),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Measurements', style: theme.appBarTheme.titleTextStyle),
            Text(
              _customerData?['name'] ?? 'Unknown Customer',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.appBarTheme.foregroundColor?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
              size: 24,
            ),
            onSelected: (value) {
              if (value == 'clear') {
                _clearAllMeasurements();
              } else if (value == 'unit') {
                setState(() {
                  _selectedUnit = _selectedUnit == 'inches' ? 'cm' : 'inches';
                });
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'unit',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'straighten',
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Switch to ${_selectedUnit == 'inches' ? 'cm' : 'inches'}',
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'delete_outline',
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Clear All',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GenderToggleWidget(
                    selectedGender: _selectedGender,
                    onGenderChanged: _onGenderChanged,
                  ),
                  SizedBox(height: 2.h),
                  _selectedGender == 'Male'
                      ? _buildMaleMeasurements()
                      : _buildFemaleMeasurements(),
                  SizedBox(height: 3.h),
                  CustomMeasurementWidget(
                    customMeasurements: _customMeasurements,
                    onAddMeasurement: _addCustomMeasurement,
                    onRemoveMeasurement: _removeCustomMeasurement,
                    unit: _selectedUnit,
                  ),
                  MeasurementHistoryWidget(
                    measurementHistory: _measurementHistory,
                    onCopyMeasurements: _copyMeasurements,
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: _saveMeasurements,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save Measurements',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaleMeasurements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MeasurementCategoryWidget(
          title: 'Upper Body',
          iconName: 'accessibility_new',
        ),
        MeasurementInputWidget(
          label: 'Chest',
          iconName: 'straighten',
          controller: _maleChestController,
          unit: _selectedUnit,
          isRequired: true,
          errorText: _validationErrors['chest'],
        ),
        MeasurementInputWidget(
          label: 'Shoulder',
          iconName: 'straighten',
          controller: _maleShoulderController,
          unit: _selectedUnit,
        ),
        MeasurementInputWidget(
          label: 'Neck',
          iconName: 'straighten',
          controller: _maleNeckController,
          unit: _selectedUnit,
        ),
        MeasurementInputWidget(
          label: 'Armhole',
          iconName: 'straighten',
          controller: _maleArmholeController,
          unit: _selectedUnit,
        ),
        const MeasurementCategoryWidget(
          title: 'Mid Section',
          iconName: 'fitness_center',
        ),
        MeasurementInputWidget(
          label: 'Waist',
          iconName: 'straighten',
          controller: _maleWaistController,
          unit: _selectedUnit,
          isRequired: true,
          errorText: _validationErrors['waist'],
        ),
        MeasurementInputWidget(
          label: 'Hip',
          iconName: 'straighten',
          controller: _maleHipController,
          unit: _selectedUnit,
        ),
        const MeasurementCategoryWidget(
          title: 'Length Measurements',
          iconName: 'height',
        ),
        MeasurementInputWidget(
          label: 'Shirt Length',
          iconName: 'straighten',
          controller: _maleShirtLengthController,
          unit: _selectedUnit,
          isRequired: true,
          errorText: _validationErrors['shirtLength'],
        ),
        MeasurementInputWidget(
          label: 'Trouser Length',
          iconName: 'straighten',
          controller: _maleTrouserLengthController,
          unit: _selectedUnit,
        ),
        MeasurementInputWidget(
          label: 'Thigh',
          iconName: 'straighten',
          controller: _maleThighController,
          unit: _selectedUnit,
        ),
        const MeasurementCategoryWidget(
          title: 'Sleeve Details',
          iconName: 'gesture',
        ),
        MeasurementInputWidget(
          label: 'Sleeve Length',
          iconName: 'straighten',
          controller: _maleSleeveController,
          unit: _selectedUnit,
        ),
      ],
    );
  }

  Widget _buildFemaleMeasurements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MeasurementCategoryWidget(
          title: 'Upper Body',
          iconName: 'accessibility_new',
        ),
        MeasurementInputWidget(
          label: 'Bust',
          iconName: 'straighten',
          controller: _femaleBustController,
          unit: _selectedUnit,
          isRequired: true,
          errorText: _validationErrors['bust'],
        ),
        MeasurementInputWidget(
          label: 'Under Bust',
          iconName: 'straighten',
          controller: _femaleUnderBustController,
          unit: _selectedUnit,
        ),
        MeasurementInputWidget(
          label: 'Shoulder',
          iconName: 'straighten',
          controller: _femaleShoulderController,
          unit: _selectedUnit,
        ),
        MeasurementInputWidget(
          label: 'Neck',
          iconName: 'straighten',
          controller: _femaleNeckController,
          unit: _selectedUnit,
        ),
        MeasurementInputWidget(
          label: 'Armhole',
          iconName: 'straighten',
          controller: _femaleArmholeController,
          unit: _selectedUnit,
        ),
        const MeasurementCategoryWidget(
          title: 'Mid Section',
          iconName: 'fitness_center',
        ),
        MeasurementInputWidget(
          label: 'Waist',
          iconName: 'straighten',
          controller: _femaleWaistController,
          unit: _selectedUnit,
          isRequired: true,
          errorText: _validationErrors['waist'],
        ),
        MeasurementInputWidget(
          label: 'Hip',
          iconName: 'straighten',
          controller: _femaleHipController,
          unit: _selectedUnit,
        ),
        const MeasurementCategoryWidget(
          title: 'Length Measurements',
          iconName: 'height',
        ),
        MeasurementInputWidget(
          label: 'Dress Length',
          iconName: 'straighten',
          controller: _femaleDressLengthController,
          unit: _selectedUnit,
          isRequired: true,
          errorText: _validationErrors['dressLength'],
        ),
        MeasurementInputWidget(
          label: 'Skirt Length',
          iconName: 'straighten',
          controller: _femaleSkirtLengthController,
          unit: _selectedUnit,
        ),
        const MeasurementCategoryWidget(
          title: 'Sleeve Details',
          iconName: 'gesture',
        ),
        MeasurementInputWidget(
          label: 'Sleeve Length',
          iconName: 'straighten',
          controller: _femaleSleeveController,
          unit: _selectedUnit,
        ),
      ],
    );
  }
}