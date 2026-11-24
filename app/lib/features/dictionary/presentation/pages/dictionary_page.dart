import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../domain/entities/sign_entry.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../modals/sign_detail_sheet.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final DictionaryRepository _repo = sl<DictionaryRepository>();
  late List<SignEntry> _items = _repo.getAll();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Diccionario')),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  onChanged: (q) => setState(() => _items = _repo.search(q)),
                  decoration: InputDecoration(
                    hintText: 'Buscar seña o categoría',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _items.isEmpty
                    ? Center(child: Text('Sin resultados', style: theme.textTheme.bodyLarge))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final s = _items[i];
                          return GlassCard(
                            onTap: () => showSignDetailSheet(context, s),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(s.emoji, style: const TextStyle(fontSize: 44)),
                                const SizedBox(height: 10),
                                Text(s.title, style: theme.textTheme.titleMedium),
                                Text(s.category, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
