import 'package:bookshelf/bootstrap.dart';
import 'package:bookshelf/services/book_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('existing accounts remain isolated and List handles Back', (
    tester,
  ) async {
    const email = String.fromEnvironment('testEmail');
    const emptyEmail = String.fromEnvironment('emptyEmail');
    const password = String.fromEnvironment('testPassword');
    expect(emptyEmail, isNotEmpty);
    await startBookShelf();
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(finder, findsWidgets);
    }

    Future<void> bottom() async {
      final finder = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      final scroll = tester.state<ScrollableState>(finder);
      for (var i = 0; i < 3; i++) {
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emptyEmail,
      password: password,
    );
    await waitFor(find.text(emptyEmail));
    await bottom();
    await waitFor(find.text('No books found'));
    expect(
      await BookRepository(
        FirebaseAuth.instance.currentUser!.uid,
      ).watchBooks().first,
      isEmpty,
    );
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('22-empty-state');
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await waitFor(find.text(email));
    await bottom();
    await waitFor(find.text('Books: 4'));
    final books = await BookRepository(
      FirebaseAuth.instance.currentUser!.uid,
    ).watchBooks().first;
    expect(books, hasLength(4));
    expect(books.any((book) => book.title == 'Dune Revised'), isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('List'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    await binding.takeScreenshot('23-account-isolation');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
