import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/tela_principal.dart';
import 'screens/tela_aparencia.dart';
import 'services/acessibilidade_service.dart';
import 'services/bloqueio_biometrico.dart';
import 'services/gerador_relatorios.dart';
import 'theme/tema.dart';
import 'widgets/fundo_animado.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Só em pé (sem girar a tela).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Tela cheia: esconde as barras do Android; aparecem ao arrastar da borda.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp();
  await temaController.carregar(); // lê o tema que o usuário escolheu
  await acessibilidade.carregar(); // lê as opções de acessibilidade
  geradorRelatorios.iniciar(); // retoma relatórios que ficaram pendentes

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
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: mensagensKey,
          theme: temaController.themeData,

          // Acessibilidade por fora de tudo; o fundo animado fica atrás
          // de TODAS as telas.
          builder: (context, child) => AcessibilidadeAplicada(
            child: PortaoBiometrico(
              child: FundoAnimado(
                tema: temaController.tema,
                destaque: temaController.destaque,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
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