// lib/screens/acessibilidade_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/acessibilidade_service.dart';
import '../theme/tema.dart';
import '../widgets/animacoes.dart';

class AcessibilidadeScreen extends StatelessWidget {
  const AcessibilidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Acessibilidade'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          ListenableBuilder(
            listenable: acessibilidade,
            builder: (_, __) => TextButton(
              onPressed: acessibilidade.padrao ? null : acessibilidade.restaurar,
              child: const Text('Restaurar'),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: acessibilidade,
        builder: (context, _) {
          final a = acessibilidade;

          Widget card(List<Widget> filhos, int ordem) => EntradaSuave(
                delay: Duration(milliseconds: 70 * ordem),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cores.card,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: filhos),
                ),
              );

          Widget chave(String titulo, String sub, bool v,
                  ValueChanged<bool> f, IconData icone) =>
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(icone, color: cores.destaque),
                title: Text(titulo, style: const TextStyle(color: Colors.white)),
                subtitle: Text(sub,
                    style:
                        TextStyle(color: cores.textoSecundario, fontSize: 12)),
                value: v,
                onChanged: (x) {
                  if (a.vibracao) HapticFeedback.selectionClick();
                  f(x);
                },
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              // ---------- tamanho do texto + prévia
              card([
                Row(children: [
                  Icon(Icons.text_fields, color: cores.destaque),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Tamanho do texto',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  Text('${(a.escalaTexto * 100).round()}%',
                      style: TextStyle(color: cores.textoSecundario)),
                ]),
                Slider(
                  value: a.escalaTexto,
                  min: 0.85,
                  max: 1.6,
                  divisions: 15,
                  label: '${(a.escalaTexto * 100).round()}%',
                  onChanged: a.definirEscala,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cores.cardSuave,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Hoje foi um dia tranquilo. Consegui descansar e conversar '
                    'com quem eu gosto.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
              ], 0),

              card([
                chave('Texto em negrito', 'Letras mais grossas e fáceis de ler',
                    a.negrito, a.definirNegrito, Icons.format_bold),
                chave('Mais espaço entre letras', 'Também aumenta o espaço entre as linhas',
                    a.espacamento, a.definirEspacamento, Icons.format_line_spacing),
                chave('Contraste aumentado', 'Deixa cores e textos mais nítidos',
                    a.altoContraste, a.definirContraste, Icons.contrast),
              ], 1),

              card([
                chave('Reduzir movimento', 'Menos animações e transições',
                    a.reduzirMovimento, a.definirMovimento, Icons.motion_photos_off),
                chave('Vibração leve', 'Pequenos toques ao mexer nas opções',
                    a.vibracao, a.definirVibracao, Icons.vibration),
              ], 2),

              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'As opções valem para o app todo e ficam salvas neste aparelho. '
                  'O tamanho do texto também respeita o ajuste do próprio Android.',
                  style: TextStyle(color: cores.textoSecundario, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}