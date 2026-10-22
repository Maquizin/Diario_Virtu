// lib/services/acessibilidade_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda e aplica as opções de acessibilidade em TODO o app.
class AcessibilidadeController extends ChangeNotifier {
  double escalaTexto = 1.0; // 0.85 a 1.6
  bool negrito = false;
  bool altoContraste = false;
  bool reduzirMovimento = false;
  bool espacamento = false; // mais espaço entre letras e linhas
  bool vibracao = true; // pequenos toques ao usar o app

  Future<void> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      escalaTexto = p.getDouble('ac_escala') ?? 1.0;
      negrito = p.getBool('ac_negrito') ?? false;
      altoContraste = p.getBool('ac_contraste') ?? false;
      reduzirMovimento = p.getBool('ac_movimento') ?? false;
      espacamento = p.getBool('ac_espacamento') ?? false;
      vibracao = p.getBool('ac_vibracao') ?? true;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _salvar() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble('ac_escala', escalaTexto);
      await p.setBool('ac_negrito', negrito);
      await p.setBool('ac_contraste', altoContraste);
      await p.setBool('ac_movimento', reduzirMovimento);
      await p.setBool('ac_espacamento', espacamento);
      await p.setBool('ac_vibracao', vibracao);
    } catch (_) {}
  }

  void definirEscala(double v) {
    escalaTexto = v;
    _salvar();
  }

  void definirNegrito(bool v) {
    negrito = v;
    _salvar();
  }

  void definirContraste(bool v) {
    altoContraste = v;
    _salvar();
  }

  void definirMovimento(bool v) {
    reduzirMovimento = v;
    _salvar();
  }

  void definirEspacamento(bool v) {
    espacamento = v;
    _salvar();
  }

  void definirVibracao(bool v) {
    vibracao = v;
    _salvar();
  }

  void restaurar() {
    escalaTexto = 1.0;
    negrito = altoContraste = reduzirMovimento = espacamento = false;
    vibracao = true;
    _salvar();
  }

  bool get padrao =>
      escalaTexto == 1.0 &&
      !negrito &&
      !altoContraste &&
      !reduzirMovimento &&
      !espacamento &&
      vibracao;
}

final acessibilidade = AcessibilidadeController();

/// Coloque no `builder` do MaterialApp, em volta de tudo.
class AcessibilidadeAplicada extends StatelessWidget {
  final Widget child;
  const AcessibilidadeAplicada({super.key, required this.child});

  // Matriz que aumenta o contraste (~25%) sem mudar as cores de lugar.
  static const _contraste = <double>[
    1.25, 0, 0, 0, -32,
    0, 1.25, 0, 0, -32,
    0, 0, 1.25, 0, -32,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: acessibilidade,
      builder: (context, _) {
        final a = acessibilidade;
        final mq = MediaQuery.of(context);
        final tema = Theme.of(context);

        Widget r = child;
        if (a.altoContraste) {
          r = ColorFiltered(
              colorFilter: const ColorFilter.matrix(_contraste), child: r);
        }

        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(a.escalaTexto),
            boldText: a.negrito || mq.boldText,
            disableAnimations: a.reduzirMovimento || mq.disableAnimations,
          ),
          child: a.espacamento
              ? Theme(
                  data: tema.copyWith(
                    textTheme: tema.textTheme
                        .apply(letterSpacingDelta: 0.6, heightFactor: 1.2),
                  ),
                  child: r,
                )
              : r,
        );
      },
    );
  }
}