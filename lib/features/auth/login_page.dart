import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';

const String kDefaultBase = 'http://192.168.191.2:8080';

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
  bool _obscure = true;

  Color get _brandDark   => const Color(0xFFC62828);
  Color get _brandLight  => const Color(0xFFFF8A80);
  Color get _brandPale   => const Color(0xFFFFE0E0);

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

    setState(() { _loading = true; _status = 'Loguję…'; });
    final base = _serverCtrl.text.trim();
    final api = ApiClient(base);

    final (okPing, msgPing) = await api.checkServer();
    if (!okPing) {
      setState(() { _loading = false; _status = 'Błąd połączenia: $msgPing'; });
      return;
    }

    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;

    final (okLogin, body) = await api.login(email: email, password: pass);

    if (!okLogin) {
      setState(() { _loading = false; _status = 'Logowanie nieudane: $body'; });
      return;
    }

    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final token = (map['accessToken'] ?? '').toString();
      if (token.isEmpty) {
        setState(() { _loading = false; _status = 'Brak accessToken w odpowiedzi serwera.'; });
        return;
      }

      final sp = await SharedPreferences.getInstance();
      await sp.setString('accessToken', token);
      await sp.setString('apiBase', base);

      setState(() { _loading = false; _status = 'Zalogowano.'; });

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home', arguments: {
        'email': email,
        'base':  base,
      });
    } catch (e) {
      setState(() { _loading = false; _status = 'Błąd parsowania odpowiedzi: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_brandPale, _brandLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, _) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16, 20, 16, bottomInset + 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo + tytuł
                          Column(
                            children: [
                              Image.asset('assets/images/logo.png',
                                  height: 88, fit: BoxFit.contain),
                              const SizedBox(height: 6),
                              Text(
                                'Panel logowania',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _brandDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Karta z polami
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _brandDark.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [

                                  TextFormField(
                                    controller: _emailCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Adres e-mail',
                                      prefixIcon: Icon(Icons.mail_outline),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Podaj e-mail'
                                            : null,
                                    keyboardType: TextInputType.emailAddress,
                                    scrollPadding:
                                        const EdgeInsets.only(bottom: 140),
                                  ),
                                  const SizedBox(height: 12),

                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscure,
                                    decoration: InputDecoration(
                                      labelText: 'Hasło',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        tooltip: _obscure
                                            ? 'Pokaż hasło'
                                            : 'Ukryj hasło',
                                        icon: Icon(_obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined),
                                        onPressed: () => setState(
                                            () => _obscure = !_obscure),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Podaj hasło'
                                        : null,
                                    onFieldSubmitted: (_) =>
                                        !_loading ? _login() : null,
                                    scrollPadding:
                                        const EdgeInsets.only(bottom: 160),
                                  ),

                                  const SizedBox(height: 16),

                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _brandDark,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      textStyle: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: _loading ? null : _login,
                                    child: Text(
                                        _loading ? 'Loguję…' : 'Zaloguj się'),
                                  ),

                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                        foregroundColor: _brandDark),
                                    icon:
                                        const Icon(Icons.person_add_outlined),
                                    label: const Text('Stwórz konto'),
                                    onPressed: _loading
                                        ? null
                                        : () async {
                                            final base =
                                                _serverCtrl.text.trim();
                                            final sp =
                                                await SharedPreferences
                                                    .getInstance();
                                            await sp.setString(
                                                'apiBase', base);
                                            if (!mounted) return;
                                            Navigator.of(context).pushNamed(
                                              '/register',
                                              arguments: {'base': base},
                                            );
                                          },
                                  ),

                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _brandDark,
                                      side: BorderSide(color: _brandDark),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                    onPressed: _loading ? null : _check,
                                    child: const Text('Sprawdź połączenie'),
                                  ),

                                  const SizedBox(height: 14),

                                  _StatusBar(
                                    text: _status,
                                    ok: _status.startsWith(
                                            'Połączenie z serwerem jest OK') ||
                                        _status == 'Zalogowano.',
                                    brandDark: _brandDark,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Opacity(
                            opacity: .8,
                            child: Text(
                              '© ${DateTime.now().year} MebleWójcik',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.text,
    required this.ok,
    required this.brandDark,
  });

  final String text;
  final bool ok;
  final Color brandDark;

  @override
  Widget build(BuildContext context) {
    final bg = ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final fg = ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final icon = ok ? Icons.check_circle : Icons.info_outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ok ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              style: TextStyle(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
