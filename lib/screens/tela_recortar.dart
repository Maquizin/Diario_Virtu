// lib/screens/tela_recortar.dart
//
// Enquadramento de imagem SEM pacotes extras e sem reconverter a foto:
// o usuário arrasta e dá zoom (pinça); guardamos só o ajuste (zoom e posição)
// e a imagem é mostrada com esse mesmo enquadramento onde for usada.

import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Zoom e posição escolhidos, relativos ao tamanho do quadro.
class AjusteImagem {
  final double escala;
  final double dx; // deslocamento / largura do quadro
  final double dy; // deslocamento / altura do quadro

  const AjusteImagem(this.escala, this.dx, this.dy);

  List<double> toList() => [escala, dx, dy];

  static AjusteImagem? fromList(Object? v) {
    if (v is List && v.length == 3) {
      final n = v.map((e) => (e as num).toDouble()).toList();
      return AjusteImagem(n[0], n[1], n[2]);
    }
    return null;
  }
}

/// Mostra a imagem com o enquadramento escolhido, preenchendo o espaço dado.
class ImagemAjustada extends StatelessWidget {
  final Uint8List bytes;
  final AjusteImagem? ajuste;

  const ImagemAjustada({super.key, required this.bytes, this.ajuste});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final a = ajuste;
        final imagem = Image.memory(bytes,
            fit: BoxFit.cover, width: w, height: h, gaplessPlayback: true);
        return ClipRect(
          child: a == null
              ? imagem
              : Transform(
                  transform: Matrix4.identity()
                    ..translate(a.dx * w, a.dy * h)
                    ..scale(a.escala),
                  child: imagem,
                ),
        );
      },
    );
  }
}

class TelaRecortar extends StatefulWidget {
  final Uint8List bytes;

  /// largura / altura do quadro (1 = quadrado, 2.7 = banner).
  final double proporcao;

  /// Mostra uma máscara redonda (foto de perfil).
  final bool circulo;

  final String titulo;

  const TelaRecortar({
    super.key,
    required this.bytes,
    required this.proporcao,
    required this.titulo,
    this.circulo = false,
  });

  @override
  State<TelaRecortar> createState() => _TelaRecortarState();
}

class _TelaRecortarState extends State<TelaRecortar> {
  final _transformacao = TransformationController();
  double _largura = 300, _altura = 300;

  @override
  void dispose() {
    _transformacao.dispose();
    super.dispose();
  }

  void _concluir() {
    final m = _transformacao.value;
    final t = m.getTranslation();
    Navigator.pop(
      context,
      AjusteImagem(m.getMaxScaleOnAxis(), t.x / _largura, t.y / _altura),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.titulo),
        actions: [
          TextButton(onPressed: _concluir, child: const Text('Concluir')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, caixa) {
                    _largura = caixa.maxWidth - 32;
                    _altura = _largura / widget.proporcao;
                    return SizedBox(
                      width: _largura,
                      height: _altura,
                      child: Stack(
                        children: [
                          ClipRect(
                            child: InteractiveViewer(
                              transformationController: _transformacao,
                              minScale: 1,
                              maxScale: 6,
                              boundaryMargin: EdgeInsets.zero,
                              child: Image.memory(
                                widget.bytes,
                                fit: BoxFit.cover,
                                width: _largura,
                                height: _altura,
                              ),
                            ),
                          ),
                          if (widget.circulo)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(painter: _MascaraCirculo()),
                              ),
                            ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.white54, width: 1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Arraste para mover e use dois dedos para dar zoom.',
                style: TextStyle(color: Colors.white60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MascaraCirculo extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final caminho = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(
          center: size.center(Offset.zero), radius: size.shortestSide / 2));
    canvas.drawPath(
        caminho, Paint()..color = Colors.black.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}