import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:learn_hub/const/header_action.dart';
import 'package:learn_hub/providers/appbar_provider.dart';
import 'package:learn_hub/services/ask_ai.dart';
import 'package:learn_hub/utils/api_helper.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

enum LoadingState {
  uploading("Uploading your document..."),
  generating("Generating the answer");

  final String message;

  const LoadingState(this.message);
}

class ContextFileInfo {
  final String id;
  final String? filename;
  final String? extension;
  final int? size;

  ContextFileInfo({required this.id, this.filename, this.extension, this.size});
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final bool isLoading;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.isError = false,
  });
}

class AskScreen extends StatefulWidget {
  final List<ContextFileInfo>? contextFiles;

  const AskScreen({super.key, this.contextFiles});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _messageScrollController = ScrollController();
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

  List<ContextFileInfo>? _contextFiles;
  File? file;
  PlatformFile? selectedFileInfo;

  late bool _isGettingResponse = false;
  late LoadingState loadingState;
  final _aiService = AskAi();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
    });

    if (widget.contextFiles != null && widget.contextFiles!.isNotEmpty) {
      print("Received materials: ${widget.contextFiles!.first.filename}");
      // Process the material IDs - perhaps load documents
      // _loadDocumentsById(widget.materialIds!);
    }

    _contextFiles = widget.contextFiles ?? [];
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
    _messageScrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      String message = _textController.text.trim();
      _textController.clear();
      setState(() {
        _isGettingResponse = true;
        _messages.add(
          Message(text: message, isUser: true, timestamp: DateTime.now()),
        );
        _messages.add(
          Message(
            text: "Loading...",
            isUser: false,
            timestamp: DateTime.now(),
            isLoading: true,
          ),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        if (file != null && selectedFileInfo != null) {
          File f = file!;
          PlatformFile info = selectedFileInfo!;

          setState(() {
            file = null;
            selectedFileInfo = null;
            loadingState = LoadingState.uploading;
          });

          _aiService.addFileToChat(f, info).then((res) {
            if (res['task_id'] == null) {
              setState(() {
                _isGettingResponse = false;
                _messages.removeAt(_messages.length - 1);
                _messages.add(
                  Message(
                    text:
                        res['message'] ??
                        "Error when uploading file, try again later",
                    isUser: false,
                    timestamp: DateTime.now(),
                    isError: true,
                  ),
                );
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
              return;
            }
            String taskId = res['task_id'];

            Timer.periodic(const Duration(seconds: 2), (timer) {
              checkTaskStatus(taskId).then((response) {
                if (response['status'] == 'completed') {
                  _queryMessage(message);
                } else {
                  setState(() {
                    _isGettingResponse = false;
                    _messages.removeAt(_messages.length - 1);
                    _messages.add(
                      Message(
                        text: "Error: ${response['message']}",
                        isUser: false,
                        timestamp: DateTime.now(),
                        isError: true,
                      ),
                    );
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
                timer.cancel();
              });
            });
          });
        } else if (_contextFiles != null && _contextFiles!.isNotEmpty) {
          final List<ContextFileInfo>? tmp = _contextFiles;
          setState(() {
            loadingState = LoadingState.generating;
            _contextFiles = null;
          });
          _aiService.addContextFileToChat(tmp!).then((res) {
            if (res['status'] != 'success') {
              setState(() {
                _isGettingResponse = false;
                _messages.removeAt(_messages.length - 1);
                _messages.add(
                  Message(
                    text:
                        res['message'] ??
                        "Error when adding file, try again later",
                    isUser: false,
                    timestamp: DateTime.now(),
                    isError: true,
                  ),
                );
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
              return;
            }
            _queryMessage(message);
          });
        } else {
          _queryMessage(message);
        }
      });
    }
  }

  void _queryMessage(String message) {
    setState(() {
      loadingState = LoadingState.generating;
      _isGettingResponse = true;
    });
    _aiService.sendMessageToChat(message, "123").then((res) {
      String taskId = res['task_id'];

      Timer.periodic(const Duration(seconds: 2), (timer) {
        checkTaskStatus(taskId)
            .then((response) {
              if (response['status'] == 'completed' &&
                  response['message'] != "Empty Response") {
                timer.cancel();
                setState(() {
                  _isGettingResponse = false;
                  _messages.removeAt(_messages.length - 1);
                  _messages.add(
                    Message(
                      text: response['message'],
                      isUser: false,
                      timestamp: DateTime.now(),
                    ),
                  );
                });
              } else {
                setState(() {
                  _isGettingResponse = false;
                  _messages.removeAt(_messages.length - 1);
                  _messages.add(
                    Message(
                      text:
                          "Sorry, I don't have enough information to answer your question.",
                      isUser: false,
                      timestamp: DateTime.now(),
                      isError: true,
                    ),
                  );
                });
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
                _inputFocusNode.requestFocus();
              });
            })
            .catchError((error) {
              setState(() {
                _isGettingResponse = false;
                _messages.removeAt(_messages.length - 1);
                _messages.add(
                  Message(
                    text: "Error: $error",
                    isUser: false,
                    timestamp: DateTime.now(),
                    isError: true,
                  ),
                );
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
                _inputFocusNode.requestFocus();
              });
            });
      });
    });
  }

  void _scrollToBottom() {
    if (_messageScrollController.hasClients) {
      _messageScrollController.animateTo(
        _messageScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _pickFile() async {
    if (_contextFiles != null && _contextFiles!.isNotEmpty)
      _contextFiles = null;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'txt'],
    );

    if (result != null) {
      setState(() {
        file = File(result.files.first.path!);
        selectedFileInfo = result.files.first;
      });
      print("File selected: ${file!.path}");
    } else {
      print("No file selected");
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
            child: AnimationConfiguration.staggeredList(
              position: 1,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child:
                      _messages.isEmpty
                          ? _buildEmptyState(cs)
                          : _buildMessageList(cs),
                ),
              ),
            ),
          ),
          AnimationConfiguration.staggeredList(
            position: 0,
            duration: const Duration(milliseconds: 600),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildInputArea(cs, placeholderColor),
              ),
            ),
          ),
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
    return ShaderMask(
      shaderCallback:
          (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: const [0.0, 0.038, 0.95, 1.0],
          ).createShader(bounds),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _messages.length,
        reverse: false,
        controller: _messageScrollController,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageBubble(message, cs);
        },
      ),
    );
  }

  Widget _buildMessageBubble(Message message, ColorScheme cs) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              message.isUser
                  ? cs.primary
                  : message.isError
                  ? cs.error.withValues(alpha: 0.2)
                  : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child:
            message.isLoading
                ? Row(
                  children: [
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: message.isUser ? cs.onPrimary : cs.onSurface,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      loadingState.message,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                )
                : Text(
                  message.text.trim(),
                  style: TextStyle(
                    color:
                        message.isUser
                            ? cs.onPrimary
                            : message.isError
                            ? cs.error
                            : cs.onSurfaceVariant,
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
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
        child: Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
              child: _buildContextFileList(cs),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _isGettingResponse ? null : _pickFile,
                  icon: Icon(
                    PhosphorIconsRegular.plus,
                    color: placeholderColor,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _inputFocusNode,
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: "Ask anything...",
                      hintStyle: TextStyle(color: placeholderColor),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) {
                      if (_textController.text.trim().isNotEmpty &&
                          !_isGettingResponse) {
                        _sendMessage();
                      }
                    },
                    autofocus: true,
                  ),
                ),
                IconButton(
                  onPressed:
                      _textController.text.trim().isNotEmpty &&
                              !_isGettingResponse
                          ? _sendMessage
                          : null,
                  icon: Icon(
                    PhosphorIconsFill.paperPlaneTilt,
                    color:
                        _textController.text.trim().isNotEmpty
                            ? cs.primary
                            : placeholderColor,
                  ),
                  padding: const EdgeInsets.all(12),
                  color:
                      _textController.text.trim().isNotEmpty
                          ? cs.primary.withValues(alpha: 0.25)
                          : Colors.transparent,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextFileList(ColorScheme cs) {
    String name;
    if (file != null && selectedFileInfo != null) {
      name = selectedFileInfo!.name;
    } else if (_contextFiles != null && _contextFiles!.isNotEmpty) {
      name = _contextFiles!.first.filename ?? "File";
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(PhosphorIconsRegular.fileText, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: cs.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(PhosphorIconsRegular.x, color: cs.primary),
            onPressed: () {
              setState(() {
                file = null;
                selectedFileInfo = null;
                _contextFiles = null;
              });
            },
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
