import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/modals/confirm_dialog.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../tts/domain/usecases/tts_usecases.dart';
import '../controllers/history_controller.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  String _format(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HistoryController>();
    final entries = controller.entries;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: 'Borrar todo',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Borrar historial',
                  message: 'Se eliminarán todas las frases guardadas.',
                  confirmText: 'Borrar',
                  destructive: true,
                );
                if (ok) controller.clear();
              },
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text('Aún no hay frases guardadas', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return Dismissible(
                      key: ValueKey(e.createdAt.microsecondsSinceEpoch),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) => controller.remove(e),
                      child: GlassCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.text, style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(_format(e.createdAt), style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Reproducir',
                              icon: Icon(Icons.play_circle_fill_rounded, color: AppColors.secondary, size: 32),
                              onPressed: () => sl<SpeakTextUseCase>()(e.text),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
