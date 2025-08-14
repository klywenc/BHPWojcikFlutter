import 'package:flutter/material.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BHP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
      routes: {
        '/': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}
