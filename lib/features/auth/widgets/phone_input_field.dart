import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../core/theme/app_colors.dart';

class PhoneInputField extends StatelessWidget {
  final void Function(String fullNumber) onChanged;
  final String? Function(String?)? validator;
  final String? initialValue;

  const PhoneInputField({
    super.key,
    required this.onChanged,
    this.validator,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      initialCountryCode: 'IN',
      initialValue: initialValue,
      style: const TextStyle(color: AppColors.textPrimary),
      dropdownTextStyle: const TextStyle(color: AppColors.textPrimary),
      dropdownIcon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
      decoration: InputDecoration(
        labelText: 'Phone Number',
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      onChanged: (phone) => onChanged(phone.completeNumber),
      validator: validator != null ? (phone) => validator!(phone?.completeNumber) : null,
    );
  }
}
