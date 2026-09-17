// lib/screens/pagina_calendario.dart
import 'package:flutter/material.dart';

class PaginaCalendario extends StatelessWidget {
  const PaginaCalendario({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calendário',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Text(
                  'Em breve: veja suas entradas organizadas por data.',
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