// lib/screens/pagina_diario.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/diario_service.dart';

const List<String> _nomesMesesAbrev = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
];

const List<Color> _coresFundo = [
  Color(0xFF000000),
  Color(0xFF1A1A2E),
  Color(0xFF2E1A3E),
  Color(0xFF1A2E2E),
  Color(0xFF2E1A1A),
];

class PaginaDiario extends StatefulWidget {
  final DateTime? dataSelecionada;
  const PaginaDiario({super.key, this.dataSelecionada});

  @override
  State<PaginaDiario> createState() => _PaginaDiarioState();
}

class _PaginaDiarioState extends State<PaginaDiario> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController controller = TextEditingController();

  late DateTime data;
  double humor = 0.5;
  bool favorito = false;
  double tamanhoFonte = 16;
  Color corFundo = Colors.black;

  final List<IconData> _iconesHumor = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];

  @override
  void initState() {
    super.initState();
    data = widget.dataSelecionada ?? DateTime.now();
  }

  Color _corDoHumor(double valor) {
    final hue = valor * 120;
    return HSVColor.fromAHSV(1.0, hue, 0.65, 0.9).toColor();
  }

  void _alternarHumor() {
    setState(() {
      final passo = 0.25;
      humor = humor + passo >= 1.05 ? 0.0 : humor + passo;
    });
  }

  Future<void> _escolherData() async {
    final novaData = await showDatePicker(
      context: context,
      initialDate: data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.deepPurpleAccent),
        ),
        child: child!,
      ),
    );
    if (novaData != null) setState(() => data = novaData);
  }

  void _abrirSeletorFundo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cor de fundo', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _coresFundo.map((cor) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => corFundo = cor);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cor,
                        shape: BoxShape.circle,
                        border: corFundo == cor ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _abrirSeletorFonte() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tamanho da fonte', style: TextStyle(color: Colors.white, fontSize: 16)),
                  Slider(
                    activeColor: Colors.deepPurpleAccent,
                    value: tamanhoFonte,
                    min: 12,
                    max: 28,
                    onChanged: (v) {
                      setModalState(() => tamanhoFonte = v);
                      setState(() => tamanhoFonte = v);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _emBreve(String recurso) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Em breve: $recurso')),
    );
  }

  void salvarEntrada() async {
    if (controller.text.isEmpty) return;

    await DiarioService().salvarEntrada(
      controller.text,
      titulo: tituloController.text,
      humor: humor,
      data: data,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cor = _corDoHumor(humor);

    return Scaffold(
      backgroundColor: corFundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topo: fechar, favoritar, salvar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() => favorito = !favorito),
                        icon: Icon(
                          favorito ? Icons.star : Icons.star_border,
                          color: favorito ? Colors.amber : Colors.white,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: salvarEntrada,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Data (pílula) + avatar de humor
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _escolherData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${data.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_nomesMesesAbrev[data.month - 1]}.\n${data.year}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _alternarHumor,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconesHumor[(humor * 4).round().clamp(0, 4)],
                        color: cor,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Título
              TextField(
                controller: tituloController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Título da nota',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),

              const SizedBox(height: 8),

              // Corpo
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(color: Colors.white, fontSize: tamanhoFonte),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Escreva seu registro aqui...',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Barra inferior de recursos
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _botaoFerramenta(Icons.image_outlined, 'Foto', () => _emBreve('anexar foto')),
                    _botaoFerramenta(Icons.emoji_emotions_outlined, 'Figurinhas', () => _emBreve('figurinhas')),
                    _botaoFerramenta(Icons.mic_none, 'Voz', () => _emBreve('gravar áudio')),
                    _botaoFerramenta(Icons.layers_outlined, 'Fundo', _abrirSeletorFundo),
                    _botaoFerramenta(Icons.text_fields, 'Fonte', _abrirSeletorFonte),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botaoFerramenta(IconData icone, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icone, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}