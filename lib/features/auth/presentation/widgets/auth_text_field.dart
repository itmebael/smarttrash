import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Colors.blue,
          selectionHandleColor: Colors.blue,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.black),
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white, // White text for black theme
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              validator: validator,
              onChanged: onChanged,
              maxLines: maxLines,
              enabled: enabled,
              style: const TextStyle(
                color: Colors.black, // Black text
                fontSize: 16,
                fontWeight: FontWeight.normal,
                decoration: TextDecoration.none,
              ),
              cursorColor: Colors.black, // Black cursor
              selectionControls: MaterialTextSelectionControls(),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                    color: Colors.grey.withValues(
                        alpha: 0.7)), // Gray hint for light background
                prefixIcon: prefixIcon != null
                    ? Icon(prefixIcon,
                        color: AppTheme.primaryGreen, size: 20) // Green icon
                    : null,
                suffixIcon: suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.3), // Gray border
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryGreen, // Green focused border
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.dangerRed),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.dangerRed, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

