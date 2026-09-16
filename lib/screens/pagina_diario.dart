// lib/screens/pagina_diario.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/diario_service.dart';

class PaginaDiario extends StatefulWidget {
  const PaginaDiario({super.key});

  @override
  State<PaginaDiario> createState() => _PaginaDiarioState();
}

class _PaginaDiarioState extends State<PaginaDiario> {
  final TextEditingController controller = TextEditingController();
  double humor = 0.5;

  Color _corDoHumor(double valor) {
    // 0.0 = vermelho (triste), 0.5 = amarelo, 1.0 = verde (feliz)
    final hue = valor * 120; // 0 = vermelho, 120 = verde no círculo de cor HSV
    return HSVColor.fromAHSV(1.0, hue, 0.65, 0.9).toColor();
  }

  String _rotuloHumor(double valor) {
    if (valor < 0.2) return "Muito mal";
    if (valor < 0.4) return "Mal";
    if (valor < 0.6) return "Neutro";
    if (valor < 0.8) return "Bem";
    return "Muito bem";
  }

  void salvarEntrada() async {
    if (controller.text.isEmpty) return;

    await DiarioService().salvarEntrada(controller.text, humor: humor);

    controller.clear();
    setState(() => humor = 0.5);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entrada salva!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = FirebaseAuth.instance.currentUser?.displayName?.split(' ').first;
    final cor = _corDoHumor(humor);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nome != null ? "Olá, $nome!" : "Olá!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "O que você está sentindo hoje?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // Barra de humor
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _rotuloHumor(humor),
                        style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: cor,
                      inactiveTrackColor: Colors.grey.shade800,
                      thumbColor: cor,
                      overlayColor: cor.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: humor,
                      onChanged: (v) => setState(() => humor = v),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Campo de texto
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: controller,
                maxLines: 8,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Escreva sobre seu dia...",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Botões de anexo (áudio e imagem) — funcionais quando adicionarmos os pacotes
            Row(
              children: [
                _botaoAnexo(Icons.mic_none, "Áudio", () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Em breve: gravar áudio")),
                  );
                }),
                const SizedBox(width: 12),
                _botaoAnexo(Icons.image_outlined, "Imagem", () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Em breve: anexar imagem")),
                  );
                }),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: salvarEntrada,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text("Salvar", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoAnexo(IconData icone, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Icon(icone, color: Colors.white70),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}