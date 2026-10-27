import 'package:flutter/material.dart';
import '../widgets/shared.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });
  final VoidCallback onLogin, onRegister;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('BookShelf')),
    body: Content(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton(onPressed: onLogin, child: const Text('Login')),
              FilledButton(
                onPressed: onRegister,
                child: const Text('Register'),
              ),
            ],
          ),
          const SizedBox(height: 36),
          Icon(
            Icons.auto_stories_rounded,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'BookShelf',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'A little space for your next great read. Keep your books, reading progress, and favorite stories together in your private library.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...const [
            (
              Icons.library_books_outlined,
              'Track your books',
              'Save every title and author in your own private collection.',
            ),
            (
              Icons.bookmarks_outlined,
              'Sort by status',
              'From To Read to Finished, follow your reading journey.',
            ),
            (
              Icons.star_outline_rounded,
              'Rate your favorites',
              'Keep ratings and notes for the stories you love.',
            ),
          ].map(
            (feature) => Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(feature.$1),
                  const SizedBox(height: 12),
                  Text(
                    feature.$2,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(feature.$3),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
