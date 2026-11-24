import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Panel inferior con la frase construida y sus acciones.
class TranscriptPanel extends StatelessWidget {
  const TranscriptPanel({
    super.key,
    required this.words,
    required this.onSpeak,
    required this.onBackspace,
    required this.onClear,
    required this.onSave,
  });

  final List<String> words;
  final VoidCallback onSpeak;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = words.isEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Traducción', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('${words.length} palabras', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56, maxHeight: 110),
              child: SingleChildScrollView(
                reverse: true,
                child: empty
                    ? Text('Las señas reconocidas aparecerán aquí…',
                        style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < words.length; i++)
                            TweenAnimationBuilder<double>(
                              key: ValueKey('$i-${words[i]}'),
                              tween: Tween(begin: 0.6, end: 1),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              builder: (_, s, child) => Transform.scale(scale: s, child: child),
                              child: Chip(
                                label: Text(words[i]),
                                backgroundColor: i == words.length - 1
                                    ? AppColors.primary.withValues(alpha: 0.35)
                                    : AppColors.surfaceLight,
                                side: BorderSide.none,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(icon: Icons.backspace_outlined, tooltip: 'Borrar última', onTap: empty ? null : onBackspace),
                _ActionButton(icon: Icons.delete_sweep_outlined, tooltip: 'Limpiar', onTap: empty ? null : onClear),
                _ActionButton(icon: Icons.bookmark_add_outlined, tooltip: 'Guardar', onTap: empty ? null : onSave),
                const Spacer(),
                FilledButton.icon(
                  onPressed: empty ? null : onSpeak,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Hablar'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon),
        style: IconButton.styleFrom(backgroundColor: AppColors.surfaceLight),
      );
}
