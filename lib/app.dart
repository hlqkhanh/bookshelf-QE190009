import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/list_screen.dart';
import 'services/book_repository.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

class BookShelfApp extends StatelessWidget {
  const BookShelfApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BookShelf',
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: messengerKey,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF276454)),
      scaffoldBackgroundColor: const Color(0xFFF7F6F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F6F0),
        centerTitle: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ),
    home: const _AuthGate(),
  );
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final StreamSubscription<User?> _subscription;
  User? _user;
  BookRepository? _repository;
  bool _checking = true;
  bool _registrationPending = false;
  String _page = 'Home';
  String? _selectedId, _authError;

  @override
  void initState() {
    super.initState();
    _subscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (!mounted) return;
        messengerKey.currentState?.clearSnackBars();
        setState(() {
          _user = user;
          _checking = false;
          _page = 'Home';
          _selectedId = null;
          _authError = null;
          _repository = user == null ? null : BookRepository(user.uid);
        });
        _showRegistrationMessage();
      },
      onError: (Object error) {
        if (mounted) {
          setState(() {
            _checking = false;
            _authError = error.toString();
          });
        }
      },
    );
  }

  void _showRegistrationMessage() {
    if (!_registrationPending || _user == null) return;
    _registrationPending = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _user != null) {
        messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Registration successful')),
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_authError != null) {
      return Scaffold(body: Center(child: Text(_authError!)));
    }
    if (_user != null) {
      return IndexedStack(
        index: _selectedId == null ? 0 : 1,
        children: [
          ListScreen(
            key: ValueKey(_user!.uid),
            user: _user!,
            repository: _repository!,
            onOpen: (id) => setState(() => _selectedId = id),
          ),
          if (_selectedId != null)
            DetailScreen(
              key: ValueKey(_selectedId),
              id: _selectedId!,
              repository: _repository!,
              onBack: () => setState(() => _selectedId = null),
            )
          else
            const SizedBox.shrink(),
        ],
      );
    }
    if (_page != 'Home') {
      return AuthScreen(
        key: ValueKey(_page),
        register: _page == 'Register',
        onBack: () => setState(() => _page = 'Home'),
        onRegistered: () {
          _registrationPending = true;
          _showRegistrationMessage();
        },
      );
    }
    return HomeScreen(
      onLogin: () => setState(() => _page = 'Login'),
      onRegister: () => setState(() => _page = 'Register'),
    );
  }
}
