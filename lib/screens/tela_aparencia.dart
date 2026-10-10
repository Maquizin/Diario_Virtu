// lib/screens/tela_aparencia.dart
import 'package:flutter/material.dart';

import '../theme/tema.dart';
import '../widgets/animacoes.dart';

class TelaAparencia extends StatelessWidget {
  const TelaAparencia({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: temaController,
      builder: (context, _) {
        final titulo = Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18);

        return Scaffold(
          appBar: AppBar(title: const Text('Aparência')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Text('Tema', style: titulo),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: [
                  for (var i = 0; i < temasDisponiveis.length; i++)
                    EntradaSuave(
                      delay: Duration(milliseconds: 80 * i),
                      child: _CartaoTema(
                        tema: temasDisponiveis[i],
                        selecionado:
                            temasDisponiveis[i].id == temaController.tema.id,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Cor de destaque', style: titulo),
              const SizedBox(height: 4),
              Text(
                'Muda os botões, gráficos e as luzes do fundo.',
                style: TextStyle(color: context.cores.textoSecundario),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _BolinhaPadrao(
                    selecionada: temaController.destaquePersonalizado == null,
                  ),
                  for (final cor in coresDestaque)
                    _BolinhaCor(
                      cor: cor,
                      selecionada: temaController.destaquePersonalizado
                              ?.toARGB32() ==
                          cor.toARGB32(),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Orbe extends StatelessWidget {
  final Color cor;
  final double tamanho;
  const _Orbe(this.cor, this.tamanho);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [cor.withValues(alpha: 0.7), cor.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _CartaoTema extends StatelessWidget {
  final TemaApp tema;
  final bool selecionado;
  const _CartaoTema({required this.tema, required this.selecionado});

  @override
  Widget build(BuildContext context) {
    final destaque = temaController.destaque;

    return GestureDetector(
      onTap: () => temaController.escolherTema(tema.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tema.fundo,
          ),
          border: Border.all(
            color: selecionado ? destaque : Colors.white12,
            width: selecionado ? 3 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(right: -25, top: -25, child: _Orbe(tema.orbes[0], 110)),
            Positioned(left: -20, top: 30, child: _Orbe(tema.orbes[1], 90)),
            Positioned(right: 10, bottom: 40, child: _Orbe(tema.orbes[2], 80)),
            if (selecionado)
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: destaque,
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tema.nome,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(tema.descricao,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BolinhaCor extends StatelessWidget {
  final Color cor;
  final bool selecionada;
  const _BolinhaCor({required this.cor, required this.selecionada});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => temaController.escolherDestaque(cor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cor,
          border: Border.all(
            color: selecionada ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
        child: selecionada
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}

class _BolinhaPadrao extends StatelessWidget {
  final bool selecionada;
  const _BolinhaPadrao({required this.selecionada});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => temaController.escolherDestaque(null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.cores.cardSuave,
          border: Border.all(
            color: selecionada ? Colors.white : Colors.white24,
            width: selecionada ? 3 : 1,
          ),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
      ),
    );
  }
}