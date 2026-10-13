// lib/services/notificacoes.dart
//
// Notificação do sistema avisando que o relatório ficou pronto
// (útil quando o usuário está em outro app).

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notificacoes {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pronto = false;

  /// Chamado ao tocar numa notificação; recebe o "payload" (ex.: '2026-09').
  void Function(String payload)? aoTocar;

  Future<void> iniciar() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (resposta) {
          final p = resposta.payload;
          if (p != null) aoTocar?.call(p);
        },
      );
      _pronto = true;
    } catch (e) {
      debugPrint('NOTIFICACOES: não foi possível iniciar: $e');
    }
  }

  /// Android 13+ pede permissão para mostrar notificações.
  Future<void> pedirPermissao() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> relatorioPronto({
    required String titulo,
    required String payload,
  }) async {
    if (!_pronto) return;
    try {
      await _plugin.show(
        id: payload.hashCode & 0x7fffffff,
        title: 'Relatório pronto',
        body: 'O relatório de $titulo foi gerado. Toque para abrir.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'relatorios',
            'Relatórios',
            channelDescription: 'Avisa quando um relatório mensal fica pronto',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('NOTIFICACOES: erro ao mostrar: $e');
    }
  }
}

final notificacoes = Notificacoes();