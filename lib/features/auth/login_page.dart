import 'package:flutter/material.dart';
import '../../core/api_client.dart';

const String kDefaultBase = 'http://192.168.43.156:8080';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _serverCtrl = TextEditingController(text: kDefaultBase);
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  String _status = '—';
  bool _loading = false;

  Future<void> _check() async {
    setState(() { _loading = true; _status = 'Sprawdzam…'; });
    final api = ApiClient(_serverCtrl.text.trim());
    final (ok, msg) = await api.checkServer();
    setState(() {
      _loading = false;
      _status = ok ? 'Połączenie z serwerem jest OK ($msg)' : 'Błąd: $msg';
    });
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; });
    final api = ApiClient(_serverCtrl.text.trim());
    final (ok, msg) = await api.checkServer();
    setState(() { _loading = false; _status = ok ? 'OK' : 'Błąd: $msg'; });
    if (!ok) return;

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home', arguments: {
      'email': _emailCtrl.text.trim(),
      'base':  _serverCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Adres e-mail',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) => (v==null || v.isEmpty) ? 'Podaj e-mail' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Hasło',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      child: Text(_loading ? 'Loguję…' : 'Zaloguj się'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : _check,
                      child: const Text('Sprawdź połączenie'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _status.startsWith('Połączenie z serwerem jest OK')
                              ? Icons.check_circle : Icons.info_outline,
                          color: _status.startsWith('Połączenie') ? Colors.green : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_status, maxLines: 2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
