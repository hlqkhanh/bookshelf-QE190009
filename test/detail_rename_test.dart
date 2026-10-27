import 'dart:async';
import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/screens/detail_screen.dart';
import 'package:bookshelf/services/book_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RenamingRepository implements BookRepository {
  final changes = StreamController<Book?>.broadcast();
  final committed = Completer<String>();
  Book? saved;
  final original = Book(
    id: bookId('alice', 'Dune', 'Frank Herbert'),
    userId: 'alice',
    title: 'Dune',
    author: 'Frank Herbert',
    genre: 'Fiction',
    status: 'To Read',
  );
  @override
  String get userId => 'alice';
  @override
  Stream<Book?> watchBook(String id) {
    if (id == original.id) {
      return Stream.multi((controller) {
        controller.add(original);
        final subscription = changes.stream.listen(controller.add);
        controller.onCancel = subscription.cancel;
      });
    }
    return Stream.value(saved);
  }

  @override
  Future<String> save(Book book, {Book? previous}) {
    saved = book;
    changes.add(null);
    return committed.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'rename keeps form alive while old document disappears, then shows new details',
    (tester) async {
      final repository = RenamingRepository();
      addTearDown(repository.changes.close);
      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            id: repository.original.id,
            repository: repository,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Dune Messiah');
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump();
      expect(find.text('No books found'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(4));
      repository.committed.complete(repository.saved!.id);
      await tester.pumpAndSettle();
      expect(find.text('Dune Messiah'), findsNWidgets(2));
      expect(find.byType(TextFormField), findsNothing);
    },
  );
}
