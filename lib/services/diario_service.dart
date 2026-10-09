// lib/services/diario_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/entrada_diario.dart';

class DiarioService {
  final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'serenia-db',
  );

  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> salvarEntrada(
    String texto, {
    String titulo = '',
    double humor = 0.5,
    String? audioUrl,
    String? imagemUrl,
    DateTime? data,
  }) async {
    final user = auth.currentUser;
    if (user == null) return;

    await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .add({
      'titulo': titulo,
      'texto': texto,
      'data': Timestamp.fromDate(data ?? DateTime.now()),
      'humor': humor,
      'audioUrl': audioUrl,
      'imagemUrl': imagemUrl,
      'favorito': false,
    });
  }

  Future<void> atualizarEntrada(
    String id, {
    required String titulo,
    required String texto,
    required double humor,
    required DateTime data,
  }) async {
    final user = auth.currentUser;
    if (user == null) return;

    await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .doc(id)
        .update({
      'titulo': titulo,
      'texto': texto,
      'humor': humor,
      'data': Timestamp.fromDate(data),
    });
  }

  Future<void> alternarFavorito(
    String id,
    bool valorAtual,
  ) async {
    final user = auth.currentUser;
    if (user == null) return;

    await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .doc(id)
        .update({
      'favorito': !valorAtual,
    });
  }

  Stream<List<EntradaDiario>> streamEntradasPeriodo(
    DateTime inicio,
    DateTime fim,
  ) {
    final user = auth.currentUser;
    if (user == null) return const Stream.empty();

    return firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .where(
          'data',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .where(
          'data',
          isLessThan: Timestamp.fromDate(fim),
        )
        .orderBy('data')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EntradaDiario.fromDoc(doc))
              .toList(),
        );
  }

  Future<void> deletarEntrada(String id) async {
    final user = auth.currentUser;
    if (user == null) return;

    await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .doc(id)
        .delete();
  }
//inicio teste
  Future<void> criarDadosDeTeste(DateTime mes) async {
  final user = auth.currentUser;
  if (user == null) return;

  final exemplos = <({int dia, int hora, double humor, String titulo, String texto})>[
    (dia: 1, hora: 21, humor: 0.75, titulo: 'Começo tranquilo', texto: 'Comecei o mês com ânimo. Fui à academia e depois jantei com a família. Dormi bem.'),
    (dia: 3, hora: 20, humor: 0.75, titulo: 'Dia produtivo', texto: 'Consegui avançar bastante no TCC hoje. Ritmo bom e sensação de progresso.'),
    (dia: 5, hora: 22, humor: 0.5, titulo: 'Dia normal', texto: 'Nada demais. Aula, almoço, estudo. Um pouco de cansaço no fim do dia.'),
    (dia: 7, hora: 19, humor: 0.5, titulo: 'Semana puxada', texto: 'Muitas entregas se acumulando. Comecei a me preocupar com os prazos.'),
    (dia: 8, hora: 23, humor: 0.25, titulo: 'Dormi mal', texto: 'Acordei duas vezes de madrugada pensando nas provas. Hoje estou sem energia e com irritação com tudo.'),
    (dia: 10, hora: 21, humor: 0.25, titulo: 'Cabeça cheia', texto: 'Não consegui me concentrar na aula. Fiquei me comparando com os colegas que parecem mais adiantados. Pulei o treino.'),
    (dia: 11, hora: 22, humor: 0.0, titulo: 'Dia pesado', texto: 'Tudo parece pesado hoje. Dormi poucas horas de novo, senti ansiedade a manhã inteira e não tive vontade de comer direito.'),
    (dia: 12, hora: 18, humor: 0.25, titulo: 'Ansiedade', texto: 'Coração acelerado antes da apresentação do grupo. Depois passou, mas fiquei sem energia.'),
    (dia: 14, hora: 20, humor: 0.25, titulo: 'Discussão em casa', texto: 'Discuti com minha mãe por causa da bagunça no quarto e do tempo que passo no celular. Me senti mal depois.'),
    (dia: 15, hora: 21, humor: 0.5, titulo: 'Conversa com amigo', texto: 'Conversei com um amigo sobre como estou me sentindo. Ajudou colocar em palavras. Ainda com cansaço, mas mais leve.'),
    (dia: 17, hora: 19, humor: 0.5, titulo: 'Voltei a treinar', texto: 'Voltei para a academia depois de uma semana parado. Dormi um pouco melhor.'),
    (dia: 18, hora: 17, humor: 0.75, titulo: 'Apresentação foi bem', texto: 'A apresentação do grupo foi melhor do que eu esperava. O professor elogiou. Foi um alívio.'),
    (dia: 20, hora: 22, humor: 0.75, titulo: 'Saída com amigos', texto: 'Fomos ao cinema e depois lanchar. Ri bastante, fazia tempo que não saía.'),
    (dia: 22, hora: 20, humor: 0.5, titulo: 'Domingo em casa', texto: 'Fiquei em casa. Um pouco de ansiedade pensando na semana de provas, mas nada como antes.'),
    (dia: 24, hora: 23, humor: 0.25, titulo: 'Sono ruim de novo', texto: 'Dormi por volta das 3h estudando. Acordei cansado, com dor de cabeça, e tomei muito café.'),
    (dia: 25, hora: 13, humor: 0.5, titulo: 'Dia de prova', texto: 'Fiz a prova de manhã. Não sei se fui bem, mas ao menos terminou.'),
    (dia: 27, hora: 18, humor: 0.75, titulo: 'Dia leve', texto: 'Caminhei no parque e almocei com a família. Me senti tranquilo, sem pressa.'),
    (dia: 28, hora: 21, humor: 1.0, titulo: 'Fim de mês', texto: 'Mês difícil, mas terminei melhor do que comecei. Quero manter a rotina de sono e os treinos.'),
  ];

  final colecao = firestore
      .collection('usuarios')
      .doc(user.uid)
      .collection('entradas');
  final batch = firestore.batch();

  for (final e in exemplos) {
    batch.set(colecao.doc(), {
      'titulo': e.titulo,
      'texto': e.texto,
      'data': Timestamp.fromDate(DateTime(mes.year, mes.month, e.dia, e.hora, 30)),
      'humor': e.humor,
      'favorito': false,
      'audioUrl': null,
      'imagemUrl': null,
      'teste': true,
    });
  }

  await batch.commit();
}

Future<void> apagarDadosDeTeste() async {
  final user = auth.currentUser;
  if (user == null) return;

  final snapshot = await firestore
      .collection('usuarios')
      .doc(user.uid)
      .collection('entradas')
      .where('teste', isEqualTo: true)
      .get();

  final batch = firestore.batch();
  for (final doc in snapshot.docs) {
    batch.delete(doc.reference);
  }
  await batch.commit();
}

//fim teste

  Future<List<EntradaDiario>> buscarTodasEntradas() async {
  final user = auth.currentUser;
  if (user == null) return [];

  final snapshot = await firestore
      .collection('usuarios')
      .doc(user.uid)
      .collection('entradas')
      .orderBy('data')
      .get();

  return snapshot.docs.map((doc) => EntradaDiario.fromDoc(doc)).toList();
}

Future<List<EntradaDiario>> buscarEntradasPeriodo(DateTime inicio, DateTime fim) async {
  final user = auth.currentUser;
  if (user == null) return [];

  final snapshot = await firestore
      .collection('usuarios')
      .doc(user.uid)
      .collection('entradas')
      .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
      .where('data', isLessThan: Timestamp.fromDate(fim))
      .orderBy('data')
      .get();

  return snapshot.docs.map((doc) => EntradaDiario.fromDoc(doc)).toList();
}

  Stream<List<EntradaDiario>> streamEntradas() {
    final user = auth.currentUser;
    if (user == null) return const Stream.empty();

    return firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EntradaDiario.fromDoc(doc))
              .toList(),
        );
  }
}