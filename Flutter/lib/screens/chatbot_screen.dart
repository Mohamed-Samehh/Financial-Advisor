import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../screens/navbar.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ChatbotScreenState createState() => ChatbotScreenState();
}

class ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  String? errorMessage;
  bool isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add({'role': 'user', 'content': _messageController.text});
      isLoading = true;
      messages.add({'role': 'bot', 'content': ''});
      errorMessage = null;
    });

    _scrollToBottom();
    final messageToSend = _messageController.text;
    _messageController.clear();

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.sendChatMessage(messageToSend);
      setState(() {
        isLoading = false;
        messages.removeWhere((msg) => msg['content'] == '');
        if (response['message'] != null) {
          messages.add({'role': 'bot', 'content': response['message']});
        } else {
          messages.add({
            'role': 'bot',
            'content':
                "I'm sorry, but I couldn't generate a response. Please try again or ask in a different way.",
          });
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        messages.removeWhere((msg) => msg['content'] == '');
        errorMessage = 'Failed to get a response. Please try again.';
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Builder(
          builder: (BuildContext appBarContext) {
            return Navbar(
              onMenuPressed: () => Scaffold.of(appBarContext).openDrawer(),
            );
          },
        ),
      ),
      drawer: Navbar.buildDrawer(context),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Header Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.blueAccent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.smart_toy,
                              size: 80,
                              color: Colors.white.withAlpha(230),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'AI Financial Chatbot',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Get instant financial advices!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // Messages Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            if (messages.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 60,
                                      color: Colors.blue.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Ready to Boost Your Finances?",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Ask me anything about money matters!",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              Column(
                                children: List.generate(messages.length, (
                                  index,
                                ) {
                                  final msg = messages[index];
                                  final isUser = msg['role'] == 'user';
                                  final isThinking = msg['content'] == '';
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      top:
                                          index > 0 &&
                                                  messages[index - 1]['role'] !=
                                                      msg['role']
                                              ? 15
                                              : 5,
                                    ),
                                    child: Align(
                                      alignment:
                                          isUser
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.75,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isUser
                                                  ? Colors.blue
                                                  : isThinking
                                                  ? const Color(0xFFE3F2FD)
                                                  : const Color(0xFFE3F2FD),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ).copyWith(
                                            bottomRight:
                                                isUser
                                                    ? const Radius.circular(5)
                                                    : null,
                                            bottomLeft:
                                                !isUser && !isThinking
                                                    ? const Radius.circular(5)
                                                    : null,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child:
                                            isThinking
                                                ? AnimatedBuilder(
                                                  animation:
                                                      _animationController,
                                                  builder: (context, child) {
                                                    final dots = [
                                                      '.',
                                                      '..',
                                                      '...',
                                                    ];
                                                    final dotIndex =
                                                        (_animationController
                                                                    .value *
                                                                3)
                                                            .floor() %
                                                        3;
                                                    return Text(
                                                      dots[dotIndex],
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF444444,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                                : isUser
                                                ? Text(
                                                  msg['content']!.replaceAll(
                                                    '\n',
                                                    '\n',
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                )
                                                : MarkdownBody(
                                                  data: msg['content']!,
                                                  styleSheet:
                                                      MarkdownStyleSheet(
                                                        p: const TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.black,
                                                        ),
                                                        strong: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        em: const TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                        code: const TextStyle(
                                                          backgroundColor:
                                                              Colors.grey,
                                                          fontFamily:
                                                              'monospace',
                                                        ),
                                                      ),
                                                ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  fillOverscroll: true,
                  child: Container(),
                ),
              ],
            ),
          ),
          // Input Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Ask for anything!',
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                          ),
                          style: const TextStyle(fontSize: 16),
                          onSubmitted: (value) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.blueAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon:
                              isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const FaIcon(
                                    FontAwesomeIcons.paperPlane,
                                    color: Colors.white,
                                  ),
                          onPressed: isLoading ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: AlertMessage(
                      message: errorMessage!,
                      isError: true,
                      onDismiss: () => setState(() => errorMessage = null),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Reusing AlertMessage from previous screens
class AlertMessage extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  const AlertMessage({
    super.key,
    required this.message,
    required this.isError,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? Colors.red : Colors.green,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red : Colors.green,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${isError ? 'Oops!' : 'Awesome!'} $message',
              style: TextStyle(
                color: isError ? Colors.red[900] : Colors.green[900],
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              color: isError ? Colors.red : Colors.green,
            ),
        ],
      ),
    );
  }
}
