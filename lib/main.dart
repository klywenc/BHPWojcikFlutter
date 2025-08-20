import 'package:flutter/material.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/home/home_page.dart';
import 'features/incidents/new_incident_page.dart';
import 'features/incidents/history_page.dart';
import 'features/incidents/preview_incident_page.dart';
import 'features/audit/audit_preview_page.dart';
import 'features/audit/new_audit_finding_page.dart';

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
        '/':             (_) => const LoginPage(),
        '/home':         (_) => const HomePage(),
        '/register':     (_) => const RegisterPage(),
        '/incident/new': (_) => const NewIncidentPage(),
        '/history':      (_) => const HistoryPage(),
        '/incident/preview': (_) => const PreviewIncidentPage(),
        '/audit/preview': (ctx) => const AuditPreviewPage(),
        '/audit/new': (ctx) => const NewAuditFindingPage(),
      },
    );
  }
}
