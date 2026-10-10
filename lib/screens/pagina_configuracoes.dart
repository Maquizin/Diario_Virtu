// lib/screens/pagina_configuracoes.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_screen.dart';
import 'privacidade_screen.dart';
import 'acessibilidade_screen.dart';
import 'package:flutter/foundation.dart';
import '../services/diario_service.dart';
import '../theme/tema.dart';
import '../widgets/animacoes.dart';

class PaginaConfiguracoes extends StatelessWidget {
  const PaginaConfiguracoes({super.key});

  Future<void> _sair(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cores = context.cores;

    return SafeArea(
      // ListView em vez de Column: não estoura a tela quando tem muitas opções.
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Text(
            'Configurações',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),

          // Foto de perfil, com um anel na cor de destaque
          EntradaSuave(
            child: Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cores.destaque,
                          cores.destaque.withValues(alpha: 0.25),
                        ],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: cores.cardSuave,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Icon(Icons.person,
                              size: 50, color: cores.textoSecundario)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Em breve: trocar foto de perfil')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cores.destaque,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          EntradaSuave(
            delay: const Duration(milliseconds: 60),
            child: Center(
              child: Text(
                user?.displayName ?? user?.email ?? 'Usuário',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 30),

          _opcaoConfig(
            context,
            ordem: 1,
            icone: Icons.palette_outlined,
            cor: cores.destaque,
            titulo: 'Aparência',
            subtitulo: 'Temas, cores e fundo animado',
            onTap: () => Navigator.pushNamed(context, '/aparencia'),
          ),

          _opcaoConfig(
            context,
            ordem: 2,
            icone: Icons.lock_outline,
            cor: Colors.purpleAccent,
            titulo: 'Privacidade',
            subtitulo: 'Controle o que o psicólogo pode acessar',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacidadeScreen()),
              );
            },
          ),

          _opcaoConfig(
            context,
            ordem: 3,
            icone: Icons.accessibility_new,
            cor: Colors.blueAccent,
            titulo: 'Acessibilidade',
            subtitulo: 'Texto, contraste e mais',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AcessibilidadeScreen()),
              );
            },
          ),

          _opcaoConfig(
            context,
            ordem: 4,
            icone: Icons.logout,
            cor: Colors.redAccent,
            titulo: 'Sair da conta',
            subtitulo: 'Encerrar sessão',
            onTap: () => _sair(context),
          ),

          if (kDebugMode) ...[
            _opcaoConfig(
              context,
              ordem: 5,
              icone: Icons.science_outlined,
              cor: Colors.orangeAccent,
              titulo: 'Gerar dados de teste',
              subtitulo: 'Cria registros fictícios do mês passado',
              onTap: () async {
                final agora = DateTime.now();
                await DiarioService()
                    .criarDadosDeTeste(DateTime(agora.year, agora.month - 1));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Dados de teste criados (mês passado)')),
                  );
                }
              },
            ),
            _opcaoConfig(
              context,
              ordem: 6,
              icone: Icons.delete_sweep_outlined,
              cor: Colors.grey,
              titulo: 'Apagar dados de teste',
              subtitulo: 'Remove só os registros de teste',
              onTap: () async {
                await DiarioService().apagarDadosDeTeste();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dados de teste apagados')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _opcaoConfig(
    BuildContext context, {
    required int ordem,
    required IconData icone,
    required Color cor,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    final cores = context.cores;

    return EntradaSuave(
      delay: Duration(milliseconds: 120 + ordem * 70),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cores.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: cor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitulo,
                        style: TextStyle(
                            color: cores.textoSecundario, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cores.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}