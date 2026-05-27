import 'package:flutter/material.dart';

class AuthInputStyles {
  static const Color _accentColor = Color(0xFFFFC107);
  static const Color _lightHintColor = Color(0xFFB5B5B5);
  static const Color _lightBorderColor = Color(0xFFE7E7E7);
  static const Color _darkFillFallback = Color(0xFF1F1F1F);
  static const Color _darkBorderColor = Color(0xFF303030);

  static Color backgroundColor(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? (theme.cardTheme.color ?? _darkFillFallback) : Colors.white;
  }

  static Color textColor(ThemeData theme) {
    return theme.brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  static Color hintColor(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? Colors.white38
        : _lightHintColor;
  }

  static Color iconColor(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? Colors.white54
        : Colors.black45;
  }

  static Color cursorColor(ThemeData theme) => _accentColor;

  static InputDecoration decoration(
    BuildContext context, {
    required String hintText,
    Widget? suffixIcon,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    double borderRadius = 25,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseBorderColor = isDark ? _darkBorderColor : _lightBorderColor;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: hintColor(theme),
        fontSize: 14,
      ),
      filled: true,
      fillColor: backgroundColor(theme),
      border: _border(
        color: baseBorderColor,
        borderRadius: borderRadius,
      ),
      enabledBorder: _border(
        color: baseBorderColor,
        borderRadius: borderRadius,
      ),
      disabledBorder: _border(
        color: baseBorderColor,
        borderRadius: borderRadius,
      ),
      focusedBorder: _border(
        color: _accentColor,
        borderRadius: borderRadius,
        width: 1.4,
      ),
      errorBorder: _border(
        color: theme.colorScheme.error,
        borderRadius: borderRadius,
        width: 1.2,
      ),
      focusedErrorBorder: _border(
        color: theme.colorScheme.error,
        borderRadius: borderRadius,
        width: 1.4,
      ),
      suffixIcon: suffixIcon,
      contentPadding: contentPadding,
      isDense: true,
    );
  }

  static OutlineInputBorder _border({
    required Color color,
    required double borderRadius,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}
