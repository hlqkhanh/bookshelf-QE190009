import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_repository.dart';
import '../widgets/book_form.dart';
import '../widgets/shared.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
    required this.user,
    required this.repository,
    required this.onOpen,
  });
  final User user;
  final BookRepository repository;
  final ValueChanged<String> onOpen;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _search = TextEditingController();
  late final Stream<List<Book>> _stream;
  String _genre = 'All', _status = 'All';
  bool _favorites = false, _loggingOut = false;
  final _toggling = <String>{};

  @override
  void initState() {
    super.initState();
    _stream = widget.repository.watchBooks();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggle(Book book) async {
    setState(() => _toggling.add(book.id));
    try {
      await widget.repository.toggleFavorite(book);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error));
    } finally {
      if (mounted) setState(() => _toggling.remove(book.id));
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error));
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Widget _filter(
    String label,
    String value,
    List<String> choices,
    ValueChanged<String> onChange,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$label-$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      'All',
      ...choices,
    ].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
    onChanged: (value) => onChange(value!),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('List'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.user.email ?? '', softWrap: true),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loggingOut ? null : _logout,
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Content(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Your private library',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: const Text('Add a book'),
                leading: const Icon(Icons.add_circle_outline),
                maintainState: true,
                childrenPadding: const EdgeInsets.all(20),
                children: [BookForm(repository: widget.repository)],
              ),
            ),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Find your next read',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  _filter(
                    'Genre filter',
                    _genre,
                    genres,
                    (value) => setState(() => _genre = value),
                  ),
                  const SizedBox(height: 16),
                  _filter(
                    'Status filter',
                    _status,
                    statuses,
                    (value) => setState(() => _status = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      hintText: 'Title or author',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Favorites only'),
                    value: _favorites,
                    onChanged: (value) => setState(() => _favorites = value),
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _genre = 'All';
                      _status = 'All';
                      _favorites = false;
                      _search.clear();
                    }),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            StreamBuilder<List<Book>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Panel(child: FormError(errorMessage(snapshot.error!)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final books = visibleBooks(
                  snapshot.data!,
                  genre: _genre,
                  status: _status,
                  favoritesOnly: _favorites,
                  search: _search.text,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Summary',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text('Books: ${books.length}'),
                          Text(
                            'Favorites: ${books.where((book) => book.favorite).length}',
                          ),
                          ...statusBreakdown(books).map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text(entry.key)),
                                  Text('${entry.value}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (books.isEmpty)
                      const Panel(child: Center(child: Text('No books found'))),
                    ...books.map(
                      (book) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          title: Text(
                            book.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${book.author}\n${book.genre} · ${book.status}',
                            ),
                          ),
                          isThreeLine: true,
                          onTap: () => widget.onOpen(book.id),
                          trailing: IconButton(
                            tooltip: book.favorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            onPressed: _toggling.contains(book.id)
                                ? null
                                : () => _toggle(book),
                            icon: Icon(
                              book.favorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: book.favorite
                                  ? const Color(0xFF986500)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
