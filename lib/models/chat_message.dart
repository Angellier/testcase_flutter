enum MessageStatus {
  pending,
  sent,
  failed,
}

/// Модель сообщения в чате.
///
/// Используем [id] для уже существующих сообщений истории и [clientId]
/// для отслеживания жизненного цикла нового сообщения при отправке и повторах.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.clientId,
    required this.chatId,
    required this.author,
    required this.text,
    required this.status,
  });

  final String id;
  final String clientId;
  final String chatId;
  final String author;
  final String text;
  final MessageStatus status;

  ChatMessage copyWith({
    String? id,
    String? clientId,
    String? chatId,
    String? author,
    String? text,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      chatId: chatId ?? this.chatId,
      author: author ?? this.author,
      text: text ?? this.text,
      status: status ?? this.status,
    );
  }
}