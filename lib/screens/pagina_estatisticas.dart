// lib/screens/pagina_estatisticas.dart
import 'package:flutter/material.dart';

class PaginaEstatisticas extends StatelessWidget {
  const PaginaEstatisticas({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estatísticas',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Text(
                  'Em breve: sequência de dias, humor e gráficos.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}