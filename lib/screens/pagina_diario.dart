import 'package:flutter/material.dart';
import '../services/diario_service.dart';

class PaginaDiario extends StatefulWidget {
  const PaginaDiario({super.key});

  @override
  State<PaginaDiario> createState() => _PaginaDiarioState();
}

class _PaginaDiarioState extends State<PaginaDiario> {

  final TextEditingController controller = TextEditingController();

  List<String> entradas = [];

void salvarEntrada() async {

  if (controller.text.isEmpty) return;

  await DiarioService().salvarEntrada(
    controller.text,
  );

  setState(() {
    entradas.add(controller.text);
  });

  controller.clear();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Entrada salva!"),
    ),
  );
}

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Como você está hoje?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),

              child: TextField(
                controller: controller,
                maxLines: 8,

                style: const TextStyle(
                  color: Colors.white,
                ),

                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Escreva sobre seu dia...",
                  hintStyle: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
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

                child: const Text(
                  "Salvar",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: entradas.length,

                itemBuilder: (context, index) {

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Text(
                      entradas[index],

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}