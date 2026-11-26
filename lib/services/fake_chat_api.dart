import "package:testcase_flutter/models/chat_message.dart";

/// Имитация серверной/транспортной отправки сообщения.
/// - для каждого нового [clientId] первая попытка завершается ошибкой;
/// - последующая попытка с тем же [clientId] проходит успешно.
class FakeChatApi {
  FakeChatApi({
    this.sendDelay = const Duration(seconds: 1),
  });

  final Duration sendDelay;

  final Map<String, int> _attemptsByClientId = {};

  Future<ChatMessage> sendMessage(ChatMessage message) async {
    await Future<void>.delayed(sendDelay);

    final nextAttempt = (_attemptsByClientId[message.clientId] ?? 0) + 1;
    _attemptsByClientId[message.clientId] = nextAttempt;

    if (nextAttempt == 1) {
      throw StateError(
        'Временная ошибка отправки для clientId=${message.clientId}',
      );
    }

    return message.copyWith(status: MessageStatus.sent);
  }
}