import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/widgets/frigo_widgets.dart';

/// Recipe filters available on the `6. What to cook` screen.
enum RecipeFilter {
  allergySafe('Allergy-safe'),
  under20Min('Under 20 min'),
  vegetarian('Vegetarian'),
  usesExpiring('Uses expiring');

  const RecipeFilter(this.label);

  final String label;
}

/// `6. What to cook` — ranked recipe suggestions.
class RecipeSuggestionsScreen extends StatefulWidget {
  const RecipeSuggestionsScreen({super.key});

  @override
  State<RecipeSuggestionsScreen> createState() =>
      _RecipeSuggestionsScreenState();
}

class _RecipeSuggestionsScreenState extends State<RecipeSuggestionsScreen> {
  final Set<RecipeFilter> _filters = {RecipeFilter.allergySafe};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'What to cook',
              subtitle: 'Ranked by what is in your fridge',
              showBack: true,
              trailing: [FrigoAvatar(onTap: context.pushProfile)],
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: RecipeFilter.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = RecipeFilter.values[index];
                  final selected = _filters.contains(filter);
                  return FilterChip(
                    label: Text(filter.label),
                    selected: selected,
                    onSelected: (value) => setState(() {
                      value ? _filters.add(filter) : _filters.remove(filter);
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
