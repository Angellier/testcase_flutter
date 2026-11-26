import 'package:material_ui/material_ui.dart';
import 'package:testcase_flutter/controllers/chat_controller.dart';
import 'package:testcase_flutter/models/chat_message.dart';

/// Экран комнаты чата.
///
/// Не содержит бизнес-логики отправки и управления статусами —
/// всё делегируется [ChatController].
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.controller,
    super.key,
  });

  final ChatController controller;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _hasText = false;
  int _previousMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    _previousMessagesCount = widget.controller.messages.length;
    _inputController.addListener(_handleInputChanged);
    widget.controller.addListener(_handleControllerChanged);
  }

  void _handleInputChanged() {
    final nextHasText = _inputController.text.trim().isNotEmpty;
    if (nextHasText != _hasText) {
      setState(() {
        _hasText = nextHasText;
      });
    }
  }

  void _handleControllerChanged() {
    final currentCount = widget.controller.messages.length;
    if (currentCount > _previousMessagesCount) {
      _previousMessagesCount = currentCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _submitMessage() async {
    final text = _inputController.text;
    if (text.trim().isEmpty) {
      return;
    }

    _inputController.clear();
    await widget.controller.sendMessage(text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _inputController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 216, 216, 216),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        titleTextStyle: const TextStyle(color: Colors.white),
        title: Text('Чат · ${widget.controller.chatId}'),
      ),
      body: Column(  
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final messages = widget.controller.messages;
                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSending = widget.controller.isSending(
                      message.clientId,
                    );
                    return _MessageTile(
                      message: message,
                      isSending: isSending,
                      onRetry: () => widget.controller.retryMessage(
                        message.clientId,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          _MessageInputBar(
            
            controller: _inputController,
            canSend: _hasText,
            onSend: _submitMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.isSending,
    required this.onRetry,
  });

  final ChatMessage message;
  final bool isSending;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isOwn = message.author == 'Вы';
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isOwn
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.author,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                _MessageStatusRow(
                  status: message.status,
                  isSending: isSending,
                  onRetry: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageStatusRow extends StatelessWidget {
  const _MessageStatusRow({
    required this.status,
    required this.isSending,
    required this.onRetry,
  });

  final MessageStatus status;
  final bool isSending;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (status) {
      MessageStatus.pending => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.8),
            ),
            const SizedBox(width: 6),
            Text(
              'Отправляется...',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      MessageStatus.sent => Text(
          'Отправлено',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
              ),
        ),
      MessageStatus.failed => Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'Ошибка отправки',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton(
              onPressed: isSending ? null : onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(isSending ? 'Повтор...' : 'Повторить'),
            ),
          ],
        ),
    };
  }
}
class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.controller,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                style: TextStyle(color: Colors.black),
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Введите сообщение',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: canSend ? onSend : null,
              tooltip: 'Отправить',
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
