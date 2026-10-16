import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../config/colors.dart';

class AuthCustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String? hintText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? fillColor;
  final bool autofocus;
  final String? Function(String)? onFieldSubmitted;
  final List<String>? autofillHints;

  const AuthCustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.inputFormatters,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.fillColor,
    this.autofocus = false,
    this.onFieldSubmitted,
    this.autofillHints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveFillColor = fillColor ?? AppColors.disableColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputTextColor = isDark ? AppColors.blackColor : AppColors.blackColor;
    return SizedBox(
      height: 54.h,
      width: 370.w,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autofocus: autofocus,
        style: TextStyle(fontSize: 14.sp, color: inputTextColor),
        cursorColor: AppColors.greyForgetColor,
        cursorWidth: 1.w,
        autofillHints: autofillHints,
        onSaved: onSaved,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: labelText.isEmpty ? null : labelText,
          hintText: hintText,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.textFieldColor,
            fontSize: 13.sp,
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.textFieldColor,
            fontSize: 13.sp,
          ),
          filled: true,
          fillColor: effectiveFillColor,
          prefixIcon: prefixIcon,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
