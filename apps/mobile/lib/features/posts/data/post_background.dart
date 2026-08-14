import 'package:flutter/material.dart';

enum PostBackground {
  defaultColor('DEFAULT'),
  red('RED'),
  blue('BLUE'),
  green('GREEN'),
  orange('ORANGE'),
  purple('PURPLE'),
  teal('TEAL'),
  dark('DARK'),
  unknown('UNKNOWN');

  const PostBackground(this.wire);
  final String wire;

  static PostBackground fromWire(String? value) {
    if (value == null) return PostBackground.defaultColor;
    return PostBackground.values.firstWhere(
      (e) => e.wire == value.toUpperCase(),
      orElse: () => PostBackground.defaultColor,
    );
  }

  bool get isDefault => this == PostBackground.defaultColor || this == PostBackground.unknown;

  Color backgroundColor(BuildContext context) {
    switch (this) {
      case PostBackground.red:
        return const Color(0xFFD32F2F);
      case PostBackground.blue:
        return const Color(0xFF1976D2);
      case PostBackground.green:
        return const Color(0xFF388E3C);
      case PostBackground.orange:
        return const Color(0xFFF57C00);
      case PostBackground.purple:
        return const Color(0xFF7B1FA2);
      case PostBackground.teal:
        return const Color(0xFF00796B);
      case PostBackground.dark:
        return const Color(0xFF212121);
      case PostBackground.defaultColor:
      case PostBackground.unknown:
        return Theme.of(context).cardColor;
    }
  }

  Color textColor(BuildContext context) {
    switch (this) {
      case PostBackground.orange:
        return const Color(0xFF111111); // High contrast dark text on orange
      case PostBackground.red:
      case PostBackground.blue:
      case PostBackground.green:
      case PostBackground.purple:
      case PostBackground.teal:
      case PostBackground.dark:
        return Colors.white; // High contrast white text on dark colors
      case PostBackground.defaultColor:
      case PostBackground.unknown:
        return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    }
  }
}
