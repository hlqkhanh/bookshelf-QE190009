import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../validation.dart';
import '../widgets/shared.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.register,
    required this.onBack,
    required this.onRegistered,
  });
  final bool register;
  final VoidCallback onBack, onRegistered;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _submitted = false, _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final registered = widget.onRegistered;
    try {
      if (widget.register) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        registered();
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.register ? 'Register' : 'Login';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_busy) widget.onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(label),
          leading: BackButton(onPressed: _busy ? null : widget.onBack),
        ),
        body: Content(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Panel(
                child: Form(
                  key: _form,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.register
                            ? 'Create your library'
                            : 'Welcome back',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.register
                            ? 'Your next chapter starts here.'
                            : 'Sign in to your private BookShelf.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: Validation.email,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: true,
                        autofillHints: [
                          widget.register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        onChanged: (_) {
                          if (_submitted && widget.register) {
                            _form.currentState!.validate();
                          }
                        },
                        validator: (value) => Validation.password(
                          value,
                          register: widget.register,
                        ),
                      ),
                      if (widget.register) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirm,
                          enabled: !_busy,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                          ),
                          validator: (value) =>
                              Validation.confirm(value, _password.text),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(_busy ? 'Please wait…' : label),
                      ),
                      FormError(_error),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
