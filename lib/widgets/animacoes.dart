// lib/widgets/animacoes.dart
//
// Pequenas animações prontas para usar em qualquer tela.

import 'package:flutter/material.dart';

/// Faz o conteúdo aparecer suavemente (surge e sobe um pouquinho).
/// Use `delay` diferente em cada item para eles entrarem em sequência:
///
///   EntradaSuave(delay: Duration(milliseconds: 150), child: MeuCard())
class EntradaSuave extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const EntradaSuave({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<EntradaSuave> createState() => _EntradaSuaveState();
}

class _EntradaSuaveState extends State<EntradaSuave> {
  bool _visivel = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visivel = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visivel ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visivel ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Número que "conta" até o valor quando aparece (e quando muda).
class NumeroAnimado extends StatelessWidget {
  final int valor;
  final TextStyle? estilo;

  const NumeroAnimado({super.key, required this.valor, this.estilo});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}', style: estilo),
    );
  }
}

/// Faz o conteúdo "respirar" (cresce e diminui devagar). Bom para a chama.
class Pulsar extends StatefulWidget {
  final Widget child;
  final double intensidade;

  const Pulsar({super.key, required this.child, this.intensidade = 0.08});

  @override
  State<Pulsar> createState() => _PulsarState();
}

class _PulsarState extends State<Pulsar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final escala = Tween<double>(begin: 1, end: 1 + widget.intensidade)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    return ScaleTransition(scale: escala, child: widget.child);
  }
}