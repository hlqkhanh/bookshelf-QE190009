import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_repository.dart';
import '../widgets/book_form.dart';
import '../widgets/shared.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.id,
    required this.repository,
    required this.onBack,
  });
  final String id;
  final BookRepository repository;
  final VoidCallback onBack;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Stream<Book?> _stream;
  Book? _editingBook;
  bool _editing = false, _busy = false;
  @override
  void initState() {
    super.initState();
    _stream = widget.repository.watchBook(widget.id);
  }

  Future<void> _toggle(Book book) async {
    setState(() => _busy = true);
    try {
      await widget.repository.toggleFavorite(book);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('Delete “${book.title}” from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.delete(book);
      if (mounted) widget.onBack();
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '—' : value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_busy) widget.onBack();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Detail'),
        leading: BackButton(onPressed: _busy ? null : widget.onBack),
      ),
      body: Content(
        child: StreamBuilder<Book?>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: FormError(errorMessage(snapshot.error!)),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // A rename deletes the old document before the transaction future
            // resolves. Keep the form alive until its onSaved switches streams.
            final book = _editing ? _editingBook : snapshot.data;
            if (book == null) {
              return const Center(child: Text('No books found'));
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Panel(
                  child: _editing
                      ? BookForm(
                          repository: widget.repository,
                          book: book,
                          onCancel: () => setState(() => _editing = false),
                          onSaved: (id) => setState(() {
                            _stream = widget.repository.watchBook(id);
                            _editing = false;
                          }),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              book.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 20),
                            _field('Title', book.title),
                            _field('Author', book.author),
                            _field('Genre', book.genre),
                            _field('Status', book.status),
                            _field('Rating', book.rating?.toString() ?? ''),
                            _field('Notes', book.notes),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                tooltip: book.favorite
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                                onPressed: _busy ? null : () => _toggle(book),
                                icon: Icon(
                                  book.favorite
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: book.favorite
                                      ? const Color(0xFF986500)
                                      : null,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                      _editingBook = book;
                                      _editing = true;
                                    }),
                              child: const Text('Edit'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _busy ? null : () => _delete(book),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
