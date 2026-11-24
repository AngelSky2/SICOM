import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/sign_prediction.dart';

/// Chip superior: seña detectada en vivo, confianza y llenado del buffer.
class PredictionOverlay extends StatelessWidget {
  const PredictionOverlay({
    super.key,
    required this.prediction,
    required this.bufferFill,
    required this.handsVisible,
    required this.threshold,
    this.modelReady = true,
  });

  final SignPrediction? prediction;
  final double bufferFill;
  final bool handsVisible;
  final double threshold;
  final bool modelReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = prediction;
    final confident = p != null && p.confidence >= threshold;
    final color = confident ? AppColors.secondary : AppColors.accent;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: bufferFill,
                  strokeWidth: 3.5,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(handsVisible ? AppColors.primary : AppColors.textSecondary),
                ),
                Icon(
                  handsVisible ? Icons.back_hand_rounded : Icons.do_not_touch_rounded,
                  size: 18,
                  color: handsVisible ? Colors.white : AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: p == null
                  ? Text(
                      !handsVisible
                          ? 'Muestra tus manos'
                          : modelReady
                              ? 'Analizando…'
                              : 'Mano detectada · falta entrenar la LSTM',
                      key: ValueKey(handsVisible),
                      style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                    )
                  : Column(
                      key: ValueKey(p.label),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.displayText, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: p.confidence,
                            minHeight: 5,
                            backgroundColor: AppColors.surfaceLight,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (p != null) ...[
            const SizedBox(width: 12),
            Text('${(p.confidence * 100).round()}%',
                style: theme.textTheme.titleMedium?.copyWith(color: color)),
          ],
        ],
      ),
    );
  }
}
