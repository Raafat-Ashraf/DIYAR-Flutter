import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../constants/api_constants.dart';
import '../storage/session_storage.dart';

class NotificationPayload {
  const NotificationPayload({
    required this.id,
    required this.title,
    required this.content,
    this.type,
    this.referenceId,
  });

  final int id;
  final String title;
  final String content;
  final String? type;
  final int? referenceId;

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      type: json['type']?.toString(),
      referenceId: json['referenceId'] as int?,
    );
  }
}

class SignalRService {
  SignalRService(this._sessionStorage);

  final SessionStorage _sessionStorage;
  HubConnection? _connection;

  final List<void Function(NotificationPayload)> _listeners = [];

  void addListener(void Function(NotificationPayload) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(NotificationPayload) listener) {
    _listeners.remove(listener);
  }

  Future<void> connect() async {
    if (_connection?.state == HubConnectionState.Connected) return;

    final token = await _sessionStorage.readAccessToken();
    if (token == null) return;

    _connection = HubConnectionBuilder()
        .withUrl(
          '${ApiConstants.baseUrl}hubs/notifications?access_token=$token',
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveNotification', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      try {
        final raw = arguments.first;
        Map<String, dynamic> json;
        if (raw is Map<String, dynamic>) {
          json = raw;
        } else {
          json = jsonDecode(raw.toString()) as Map<String, dynamic>;
        }
        final payload = NotificationPayload.fromJson(json);
        for (final listener in _listeners) {
          listener(payload);
        }
      } catch (_) {}
    });

    try {
      await _connection!.start();
      debugPrint('[SignalR] Connected');
    } catch (e) {
      debugPrint('[SignalR] Connection error: $e');
    }
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
    debugPrint('[SignalR] Disconnected');
  }
}
