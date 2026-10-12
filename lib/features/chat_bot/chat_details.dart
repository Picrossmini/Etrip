import 'dart:async';

import 'package:etrip/core/localization/locale_cubit.dart';
import 'package:etrip/core/localization/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:etrip/core/constants.dart';
import 'package:etrip/core/widgets/reusable_screen.dart';
import 'package:etrip/core/widgets/robot_panda_logo.dart';
import 'package:etrip/core/widgets/space_widget.dart';
import 'package:etrip/features/chat_bot/data/chat_history_service.dart';
import 'package:etrip/features/chat_bot/data/chat_api_service.dart';

class ChatDetails extends StatefulWidget {
  const ChatDetails({super.key});

  @override
  State<ChatDetails> createState() => _ChatDetailsState();
}

class _ChatDetailsState extends State<ChatDetails> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatApiService _api = ChatApiService();
  final List<Map<String, String>> _messages = [];
  bool _isSending = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _messages.addAll(ChatHistoryService.load());
    if (_messages.isNotEmpty) _scrollToBottom();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startNewChat() {
    _typingTimer?.cancel();
    ChatHistoryService.clear();
    setState(() {
      _messages.clear();
      _isSending = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Replaces the last bot bubble with [reply] one character at a time.
  void _showReplyWithTypewriter(String reply) {
    _typingTimer?.cancel();
    var shown = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      shown = (shown + 2).clamp(0, reply.length);
      setState(() {
        _messages.last = {'role': 'bot', 'text': reply.substring(0, shown)};
      });
      _scrollToBottom();
      if (shown >= reply.length) {
        timer.cancel();
        setState(() => _isSending = false);
      }
    });
  }

  Future<void> _sendMessage([String? preset]) async {
    final userMessage = (preset ?? _controller.text).trim();
    if (userMessage.isEmpty || _isSending) return;

    final lang = context.read<LocaleCubit>().state.languageCode;
    final history = List<Map<String, String>>.from(_messages)
      ..add({'role': 'user', 'text': userMessage});

    setState(() {
      _isSending = true;
      _messages.add({'role': 'user', 'text': userMessage});
      _messages
          .add({'role': 'bot', 'text': Translations.tr('bot_thinking', lang)});
    });
    _controller.clear();
    _scrollToBottom();

    String reply;
    try {
      reply = await _api.chat(history, lang);
      if (reply.isEmpty) throw Exception('empty reply');
    } catch (_) {
      // Offline / API unreachable: show only a network notice, nothing else.
      reply = Translations.tr('chat_error', lang);
    }

    // Persist the full reply immediately so leaving mid-animation loses
    // nothing.
    ChatHistoryService.save([...history, {'role': 'bot', 'text': reply}]);

    if (!mounted) return;
    _showReplyWithTypewriter(reply);
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const RobotPandaLogo(size: 150),
          const VerticalSpace(2),
          Text(
            Translations.tr('chatbot_greeting', lang),
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips(String lang) {
    final suggestions = [
      Translations.tr('chat_suggest_1', lang),
      Translations.tr('chat_suggest_3', lang),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          for (final suggestion in suggestions) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => _sendMessage(suggestion),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: EdgeInsets.only(
                      right: suggestion == suggestions.last ? 0 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    suggestion,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message['text'] ?? '',
            style: GoogleFonts.montserrat(color: Colors.black, fontSize: 15),
          ),
        ),
      );
    }
    // DeepSeek style: assistant replies are plain markdown text, no bubble.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 8),
            child: RobotPandaLogo(size: 28),
          ),
          Expanded(
            child: GptMarkdown(
              message['text'] ?? '',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleCubit>().state.languageCode;
    return ReusableScreen(
      showBackButton: true,
      backgroundColor: kMainColor,
      imageColor: Colors.black,
      gradientStops: const [0.1, 0.7],
      child: SafeArea(
        child: Column(
          children: [
            const VerticalSpace(3),

            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Text(
                    Translations.tr('chatbot_title', lang),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(radius: 5, backgroundColor: Colors.green),
                  const Spacer(),
                  IconButton(
                    onPressed: _startNewChat,
                    tooltip: Translations.tr('start_new_chat', lang),
                    icon: const Icon(
                      Icons.add_comment_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            // Messages List
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(lang)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) =>
                          _buildMessage(_messages[index]),
                    ),
            ),
            // Suggestion chips above the input bar (only for a fresh chat)
            if (_messages.isEmpty) _buildSuggestionChips(lang),
            // Typing Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _sendMessage(),
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: Translations.tr('ask_me', lang),
                          hintStyle: GoogleFonts.playfairDisplaySc(
                            // <-- Hint text
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSending
                            ? Colors.limeAccent.withValues(alpha: 0.4)
                            : Colors.limeAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
