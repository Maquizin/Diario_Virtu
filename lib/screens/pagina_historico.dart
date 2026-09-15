import 'package:flutter/material.dart';

class PaginaHistorico extends StatelessWidget {
  const PaginaHistorico({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Histórico",
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
        ),
      ),
    );
  }
}