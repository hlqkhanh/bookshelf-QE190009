import 'package:flutter_test/flutter_test.dart';
import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/validation.dart';

Book sample(
  String title,
  String author, {
  String status = 'To Read',
  String genre = 'Fiction',
  bool favorite = false,
}) => Book(
  id: bookId('alice', title, author),
  userId: 'alice',
  title: title,
  author: author,
  status: status,
  genre: genre,
  favorite: favorite,
);

void main() {
  test(
    'identity normalizes case and edges, separates users and ambiguous pairs',
    () {
      expect(bookId('a', ' Dune ', 'FRANK'), bookId('a', 'dune', 'frank'));
      expect(bookId('a', 'dune', 'frank'), isNot(bookId('b', 'dune', 'frank')));
      expect(bookId('a', 'a|b', 'c'), isNot(bookId('a', 'a', 'b|c')));
    },
  );
  test(
    'all filters combine, search trims and matches authors, sorting ignores case',
    () {
      final books = [
        sample('zebra', 'Joe'),
        sample('Dune', 'Z', favorite: true),
        sample('dune', 'A', favorite: true, status: 'Reading'),
        sample('Alpha', 'Herbert', genre: 'Academic'),
      ];
      expect(visibleBooks(books).map((b) => b.author), [
        'Herbert',
        'A',
        'Z',
        'Joe',
      ]);
      expect(
        visibleBooks(
          books,
          genre: 'Fiction',
          status: 'Reading',
          favoritesOnly: true,
          search: '  DUN ',
        ).single.author,
        'A',
      );
      expect(visibleBooks(books, search: ' HERBERT ').single.title, 'Alpha');
      expect(
        visibleBooks(books, genre: 'Academic', favoritesOnly: true),
        isEmpty,
      );
      expect(
        visibleBooks([
          sample('dune', 'A', status: 'Reading'),
        ], favoritesOnly: true),
        isEmpty,
      );
    },
  );
  test(
    'summary ranks count then prescribed status order and omits empty rows',
    () {
      final rows = statusBreakdown([
        sample('a', 'a', status: 'Finished'),
        sample('b', 'b', status: 'Reading'),
        sample('c', 'c'),
        sample('d', 'd', status: 'Finished'),
      ]);
      expect(rows.map((e) => e.key), ['Finished', 'To Read', 'Reading']);
      expect(rows.map((e) => e.value), [2, 1, 1]);
      expect(statusBreakdown([]), isEmpty);
    },
  );
  test('exact required validation and length boundaries', () {
    expect(Validation.title('  '), 'Title is required');
    expect(Validation.title('a' * 100), isNull);
    expect(Validation.title('a' * 101), 'Title must be at most 100 characters');
    expect(Validation.author('a' * 61), 'Author must be at most 60 characters');
    expect(Validation.notes('a' * 301), 'Notes must be at most 300 characters');
    expect(Validation.notes('a' * 300), isNull);
    expect(Validation.email(''), 'Email is required');
    expect(Validation.email('a@'), 'Please enter a valid email address');
    expect(
      Validation.password('123', register: true),
      'Password must be at least 6 characters',
    );
    expect(Validation.password('123'), isNull);
    expect(Validation.confirm('', '123456'), 'Confirm password is required');
    expect(Validation.confirm('123', '123456'), 'Passwords do not match');
  });
  test(
    'rating accepts optional integer range and refuses fractions or out-of-range',
    () {
      for (final value in ['', '0', '5']) {
        expect(Validation.rating(value), isNull);
      }
      for (final value in ['-1', '6', '2.5', '2.0', 'hello']) {
        expect(
          Validation.rating(value),
          'Rating must be a whole number from 0 to 5',
        );
      }
    },
  );
}
