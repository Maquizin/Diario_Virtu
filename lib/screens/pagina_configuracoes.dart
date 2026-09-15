import 'package:flutter/material.dart';

class PaginaConfiguracoes extends StatelessWidget {
  const PaginaConfiguracoes({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Configurações",
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
        ),
      ),
    );
  }
}