import 'package:flutter/material.dart';

import '../router/app_router.dart';
import 'frigo_widgets.dart';

/// Shown by the router for unknown locations.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FrigoLogo(),
              const SizedBox(height: 24),
              Text(
                'We could not find "$location".',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: context.goToFridge,
                child: const Text('Open the fridge'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
