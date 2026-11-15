import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/frigo_widgets.dart';
import '../../models/models.dart';
import '../../providers/profile_provider.dart';

/// `9. Allergies and diet` — allergens hide recipes, diet filters them.
///
/// Edits are kept in a local draft and only written to [profileProvider]
/// when the user taps `Save`.
class AllergiesScreen extends ConsumerStatefulWidget {
  const AllergiesScreen({super.key});

  @override
  ConsumerState<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends ConsumerState<AllergiesScreen> {
  final _customController = TextEditingController();
  late Set<Allergen> _allergies;
  late List<String> _custom;
  late Diet _diet;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _allergies = {...profile.allergies};
    _custom = [...profile.customAllergies];
    _diet = profile.diet;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _addCustom() {
    final raw = _customController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (raw.isEmpty) return;
    final key = normalizeIngredientName(raw);
    setState(() {
      _customController.clear();
      // Typing a standard allergen just selects its chip.
      for (final a in Allergen.values) {
        if (a.label.toLowerCase() == key) {
          _allergies.add(a);
          return;
        }
      }
      final exists = _custom.any((c) => normalizeIngredientName(c) == key);
      if (!exists) _custom.add(raw[0].toUpperCase() + raw.substring(1));
    });
  }

  void _save() {
    ref
        .read(profileProvider.notifier)
        .updateDietary(
          allergies: _allergies,
          customAllergies: _custom,
          diet: _diet,
        );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).maybePop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Allergies and diet saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const ScreenHeader(title: 'Allergies and diet', showBack: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AlertBanner(
                    icon: Icons.warning_amber_rounded,
                    message:
                        'Recipes with these ingredients are hidden from '
                        'your suggestions.',
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel("I'm allergic to"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final allergen in Allergen.values)
                        FilterChip(
                          key: Key('allergen-${allergen.name}'),
                          label: Text(allergen.label),
                          labelStyle: _chipLabel(_allergies.contains(allergen)),
                          checkmarkColor: Colors.white,
                          selected: _allergies.contains(allergen),
                          onSelected: (value) => setState(() {
                            value
                                ? _allergies.add(allergen)
                                : _allergies.remove(allergen);
                          }),
                        ),
                      for (final custom in _custom)
                        InputChip(
                          key: Key('custom-allergy-$custom'),
                          label: Text(custom),
                          labelStyle: _chipLabel(true),
                          selected: true,
                          showCheckmark: false,
                          deleteIconColor: Colors.white,
                          onDeleted: () =>
                              setState(() => _custom.remove(custom)),
                          deleteButtonTooltipMessage: 'Remove $custom',
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    key: const Key('custom-allergy-input'),
                    controller: _customController,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _addCustom(),
                    decoration: InputDecoration(
                      hintText: 'Add your own ingredient',
                      prefixIcon: const Icon(Icons.edit_outlined),
                      suffixIcon: IconButton(
                        tooltip: 'Add allergy',
                        onPressed: _addCustom,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SectionLabel('My diet'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final diet in Diet.values)
                        ChoiceChip(
                          key: Key('diet-${diet.name}'),
                          label: Text(diet.label),
                          labelStyle: _chipLabel(_diet == diet),
                          checkmarkColor: Colors.white,
                          selected: _diet == diet,
                          onSelected: (_) => setState(() => _diet = diet),
                        ),
                    ],
                  ),
                  if (_diet != Diet.none) ...[
                    const SizedBox(height: 12),
                    Text(
                      _dietHint(_diet),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [FilledButton(onPressed: _save, child: const Text('Save'))],
      ),
    );
  }

  /// Selected chips darken to charcoal, so text strictly turns pure white.
  static TextStyle _chipLabel(bool selected) => TextStyle(
    color: selected ? Colors.white : AppColors.charcoal,
    fontWeight: FontWeight.w500,
  );

  static String _dietHint(Diet diet) => switch (diet) {
    Diet.none => '',
    Diet.vegetarian => 'No meat, poultry, fish or seafood.',
    Diet.vegan => 'No animal products, including dairy and eggs.',
    Diet.halal => 'No pork or alcohol.',
  };
}
