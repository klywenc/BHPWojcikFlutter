import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _codeCtrl  = TextEditingController();

  bool _loading = false;
  String _status = '—';

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final base = (args['base'] as String?) ?? 'http://192.168.191.2:8080';
    final api = ApiClient(base);

    setState(() { _loading = true; _status = 'Rejestruję…'; });
    final (ok, msg) = await api.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      registrationCode: _codeCtrl.text.trim(),
    );
    setState(() { _loading = false; _status = ok ? 'Konto utworzone' : 'Błąd: $msg'; });

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stwórz konto')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Imię i nazwisko'),
                    validator: (v) => (v==null || v.isEmpty) ? 'Podaj imię i nazwisko' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (v) => (v==null || v.isEmpty) ? 'Podaj e-mail' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(labelText: 'Hasło'),
                    obscureText: true,
                    validator: (v) => (v!=null && v.length>=6) ? null : 'Min. 6 znaków',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(labelText: 'Kod rejestracyjny'),
                    validator: (v) => (v==null || v.isEmpty) ? 'Podaj kod' : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? 'Rejestruję…' : 'Zarejestruj'),
                  ),
                  const SizedBox(height: 8),
                  Text(_status),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
