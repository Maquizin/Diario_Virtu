// lib/screens/tela_principal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tema.dart';
import 'pagina_diario.dart';
import 'pagina_historico.dart';
import 'pagina_calendario.dart';
import 'pagina_estatisticas.dart';
import 'pagina_configuracoes.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int paginaAtual = 0;

  final List<Widget> paginas = [
    PaginaHistorico(),
    const PaginaCalendario(),
    const PaginaEstatisticas(),
    const PaginaConfiguracoes(),
  ];

  void _abrirNovaAnotacao() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaginaDiario()),
    );
  }

  void _ir(int pagina) {
    HapticFeedback.lightImpact();
    setState(() => paginaAtual = pagina);
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Scaffold(
      // Transparente: o fundo animado do app aparece atrás.
      backgroundColor: Colors.transparent,

      // Troca de página com um fade suave.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey(paginaAtual),
          child: paginas[paginaAtual],
        ),
      ),

      bottomNavigationBar: Container(
        height: 80,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cores.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ItemNav(
              icone: Icons.menu_book_outlined,
              selecionado: paginaAtual == 0,
              onTap: () => _ir(0),
            ),
            _ItemNav(
              icone: Icons.calendar_today_outlined,
              selecionado: paginaAtual == 1,
              onTap: () => _ir(1),
            ),

            // "+" CENTRAL — abre a tela de nova anotação
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _abrirNovaAnotacao();
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: cores.destaque,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cores.destaque.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),

            _ItemNav(
              icone: Icons.bar_chart_rounded,
              selecionado: paginaAtual == 2,
              onTap: () => _ir(2),
            ),
            _ItemNav(
              icone: Icons.person_outline,
              selecionado: paginaAtual == 3,
              onTap: () => _ir(3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícone da barra de baixo, com "pílula" e leve aumento quando selecionado.
class _ItemNav extends StatelessWidget {
  final IconData icone;
  final bool selecionado;
  final VoidCallback onTap;

  const _ItemNav({
    required this.icone,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selecionado
              ? cores.destaque.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: AnimatedScale(
          scale: selecionado ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: Icon(
            icone,
            color: selecionado ? Colors.white : cores.textoSecundario,
          ),
        ),
      ),
    );
  }
}