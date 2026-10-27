import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_repository.dart';
import '../validation.dart';
import 'shared.dart';

class BookForm extends StatefulWidget {
  const BookForm({
    super.key,
    required this.repository,
    this.book,
    this.onSaved,
    this.onCancel,
  });
  final BookRepository repository;
  final Book? book;
  final ValueChanged<String>? onSaved;
  final VoidCallback? onCancel;

  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _author, _rating, _notes;
  String _genre = '', _status = '';
  bool _submitted = false, _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _title = TextEditingController(text: book?.title ?? '');
    _author = TextEditingController(text: book?.author ?? '');
    _rating = TextEditingController(text: book?.rating?.toString() ?? '');
    _notes = TextEditingController(text: book?.notes ?? '');
    _genre = book?.genre ?? '';
    _status = book?.status ?? '';
  }

  @override
  void dispose() {
    for (final controller in [_title, _author, _rating, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final previous = widget.book;
    final book = Book(
      id: bookId(widget.repository.userId, _title.text, _author.text),
      userId: widget.repository.userId,
      title: _title.text.trim(),
      author: _author.text.trim(),
      genre: _genre,
      status: _status,
      rating: int.tryParse(_rating.text.trim()),
      notes: _notes.text,
      favorite: previous?.favorite ?? false,
      createdAt: previous?.createdAt,
    );
    try {
      final id = await widget.repository.save(book, previous: previous);
      if (!mounted) return;
      if (previous == null) {
        for (final controller in [_title, _author, _rating, _notes]) {
          controller.clear();
        }
        setState(() {
          _genre = '';
          _status = '';
          _submitted = false;
        });
        _form.currentState!.reset();
      }
      showMessage(context, previous == null ? 'Book added' : 'Book saved');
      widget.onSaved?.call(id);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    autovalidateMode: _submitted
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.book == null ? 'Add a book' : 'Edit book',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _title,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Title'),
          validator: Validation.title,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _author,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Author'),
          validator: Validation.author,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('genre-$_genre'),
          initialValue: _genre,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Genre'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Choose genre')),
            ...genres.map(
              (value) => DropdownMenuItem(value: value, child: Text(value)),
            ),
          ],
          onChanged: _busy
              ? null
              : (value) => setState(() => _genre = value ?? ''),
          validator: (value) =>
              value == null || value.isEmpty ? 'Please choose a genre' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('status-$_status'),
          initialValue: _status,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Status'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Choose status')),
            ...statuses.map(
              (value) => DropdownMenuItem(value: value, child: Text(value)),
            ),
          ],
          onChanged: _busy
              ? null
              : (value) => setState(() => _status = value ?? ''),
          validator: (value) =>
              value == null || value.isEmpty ? 'Please choose a status' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _rating,
          enabled: !_busy,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Rating (optional)',
            hintText: '0–5',
          ),
          validator: Validation.rating,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notes,
          enabled: !_busy,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
          validator: Validation.notes,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(
            _busy
                ? 'Saving…'
                : widget.book == null
                ? 'Add book'
                : 'Save',
          ),
        ),
        if (widget.onCancel != null)
          TextButton(
            onPressed: _busy ? null : widget.onCancel,
            child: const Text('Cancel'),
          ),
        FormError(_error),
      ],
    ),
  );
}
