import 'package:flutter/material.dart';
import 'package:learn_hub/const/header_action.dart';
import 'package:learn_hub/providers/appbar_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, required this.timestamp});
}

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Message> _messages = [
    // Sample messages - remove or modify as needed
    // Message(
    //   text: "Hello! How can I help you today?",
    //   isUser: false,
    //   timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    // ),
    // Message(
    //   text: "I have a question about Flutter.",
    //   isUser: true,
    //   timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    // ),
    // Message(
    //   text:
    //       "Sure, I'd be happy to help with your Flutter questions. What would you like to know?",
    //   isUser: false,
    //   timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    // ),
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
    });
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder:
            (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Chat History",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIconsRegular.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: 10, // Sample history items
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text("Previous Chat ${index + 1}"),
                      subtitle: Text(
                        "Last message from this conversation",
                      ),
                      leading: CircleAvatar(
                        child: Icon(
                          PhosphorIconsRegular.chatCircleText,
                        ),
                      ),
                      trailing: Text(
                        "${index + 1} day ago",
                        style: TextStyle(color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Load the selected chat
                      },
                      onLongPress: () {
                        print("Long pressed on chat ${index + 1}");
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(
          Message(
            text: _textController.text,
            isUser: true,
            timestamp: DateTime.now(),
          ),
        );
        _textController.clear();
      });

      // Simulate response - remove in production
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _messages.add(
              Message(
                text: "Thanks for your message! This is a simulated response.",
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholderColor = cs.onSurface.withValues(alpha: 0.25);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppBarProvider>(context, listen: false).setHeaderAction(
        HeaderAction(
          type: AppBarActionType.chatHistory,
          callback: _showChatHistory,
        ),
      );
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child:
            _messages.isEmpty
                ? _buildEmptyState(cs)
                : _buildMessageList(cs),
          ),
          _buildInputArea(cs, placeholderColor),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.sparkle,
            size: 80,
            color: cs.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "No messages yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Have a question or need explanation? Ask away!",
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      reverse: false,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message, cs);
      },
    );
  }

  Widget _buildMessageBubble(Message message, ColorScheme cs) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? cs.primary : cs.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? cs.onPrimary : cs.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme cs, Color placeholderColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 84),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          spacing: 0,
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(PhosphorIconsFill.image, color: placeholderColor),
              padding: EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: "Ask anything...",
                  hintStyle: TextStyle(color: placeholderColor),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              onPressed: _sendMessage,
              icon: Icon(
                PhosphorIconsFill.paperPlaneTilt,
                color:
                _textController.text.trim().isNotEmpty
                    ? cs.primary
                    : placeholderColor,
              ),
              padding: EdgeInsets.all(12),
              color:
              _textController.text.trim().isNotEmpty
                  ? cs.primary.withValues(alpha: 0.25)
                  : Colors.transparent,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
