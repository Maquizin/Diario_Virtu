import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/tela_principal.dart';
import 'screens/tela_aparencia.dart';
import 'theme/tema.dart';
import 'widgets/fundo_animado.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await temaController.carregar(); // lê o tema que o usuário escolheu

  runApp(const DiarioApp());
}

class DiarioApp extends StatelessWidget {
  const DiarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Reconstrói o app inteiro sempre que o usuário troca de tema.
    return ListenableBuilder(
      listenable: temaController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Diário com IA',
          debugShowCheckedModeBanner: false,
          theme: temaController.themeData,

          // O fundo animado fica atrás de TODAS as telas.
          builder: (context, child) => FundoAnimado(
            tema: temaController.tema,
            destaque: temaController.destaque,
            child: child ?? const SizedBox.shrink(),
          ),

          initialRoute: '/',

          routes: {
            '/': (context) => const AuthGate(),
            '/login': (context) => LoginScreen(),
            '/diario': (context) => const TelaPrincipal(),
            '/aparencia': (context) => const TelaAparencia(),
          },
        );
      },
    );
  }
}