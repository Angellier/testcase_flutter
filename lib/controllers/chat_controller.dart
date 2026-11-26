import 'package:flutter/foundation.dart';
import 'package:testcase_flutter/models/chat_message.dart';
import 'package:testcase_flutter/services/fake_chat_api.dart';

/// Контроллер состояния чата.
///
/// Хранит источник истины по сообщениям для [chatId] и управляет
/// жизненным циклом отправки и ручных повторов.
class ChatController extends ChangeNotifier {
  ChatController({
    required this._api,
    this.chatId = 'room1',
    this.currentUser = 'Вы',
  }) : _messages = _buildInitialMessages(chatId);

  final FakeChatApi _api;
  final String chatId;
  final String currentUser;

  final List<ChatMessage> _messages;


  final Set<String> _inFlightClientIds = <String>{};

  int _clientSequence = 0;
  bool _isDisposed = false;


  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);


  bool isSending(String clientId) => _inFlightClientIds.contains(clientId);


  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) {
      return;
    }

    _clientSequence += 1;
    final clientId = 'client_${chatId}_$_clientSequence';

    final draftMessage = ChatMessage(
      id: clientId,
      clientId: clientId,
      chatId: chatId,
      author: currentUser,
      text: text,
      status: MessageStatus.pending,
    );

    _messages.add(draftMessage);
    _safeNotifyListeners();

    await _executeSend(draftMessage);
  }

 
  Future<void> retryMessage(String clientId) async {
    if (_inFlightClientIds.contains(clientId)) {
      return;
    }

    final index = _messages.indexWhere((item) => item.clientId == clientId);
    if (index == -1) {
      return;
    }

    final current = _messages[index];
    if (current.status == MessageStatus.pending) {
      return;
    }

    final retryingMessage = current.copyWith(status: MessageStatus.pending);
    _messages[index] = retryingMessage;
    _safeNotifyListeners();

    await _executeSend(retryingMessage);
  }

  Future<void> _executeSend(ChatMessage message) async {
    final clientId = message.clientId;
    _inFlightClientIds.add(clientId);

    try {
      final sentMessage = await _api.sendMessage(message);
      _replaceByClientId(clientId, sentMessage);
    } catch (_) {
      final index = _messages.indexWhere((item) => item.clientId == clientId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          status: MessageStatus.failed,
        );
        _safeNotifyListeners();
      }
    } finally {
      _inFlightClientIds.remove(clientId);
      _safeNotifyListeners();
    }
  }

  void _replaceByClientId(String clientId, ChatMessage updated) {
    final index = _messages.indexWhere((item) => item.clientId == clientId);
    if (index == -1) {
      return;
    }
    _messages[index] = updated;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _inFlightClientIds.clear();
    super.dispose();
  }

  static List<ChatMessage> _buildInitialMessages(String chatId) {
    return <ChatMessage>[
      ChatMessage(
        id: 'msg_1',
        clientId: 'msg_1',
        chatId: chatId,
        author: 'Алексей',
        text: 'Привет! Подключили тестовую комнату room1.',
        status: MessageStatus.sent,
      ),
      ChatMessage(
        id: 'msg_2',
        clientId: 'msg_2',
        chatId: chatId,
        author: 'Мария',
        text: 'Отлично, проверим отправку, ошибку на первой попытке и повтор.',
        status: MessageStatus.sent,
      ),
      ChatMessage(
        id: 'msg_3',
        clientId: 'msg_3',
        chatId: chatId,
        author: 'Вы',
        text: 'Да, следим за тем, чтобы при ретрае не появлялись дубли.',
        status: MessageStatus.sent,
      ),
      ChatMessage(
        id: 'msg_4',
        clientId: 'msg_4',
        chatId: chatId,
        author: 'Алексей',
        text: 'И чтобы кнопка повтора блокировалась на время запроса.',
        status: MessageStatus.sent,
      ),
      ChatMessage(
        id: 'msg_5',
        clientId: 'msg_5',
        chatId: chatId,
        author: 'Мария',
        text: 'Ждём тестовое сообщение — поехали!',
        status: MessageStatus.sent,
      ),
      ChatMessage(
        id: 'msg_6',
        clientId: 'msg_6',
        chatId: chatId,
        author: 'Михаил',
        text: 'Если что — пиши прямо сюда.',
        status: MessageStatus.sent,
      ),
    ];
  }
}
