import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;
    final email = (args['email'] ?? 'USER').toString();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(child: Text('Cześć $email', overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _BigButton(text: 'Rozpocznij Audyt', onTap: () {}),
                _BigButton(text: 'Stwórz incydent', onTap: () {}),
                _BigButton(text: 'Historia', onTap: () {}),
                const Spacer(),
                _BigButton(
                  text: 'Wyloguj się',
                  onTap: () => Navigator.of(context).pushReplacementNamed('/'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _BigButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.tonal(
          onPressed: onTap,
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
