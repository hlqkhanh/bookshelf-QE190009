import 'package:bookshelf/bootstrap.dart';
import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/services/book_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Run against YOUR Firebase test project after publishing firestore.rules.
// Credentials are passed from an ignored local file, never embedded in the APK.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const email = String.fromEnvironment('testEmail');
  const password = String.fromEnvironment('testPassword');

  testWidgets('BookShelf real Firebase workflow and report screenshots', (
    tester,
  ) async {
    expect(
      email,
      isNotEmpty,
      reason: 'Pass --dart-define-from-file=report.local.json',
    );
    expect(password, isNotEmpty);
    await startBookShelf();
    await FirebaseAuth.instance.signOut();

    Future<void> until(Finder finder) async {
      for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(finder, findsWidgets);
      await tester.pumpAndSettle();
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> shot(String name) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    Finder button(String text) => find.widgetWithText(FilledButton, text);
    Future<void> login(String userEmail) async {
      await tap(find.text('Login'));
      await tester.enterText(find.byType(TextFormField).at(0), userEmail);
      await tester.enterText(find.byType(TextFormField).at(1), password);
      await tap(button('Login'));
      await until(find.text('Your private library'));
    }

    Finder select(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(DropdownButtonFormField<String>),
    );
    Future<void> choose(String label, String value) async {
      await tap(select(label));
      await tap(find.text(value).last);
    }

    Future<void> listBottom() async {
      await tester.drag(find.byType(ListView).first, const Offset(0, -1800));
      await tester.pumpAndSettle();
    }

    Future<void> addBook(
      String title,
      String author,
      String genre,
      String status,
      int rating,
    ) async {
      await tester.enterText(find.byType(TextFormField).at(0), title);
      await tester.enterText(find.byType(TextFormField).at(1), author);
      await choose('Genre', genre);
      await choose('Status', status);
      await tester.enterText(find.byType(TextFormField).at(2), '$rating');
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'A book in my personal reading collection.',
      );
      await tap(button('Add book'));
      await until(find.text('Book added'));
    }

    await until(find.text('Track your books'));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await shot('00-home');
    await tap(find.text('Login'));
    await shot('06-login');
    await tap(find.byType(BackButton));
    await tap(find.text('Register'));
    await tap(button('Register'));
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Confirm password is required'), findsOneWidget);
    await shot('04-register-validation');
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.enterText(find.byType(TextFormField).at(2), password);
    await tap(button('Register'));
    // A rerun may use the same dedicated test account; existing screenshots remain real.
    for (
      var i = 0;
      i < 100 && find.text('Your private library').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.textContaining('already').evaluate().isNotEmpty) break;
    }
    if (find.text('Your private library').evaluate().isEmpty) {
      await tap(find.byType(BackButton));
      await login(email);
    } else {
      await until(find.text('Registration successful'));
      await shot('05-register-success');
    }

    final repository = BookRepository(FirebaseAuth.instance.currentUser!.uid);
    final initial = await repository.watchBooks().first;
    await tap(find.byType(ExpansionTile));
    await tap(button('Add book'));
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Please choose a genre'), findsOneWidget);
    await tester.ensureVisible(find.text('Title is required'));
    await tester.pumpAndSettle();
    await shot('08-add-validation');
    const samples = [
      ('Dune', 'Frank Herbert', 'Fiction', 'To Read', 5),
      ('Atomic Habits', 'James Clear', 'Non-Fiction', 'Reading', 4),
      ('Clean Code', 'Robert C. Martin', 'Academic', 'Finished', 4),
      (
        'A Brief History of Time',
        'Stephen Hawking',
        'Non-Fiction',
        'Reading',
        5,
      ),
      (
        'The Little Prince',
        'Antoine de Saint-Exupery',
        'Fiction',
        'Finished',
        5,
      ),
    ];
    for (final sample in samples) {
      if (initial.any(
        (book) => book.title == sample.$1 && book.author == sample.$2,
      )) {
        continue;
      }
      await addBook(sample.$1, sample.$2, sample.$3, sample.$4, sample.$5);
      await shot('09-add-success');
    }
    await tester.ensureVisible(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    await tap(find.byType(ExpansionTile));

    // Verify duplicate writes do not add a second row.
    final books = await repository.watchBooks().first;
    final dune = books.firstWhere((book) => book.title == 'Dune');
    await expectLater(
      repository.save(
        Book(
          id: bookId(dune.userId, 'dune', 'frank herbert'),
          userId: dune.userId,
          title: 'dune',
          author: 'frank herbert',
          genre: 'Fiction',
          status: 'To Read',
        ),
      ),
      throwsA(isA<DuplicateBookException>()),
    );

    // Favorite from the real Detail screen, then test filters on live snapshots.
    await listBottom();
    await tap(find.text('Dune'));
    await until(find.text('Detail'));
    await shot('15-detail-view');
    await tester.ensureVisible(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();
    await shot('18-favorite-before');
    await tap(find.byTooltip('Add to favorites'));
    await until(find.byTooltip('Remove from favorites'));
    await shot('19-favorite-after');
    await tap(find.byType(BackButton));

    await choose('Genre filter', 'Fiction');
    await shot('10-filter-genre');
    await tap(find.text('Clear'));
    await choose('Status filter', 'Reading');
    await shot('11-filter-status');
    await tap(find.text('Clear'));
    await tap(find.byType(Switch));
    await shot('12-filter-favorites');
    await tap(find.text('Clear'));
    await tester.enterText(find.byType(TextField).last, '  HERBERT  ');
    await tester.pumpAndSettle();
    await shot('13-filter-search');
    await tap(find.text('Clear'));
    await listBottom();
    await shot('14-summary');
    await shot('07-list-after-login');

    await tap(find.text('Dune'));
    await tap(find.text('Edit'));
    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), '');
    await tester.enterText(find.byType(TextFormField).at(2), '6');
    await tap(button('Save'));
    await tester.ensureVisible(find.text('Title is required'));
    await tester.pumpAndSettle();
    await shot('16-detail-edit-validation');
    await tester.enterText(find.byType(TextFormField).at(0), 'Dune Revised');
    await tester.enterText(find.byType(TextFormField).at(1), 'Frank Herbert');
    await tester.enterText(find.byType(TextFormField).at(2), '5');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'Updated notes, saved in Firestore.',
    );
    await tap(button('Save'));
    await until(find.text('Dune Revised'));
    await shot('17-detail-after-save');
    await tap(find.text('Delete'));
    await shot('20-delete-confirmation');
    await tap(button('Delete'));
    await until(find.text('Your private library'));
    await listBottom();
    expect(find.text('Dune Revised'), findsNothing);
    await shot('21-delete-after');

    await tap(find.text('Logout'));
    await until(find.text('Track your books'));
    await login(email);
    await listBottom();
    expect(find.text('Dune Revised'), findsNothing);
    expect(await repository.watchBooks().first, hasLength(4));
    await tap(find.text('Logout'));
    // Second account proves data isolation and gives a genuine empty-state image.
    final emptyEmail =
        'empty.${DateTime.now().millisecondsSinceEpoch}@example.com';
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emptyEmail,
      password: password,
    );
    await until(find.text('Your private library'));
    await listBottom();
    await until(find.text('No books found'));
    await shot('22-empty-state');
    await tap(find.text('Logout'));
    await until(find.text('Track your books'));
    await login(email);
    await listBottom();
    binding.reportData ??= {};
    binding.reportData!.addAll({
      'workflow': 'passed',
      'testAccount': email,
      'booksRemaining': 4,
    });
  }, timeout: const Timeout(Duration(minutes: 10)));
}
