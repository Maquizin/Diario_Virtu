// lib/models/entrada_diario.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EntradaDiario {
  final String? id;
  final String texto;
  final DateTime data;
  final double humor; // 0.0 (triste) a 1.0 (feliz)
  final String? audioUrl;
  final String? imagemUrl;

  EntradaDiario({
    this.id,
    required this.texto,
    required this.data,
    this.humor = 0.5,
    this.audioUrl,
    this.imagemUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'data': Timestamp.fromDate(data),
      'humor': humor,
      'audioUrl': audioUrl,
      'imagemUrl': imagemUrl,
    };
  }

  factory EntradaDiario.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return EntradaDiario(
      id: doc.id,
      texto: map['texto'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      humor: (map['humor'] ?? 0.5).toDouble(),
      audioUrl: map['audioUrl'],
      imagemUrl: map['imagemUrl'],
    );
  }
}