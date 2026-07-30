import 'dart:ui';
import 'package:flutter/material.dart';

/// A frosted-glass card: a blurred, semi-transparent surface with a hairline
/// border. Used for the dashboard's hero cards and anywhere else that
/// should feel like it's floating above the background rather than sitting
/// flat on it. Kept as one widget so the blur amount / opacity stay
/// consistent everywhere instead of being re-tuned per screen.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: (isDark ? Colors.white : scheme.primary).withOpacity(isDark ? 0.06 : 0.08),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: (isDark ? Colors.white : scheme.primary).withOpacity(0.14),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
