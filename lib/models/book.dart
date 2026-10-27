import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

const genres = ['Fiction', 'Non-Fiction', 'Academic', 'Other'];
const statuses = ['To Read', 'Reading', 'Finished'];

String bookId(String userId, String title, String author) {
  String digest(String value) =>
      sha256.convert(utf8.encode(value.trim().toLowerCase())).toString();
  return '${userId}__${digest(title)}_${digest(author)}';
}

class Book {
  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    this.rating,
    this.favorite = false,
    this.notes = '',
    this.createdAt,
  });

  final String id, userId, title, author, genre, status, notes;
  final int? rating;
  final bool favorite;
  final Timestamp? createdAt;

  factory Book.fromMap(Map<String, dynamic> data) => Book(
    id: data['id'] as String,
    userId: data['userId'] as String,
    title: data['title'] as String,
    author: data['author'] as String,
    genre: data['genre'] as String,
    status: data['status'] as String,
    rating: data['rating'] as int?,
    favorite: data['favorite'] as bool? ?? false,
    notes: data['notes'] as String? ?? '',
    createdAt: data['createdAt'] as Timestamp?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'author': author,
    'genre': genre,
    'status': status,
    'rating': rating,
    'favorite': favorite,
    'notes': notes,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };
}

List<Book> visibleBooks(
  Iterable<Book> books, {
  String genre = 'All',
  String status = 'All',
  bool favoritesOnly = false,
  String search = '',
}) {
  final query = search.trim().toLowerCase();
  final result = books
      .where(
        (book) =>
            (genre == 'All' || book.genre == genre) &&
            (status == 'All' || book.status == status) &&
            (!favoritesOnly || book.favorite) &&
            (book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query)),
      )
      .toList();
  result.sort((a, b) {
    final title = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return title != 0
        ? title
        : a.author.toLowerCase().compareTo(b.author.toLowerCase());
  });
  return result;
}

List<MapEntry<String, int>> statusBreakdown(Iterable<Book> books) {
  final counts = <String, int>{};
  for (final book in books) {
    counts.update(book.status, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts.entries.toList()..sort((a, b) {
    final count = b.value.compareTo(a.value);
    return count != 0
        ? count
        : statuses.indexOf(a.key).compareTo(statuses.indexOf(b.key));
  });
}
