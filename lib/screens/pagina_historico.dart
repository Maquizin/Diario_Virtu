// lib/screens/historico_screen.dart
import 'package:flutter/material.dart';
import '../services/diario_service.dart';
import '../models/entrada_diario.dart';
import '../utils/humor_utils.dart';
import 'pagina_diario.dart';

const List<String> _nomesMeses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
];

class PaginaHistorico extends StatelessWidget {
  PaginaHistorico({super.key});

  final DiarioService _diarioService = DiarioService();

  bool _ehHoje(DateTime data) {
    final hoje = DateTime.now();
    return data.year == hoje.year && data.month == hoje.month && data.day == hoje.day;
  }

  String _tituloData(DateTime data) {
    final dataFormatada = '${data.day} de ${_nomesMeses[data.month - 1]}';
    return _ehHoje(data) ? 'HOJE, $dataFormatada'.toUpperCase() : dataFormatada.toUpperCase();
  }

  String _horario(DateTime data) {
    return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  void _abrirEntrada(BuildContext context, EntradaDiario entrada) {
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
              if (entrada.titulo.isNotEmpty) ...[
                Text(entrada.titulo,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
              ],
              Text(_tituloData(entrada.data), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              Text(entrada.texto, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _editarEntrada(BuildContext context, EntradaDiario entrada) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaginaDiario(entradaExistente: entrada)),
    );
  }

  void _confirmarExclusao(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Excluir entrada?', style: TextStyle(color: Colors.white)),
          content: const Text('Essa ação não pode ser desfeita.', style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _diarioService.deletarEntrada(id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
                  }
                }
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _emBreve(BuildContext context, String recurso) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Em breve: $recurso')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Histórico',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<EntradaDiario>>(
                stream: _diarioService.streamEntradas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Erro ao carregar histórico: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white)));
                  }

                  final entradas = snapshot.data ?? [];
                  if (entradas.isEmpty) {
                    return const Center(
                        child: Text('Nenhuma entrada ainda.', style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: entradas.length,
                    itemBuilder: (context, index) {
                      final entrada = entradas[index];
                      final cor = corDoHumor(entrada.humor);
                      final preview = entrada.texto.length > 90
                          ? '${entrada.texto.substring(0, 90)}...'
                          : entrada.texto;

                      return GestureDetector(
                        onTap: () => _abrirEntrada(context, entrada),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar de humor
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(color: cor.withOpacity(0.25), shape: BoxShape.circle),
                                    child: Icon(iconeHumor(entrada.humor), color: cor, size: 26),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(_tituloData(entrada.data),
                                                style: const TextStyle(
                                                    color: Colors.grey, fontSize: 11, letterSpacing: 0.5)),
                                            if (entrada.favorito) ...[
                                              const SizedBox(width: 6),
                                              const Icon(Icons.star, color: Colors.amber, size: 14),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(rotuloHumor(entrada.humor),
                                                style: TextStyle(
                                                    color: cor, fontSize: 18, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 10),
                                            Text(_horario(entrada.data),
                                                style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Menu de 3 pontos
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                                    color: const Color(0xFF2C2C2E),
                                    onSelected: (valor) {
                                      switch (valor) {
                                        case 'editar':
                                          _editarEntrada(context, entrada);
                                          break;
                                        case 'compartilhar':
                                          _emBreve(context, 'compartilhar entrada');
                                          break;
                                        case 'favorito':
                                          _diarioService.alternarFavorito(entrada.id!, entrada.favorito);
                                          break;
                                        case 'foto':
                                          _emBreve(context, 'adicionar foto');
                                          break;
                                        case 'excluir':
                                          _confirmarExclusao(context, entrada.id!);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'editar', child: Text('Editar')),
                                      const PopupMenuItem(value: 'compartilhar', child: Text('Compartilhar')),
                                      PopupMenuItem(
                                        value: 'favorito',
                                        child: Text(entrada.favorito ? 'Remover favorito' : 'Marcar como favorito'),
                                      ),
                                      const PopupMenuItem(value: 'foto', child: Text('Adicionar foto')),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'excluir',
                                        child: Text('Excluir', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              if (entrada.titulo.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(entrada.titulo,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              ],

                              const SizedBox(height: 6),
                              Text(preview, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      );
                    },
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