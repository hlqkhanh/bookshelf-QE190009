import 'package:bookshelf/screens/home_screen.dart';
import 'package:bookshelf/services/book_repository.dart';
import 'package:bookshelf/widgets/book_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class NoNetworkRepository implements BookRepository {
  @override
  String get userId => 'alice';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'Home displays required entry points and feature cards on phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(onLogin: () {}, onRegister: () {}),
        ),
      );
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('BookShelf'), findsNWidgets(2));
      expect(find.text('Track your books'), findsOneWidget);
      expect(find.text('Sort by status'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Rate your favorites'), 250);
      expect(find.text('Rate your favorites'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Add starts clean, validates on submit, clears valid field error',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BookForm(repository: NoNetworkRepository()),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Title is required'), findsNothing);
      final button = find.widgetWithText(FilledButton, 'Add book');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Author is required'), findsOneWidget);
      expect(find.text('Please choose a genre'), findsOneWidget);
      expect(find.text('Please choose a status'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Dune');
      await tester.pumpAndSettle();
      expect(find.text('Title is required'), findsNothing);
      expect(find.text('Author is required'), findsOneWidget);
    },
  );
}
