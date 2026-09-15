import 'package:flutter/material.dart';

import 'pagina_diario.dart';
import 'pagina_historico.dart';
import 'pagina_configuracoes.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {

  int paginaAtual = 1;

  final List<Widget> paginas = [
    PaginaHistorico(),
    PaginaDiario(),
    PaginaConfiguracoes(),
  ];

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

            // HISTÓRICO
            IconButton(
              onPressed: () {
                setState(() {
                  paginaAtual = 0;
                });
              },
              icon: Icon(
                Icons.bar_chart_rounded,
                color: paginaAtual == 0
                    ? Colors.white
                    : Colors.grey,
              ),
            ),

            // DIÁRIO
            Container(
              width: 60,
              height: 60,

              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),

              child: IconButton(
                onPressed: () {
                  setState(() {
                    paginaAtual = 1;
                  });
                },
                icon: Icon(
                  Icons.edit,
                  color: Colors.black,
                ),
              ),
            ),

            // CONFIG
            IconButton(
              onPressed: () {
                setState(() {
                  paginaAtual = 2;
                });
              },
              icon: Icon(
                Icons.settings,
                color: paginaAtual == 2
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