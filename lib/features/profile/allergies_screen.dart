import 'package:flutter/material.dart';

import '../../core/widgets/frigo_widgets.dart';

/// `9. Allergies and diet` — allergens hide recipes, diet filters them.
class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({super.key});

  static const allergens = [
    'Peanuts',
    'Tree nuts',
    'Milk',
    'Eggs',
    'Gluten',
    'Fish',
    'Shellfish',
    'Soy',
    'Sesame',
  ];

  static const diets = ['None', 'Vegetarian', 'Vegan', 'Halal'];

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  final Set<String> _selectedAllergens = {};
  String _diet = AllergiesScreen.diets.first;

  @override
  Widget build(BuildContext context) {
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
                        'Recipes with these ingredients are hidden from your suggestions.',
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel("I'm allergic to"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final allergen in AllergiesScreen.allergens)
                        FilterChip(
                          label: Text(allergen),
                          selected: _selectedAllergens.contains(allergen),
                          onSelected: (value) => setState(() {
                            value
                                ? _selectedAllergens.add(allergen)
                                : _selectedAllergens.remove(allergen);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('My diet'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final diet in AllergiesScreen.diets)
                        ChoiceChip(
                          label: Text(diet),
                          selected: _diet == diet,
                          onSelected: (_) => setState(() => _diet = diet),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
