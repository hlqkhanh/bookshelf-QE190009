import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';

Future<void> startBookShelf() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Android reads Firebase's public client values from google-services.json.
    await Firebase.initializeApp();
    const emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
    if (emulatorHost.isNotEmpty) {
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }
    runApp(const BookShelfApp());
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                'Firebase setup required\n\nAdd your Android client configuration at '
                'android/app/google-services.json, then rebuild the app.\n\n$error',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
