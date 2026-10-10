// lib/widgets/fundo_animado.dart
//
// Fundo vivo do app: gradiente + luzes coloridas que flutuam devagar
// (e estrelas que piscam, nos temas que têm). Fica atrás de todas as telas.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tema.dart';

class _Estrela {
  final double dx, dy, raio, fase;
  const _Estrela(this.dx, this.dy, this.raio, this.fase);
}

class FundoAnimado extends StatefulWidget {
  final TemaApp tema;
  final Color destaque;
  final Widget child;

  const FundoAnimado({
    super.key,
    required this.tema,
    required this.destaque,
    required this.child,
  });

  @override
  State<FundoAnimado> createState() => _FundoAnimadoState();
}

class _FundoAnimadoState extends State<FundoAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  late final List<_Estrela> _estrelas = () {
    final r = math.Random(7);
    return List.generate(
      70,
      (_) => _Estrela(r.nextDouble(), r.nextDouble(), 0.6 + r.nextDouble() * 1.2,
          r.nextDouble()),
    );
  }();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeita a configuração de "reduzir movimento" do aparelho.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tema;
    // A primeira luz usa a cor de destaque escolhida pelo usuário.
    final orbes = [widget.destaque, ...t.orbes.skip(1)];

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: t.fundo,
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _FundoPainter(
              t: _c,
              orbes: orbes,
              estrelas: t.estrelas ? _estrelas : const [],
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _FundoPainter extends CustomPainter {
  final Animation<double> t;
  final List<Color> orbes;
  final List<_Estrela> estrelas;

  _FundoPainter({required this.t, required this.orbes, required this.estrelas})
      : super(repaint: t);

  // [freqX, freqY, faseX, faseY, raio (fração da largura), amplitudeX, amplitudeY]
  // As frequências são inteiras para o movimento emendar sem "pulo" no loop.
  static const _params = <List<double>>[
    [1, 1, 0.00, 0.25, 0.85, 0.35, 0.30],
    [2, 1, 0.40, 0.70, 0.70, 0.40, 0.25],
    [1, 2, 0.75, 0.10, 0.80, 0.30, 0.35],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final w = size.width, h = size.height;

    for (var i = 0; i < _params.length; i++) {
      final p = _params[i];
      final cor = orbes[i % orbes.length];
      final cx = w * (0.5 + p[5] * math.sin(2 * math.pi * (v * p[0] + p[2])));
      final cy = h * (0.5 + p[6] * math.cos(2 * math.pi * (v * p[1] + p[3])));
      final raio = w * p[4];
      final centro = Offset(cx, cy);

      final pincel = Paint()
        ..shader = RadialGradient(
          colors: [cor.withValues(alpha: 0.38), cor.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: centro, radius: raio));
      canvas.drawCircle(centro, raio, pincel);
    }

    for (final e in estrelas) {
      final brilho =
          0.5 + 0.5 * math.sin(2 * math.pi * (v * 12 + e.fase));
      final pincel = Paint()
        ..color = Colors.white.withValues(alpha: 0.15 + 0.65 * brilho);
      canvas.drawCircle(Offset(e.dx * w, e.dy * h), e.raio, pincel);
    }
  }

  @override
  bool shouldRepaint(covariant _FundoPainter old) =>
      old.orbes != orbes || old.estrelas != estrelas;
}