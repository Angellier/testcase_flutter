import 'package:material_ui/material_ui.dart';
import 'package:testcase_flutter/controllers/chat_controller.dart';
import 'package:testcase_flutter/screens/chat_screen.dart';
import 'package:testcase_flutter/services/fake_chat_api.dart';

void main() {
  runApp(const ChatTestApp());
}

class ChatTestApp extends StatefulWidget {
  const ChatTestApp({super.key});

  @override
  State<ChatTestApp> createState() => _ChatTestAppState();
}

class _ChatTestAppState extends State<ChatTestApp> {
  late final FakeChatApi _api;
  late final ChatController _controller;

  @override
  void initState() {
    super.initState();
    _api = FakeChatApi();
    _controller = ChatController(api: _api);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Тестовое задание',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: ChatScreen(controller: _controller),
    );
  }
}