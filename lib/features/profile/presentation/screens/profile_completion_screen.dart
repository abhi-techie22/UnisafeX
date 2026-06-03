import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/widgets/app_button.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/profile/domain/entities/user_profile.dart';
import 'package:unisafex/features/profile/presentation/providers/profile_provider.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedGender;
  String? _selectedVisaType;
  String? _selectedTravelPurpose;
  Country? _selectedCountry;
  Country? _selectedPassportCountry;
  DateTime? _visaExpiry;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final profile = UserProfile(
        userId: user.id,
        fullName: _nameController.text.trim(),
        gender: _selectedGender,
        nationality: _selectedCountry?.name,
        country: _selectedCountry?.name,
        countryCode: _selectedCountry?.countryCode,
        currentLocation: _locationController.text.trim(),
        passportCountry: _selectedPassportCountry?.name,
        visaType: _selectedVisaType,
        visaExpiry: _visaExpiry,
        travelPurpose: _selectedTravelPurpose,
        isProfileComplete: true,
      );

      await ref.read(profileNotifierProvider.notifier).saveProfile(profile);

      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Complete Profile',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        'Step ${_currentStep + 1} of 2',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(2, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.grey800
                                : AppColors.grey200),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: AppConstants.animNormal,
                    child: _currentStep == 0
                        ? _buildStep1()
                        : _buildStep2(),
                  ),
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: AppOutlinedButton(
                        label: 'Back',
                        onPressed: () =>
                            setState(() => _currentStep--),
                        icon: Icons.arrow_back_rounded,
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label:
                          _currentStep == 0 ? 'Continue' : 'Save Profile',
                      onPressed: _currentStep == 0 ? _nextStep : _save,
                      isLoading: _isLoading,
                      isFullWidth: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    setState(() => _currentStep = 1);
  }

  Widget _buildStep1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Info',
            style: Theme.of(context).textTheme.headlineMedium)
            .animate()
            .fadeIn(),

        const SizedBox(height: 6),
        Text(
          'Tell us about yourself',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.grey400 : AppColors.grey600,
              ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 32),

        _buildLabel('Full Name *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'John Smith',
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Please enter your name' : null,
        ),

        const SizedBox(height: 20),

        _buildLabel('Gender'),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedGender,
          hint: 'Select gender',
          items: AppConstants.genderOptions,
          onChanged: (v) => setState(() => _selectedGender = v),
          prefixIcon: Icons.wc_outlined,
        ),

        const SizedBox(height: 20),

        _buildLabel('Nationality *'),
        const SizedBox(height: 8),
        _buildCountryPicker(
          label: _selectedCountry?.name ?? 'Select your country',
          onTap: () {
            showCountryPicker(
              context: context,
              showPhoneCode: false,
              onSelect: (c) => setState(() => _selectedCountry = c),
            );
          },
          flag: _selectedCountry?.flagEmoji,
        ),

        const SizedBox(height: 20),

        _buildLabel('Current Location in India'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            hintText: 'e.g. Delhi, Mumbai...',
            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep2() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Travel Details',
            style: Theme.of(context).textTheme.headlineMedium)
            .animate()
            .fadeIn(),

        const SizedBox(height: 6),
        Text(
          'Help us personalize your experience',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.grey400 : AppColors.grey600,
              ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 32),

        _buildLabel('Passport Country'),
        const SizedBox(height: 8),
        _buildCountryPicker(
          label: _selectedPassportCountry?.name ?? 'Select passport country',
          onTap: () {
            showCountryPicker(
              context: context,
              showPhoneCode: false,
              onSelect: (c) => setState(() => _selectedPassportCountry = c),
            );
          },
          flag: _selectedPassportCountry?.flagEmoji,
        ),

        const SizedBox(height: 20),

        _buildLabel('Visa Type'),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedVisaType,
          hint: 'Select visa type',
          items: AppConstants.visaTypes,
          onChanged: (v) => setState(() => _selectedVisaType = v),
          prefixIcon: Icons.document_scanner_outlined,
        ),

        const SizedBox(height: 20),

        _buildLabel('Visa Expiry Date'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickVisaExpiry,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey800 : AppColors.grey100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: isDark ? AppColors.grey400 : AppColors.grey500,
                ),
                const SizedBox(width: 12),
                Text(
                  _visaExpiry != null
                      ? DateFormat('dd MMM yyyy').format(_visaExpiry!)
                      : 'Select expiry date',
                  style: TextStyle(
                    fontSize: 14,
                    color: _visaExpiry != null
                        ? (isDark ? AppColors.white : AppColors.grey900)
                        : (isDark ? AppColors.grey500 : AppColors.grey400),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        _buildLabel('Travel Purpose'),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedTravelPurpose,
          hint: 'Why are you visiting India?',
          items: AppConstants.travelPurposes,
          onChanged: (v) => setState(() => _selectedTravelPurpose = v),
          prefixIcon: Icons.luggage_outlined,
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _pickVisaExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _visaExpiry = picked);
  }

  Widget _buildLabel(String label) {
    return Text(label, style: Theme.of(context).textTheme.labelLarge);
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData prefixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, size: 20),
      ),
      dropdownColor:
          isDark ? AppColors.cardDark : AppColors.cardLight,
      isExpanded: true,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCountryPicker({
    required String label,
    required VoidCallback onTap,
    String? flag,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? AppColors.grey800 : AppColors.grey100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (flag != null) ...[
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
            ] else ...[
              Icon(Icons.flag_outlined,
                  size: 20,
                  color:
                      isDark ? AppColors.grey400 : AppColors.grey500),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: flag != null
                      ? (isDark ? AppColors.white : AppColors.grey900)
                      : (isDark
                          ? AppColors.grey500
                          : AppColors.grey400),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ],
        ),
      ),
    );
  }
}
