import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

String errorMessage(Object error) => error is FirebaseException
    ? (error.message ?? error.code)
    : error.toString().replaceFirst('Bad state: ', '');

class Content extends StatelessWidget {
  const Content({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: child,
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class FormError extends StatelessWidget {
  const FormError(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(
              message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
