// lib/models/entrada_diario.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EntradaDiario {
  final String? id;
  final String titulo;
  final String texto;
  final DateTime data;
  final double humor;
  final bool favorito;
  final String? audioUrl;
  final String? imagemUrl;

  EntradaDiario({
    this.id,
    this.titulo = '',
    required this.texto,
    required this.data,
    this.humor = 0.5,
    this.favorito = false,
    this.audioUrl,
    this.imagemUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'texto': texto,
      'data': Timestamp.fromDate(data),
      'humor': humor,
      'favorito': favorito,
      'audioUrl': audioUrl,
      'imagemUrl': imagemUrl,
    };
  }

  factory EntradaDiario.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return EntradaDiario(
      id: doc.id,
      titulo: map['titulo'] ?? '',
      texto: map['texto'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      humor: (map['humor'] ?? 0.5).toDouble(),
      favorito: map['favorito'] ?? false,
      audioUrl: map['audioUrl'],
      imagemUrl: map['imagemUrl'],
    );
  }
}