// lib/utils/humor_utils.dart
import 'package:flutter/material.dart';

Color corDoHumor(double valor) {
  final hue = valor * 120; // 0 = vermelho, 120 = verde
  return HSVColor.fromAHSV(1.0, hue, 0.65, 0.9).toColor();
}

String rotuloHumor(double valor) {
  if (valor < 0.2) return "Muito mal";
  if (valor < 0.4) return "Mal";
  if (valor < 0.6) return "Neutro";
  if (valor < 0.8) return "Bem";
  return "Muito bem";
}

IconData iconeHumor(double valor) {
  const icones = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];
  return icones[(valor * 4).round().clamp(0, 4)];
}