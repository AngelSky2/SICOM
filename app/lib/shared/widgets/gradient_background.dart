import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Fondo con degradado y dos "blobs" de color difuminados.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Stack(
        children: [
          Positioned(top: -120, right: -80, child: _blob(AppColors.primary, 280)),
          Positioned(bottom: -140, left: -100, child: _blob(AppColors.secondary, 300)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
            ),
          ),
        ),
      );
}
