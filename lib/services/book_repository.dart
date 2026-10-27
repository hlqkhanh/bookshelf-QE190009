import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class DuplicateBookException implements Exception {
  @override
  String toString() => 'A book with this title and author already exists.';
}

class BookRepository {
  BookRepository(this.userId, {FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _books =>
      _db.collection('books');

  Stream<List<Book>> watchBooks() => _books
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Book.fromMap(doc.data())).toList(),
      );

  Stream<Book?> watchBook(String id) => _books
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Book.fromMap(doc.data()!) : null);

  Future<String> save(Book book, {Book? previous}) async {
    if (book.userId != userId) throw StateError('Invalid book owner');
    final target = _books.doc(book.id);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(target);
      if (previous == null || previous.id != book.id) {
        if (existing.exists) throw DuplicateBookException();
        final data = book.toMap();
        if (previous != null) {
          final old = await transaction.get(_books.doc(previous.id));
          if (!old.exists) throw StateError('This book no longer exists.');
          data['favorite'] = old.data()!['favorite'];
          data['createdAt'] = old.data()!['createdAt'];
          transaction.delete(old.reference);
        }
        transaction.set(target, data);
      } else {
        if (!existing.exists) throw StateError('This book no longer exists.');
        // Preserve current favorite and createdAt if they changed during editing.
        final data = book.toMap()
          ..['favorite'] = existing.data()!['favorite']
          ..['createdAt'] = existing.data()!['createdAt'];
        transaction.update(target, data);
      }
    });
    return book.id;
  }

  Future<void> toggleFavorite(Book book) =>
      _db.runTransaction((transaction) async {
        final ref = _books.doc(book.id);
        final doc = await transaction.get(ref);
        if (!doc.exists) throw StateError('This book no longer exists.');
        transaction.update(ref, {
          'favorite': !(doc.data()!['favorite'] as bool? ?? false),
        });
      });

  Future<void> delete(Book book) => _books.doc(book.id).delete();
}
