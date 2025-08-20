import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Color get _brandDark  => const Color(0xFFC62828);
  Color get _brandLight => const Color(0xFFFF8A80);
  Color get _brandPale  => const Color(0xFFFFE0E0);

  @override
  Widget build(BuildContext context) {
    final args  = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;
    final email = (args['email'] ?? 'USER').toString();
    final base  = (args['base']  ?? '').toString();

    void go(String route) {
      Navigator.of(context).pushNamed(route, arguments: {'email': email, 'base': base});
    }

    Future<void> logout() async {
      final sp = await SharedPreferences.getInstance();
      await sp.remove('accessToken');
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }

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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Image.asset('assets/images/logo.png', height: 34),
              ),
              Expanded(
                child: Text(
                  'Cześć, $email',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(child: Icon(Icons.person)),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _brandDark.withOpacity(0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                      child: Column(
                        children: [
                          _MenuButton(
                            color: _brandDark,
                            icon: Icons.checklist_outlined,
                            text: 'Rozpocznij audyt',
                            onTap: () => go('/audit/new'),
                          ),
                          const SizedBox(height: 10),
                          _MenuButton(
                            color: _brandDark,
                            icon: Icons.report_problem_outlined,
                            text: 'Stwórz incydent',
                            onTap: () => go('/incident/new'),
                          ),
                          const SizedBox(height: 10),
                          _MenuButton(
                            color: _brandDark,
                            icon: Icons.history,
                            text: 'Historia',
                            onTap: () => go('/history'),
                          ),
                          const SizedBox(height: 10),
                          _MenuButton(
                            color: Colors.black87,
                            icon: Icons.logout,
                            text: 'Wyloguj się',
                            isFilled: false,
                            onTap: logout,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.text,
    required this.onTap,
    required this.color,
    this.isFilled = true,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color color;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final btn = isFilled
        ? FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: onTap,
            icon: const Icon(Icons.chevron_right, size: 20),
            label: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(text)),
              ],
            ),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: onTap,
            icon: Icon(icon, size: 20),
            label: Text(text),
          );

    return SizedBox(width: double.infinity, child: btn);
  }
}
