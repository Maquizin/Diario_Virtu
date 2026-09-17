import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: paginas[paginaAtual],

      bottomNavigationBar: Container(
        height: 80,
        margin: EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(30),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [

            // DIÁRIO (mini resumo / histórico)
            IconButton(
              onPressed: () {
                setState(() {
                  paginaAtual = 0;
                });
              },
              icon: Icon(
                Icons.menu_book_outlined,
                color: paginaAtual == 0
                    ? Colors.white
                    : Colors.grey,
              ),
            ),

            // CALENDÁRIO
            IconButton(
              onPressed: () {
                setState(() {
                  paginaAtual = 1;
                });
              },
              icon: Icon(
                Icons.calendar_today_outlined,
                color: paginaAtual == 1
                    ? Colors.white
                    : Colors.grey,
              ),
            ),

            // "+" CENTRAL — abre a tela de nova anotação
            Container(
              width: 60,
              height: 60,

              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),

              child: IconButton(
                onPressed: _abrirNovaAnotacao,
                icon: Icon(
                  Icons.add,
                  color: Colors.black,
                ),
              ),
            ),

            // ESTATÍSTICAS
            IconButton(
              onPressed: () {
                setState(() {
                  paginaAtual = 2;
                });
              },
              icon: Icon(
                Icons.bar_chart_rounded,
                color: paginaAtual == 2
                    ? Colors.white
                    : Colors.grey,
              ),
            ),

            // SOBRE MIM / CONFIG
            IconButton(
              onPressed: () {
                setState(() {
                  paginaAtual = 3;
                });
              },
              icon: Icon(
                Icons.person_outline,
                color: paginaAtual == 3
                    ? Colors.white
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}