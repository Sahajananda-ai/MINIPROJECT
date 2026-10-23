import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/savebite_theme.dart';

/// A message in the concierge chat.
class _ChatMessage {
  final String text;
  final bool isUser;
  final String? source; // 'gemini' or 'rules' for AI replies

  const _ChatMessage(this.text, {this.isUser = false, this.source});
}

/// Ask SaveBite AI — a real assistant grounded in live mystery-box data.
///
/// It answers questions about what's available right now, the best deals,
/// prices, and how pickup works, using the server's /ai/chat endpoint so
/// answers reflect real shops and prices, not guesses.
class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen({super.key});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  static const List<String> _suggestions = [
    "What's the best deal right now?",
    "How does pickup work?",
    "Any boxes under ₹100?",
    "Are there vegetarian options?",
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(const _ChatMessage(
      "Hi! I'm your SaveBite assistant 🌿. Ask me what's available, the best "
      "deals, prices, or how pickup works — I answer using live data.",
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final message = text.trim();
    if (message.isEmpty || _loading) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(message, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    final result = await ApiService.askConcierge(message);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result != null && result['reply'] != null) {
        _messages.add(_ChatMessage(
          result['reply'] as String,
          source: result['source'] as String?,
        ));
      } else {
        _messages.add(const _ChatMessage(
          "Sorry, I couldn't reach the SaveBite server. Check that the backend "
          "is running and try again.",
        ));
      }
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaveBiteTheme.cream,
      appBar: AppBar(
        backgroundColor: SaveBiteTheme.cream,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SaveBiteTheme.charcoal),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SaveBiteTheme.tealWash,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: SaveBiteTheme.tealPrimary, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ask SaveBite AI", style: SaveBiteTheme.title(size: 16)),
                Text(
                  "Live answers about today's boxes",
                  style: SaveBiteTheme.body(size: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
          if (_messages.length <= 1) _buildSuggestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions
            .map((s) => ActionChip(
                  onPressed: () => _send(s),
                  backgroundColor: SaveBiteTheme.white,
                  side: const BorderSide(color: SaveBiteTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  label: Text(
                    s,
                    style: SaveBiteTheme.body(size: 12, color: SaveBiteTheme.tealPrimary, w: FontWeight.w600),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: const BoxDecoration(
          color: SaveBiteTheme.cream,
          border: Border(top: BorderSide(color: SaveBiteTheme.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                style: SaveBiteTheme.body(size: 14, color: SaveBiteTheme.charcoal),
                decoration: InputDecoration(
                  hintText: "Ask about deals, prices, pickup…",
                  hintStyle: SaveBiteTheme.body(size: 14),
                  filled: true,
                  fillColor: SaveBiteTheme.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: SaveBiteTheme.borderInput),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: SaveBiteTheme.borderInput),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: SaveBiteTheme.tealPrimary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: _loading ? null : () => _send(_controller.text),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isUser ? SaveBiteTheme.tealPrimary : SaveBiteTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: SaveBiteTheme.cardShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: isUser ? Colors.white : SaveBiteTheme.charcoal,
              ),
            ),
            if (!isUser && message.source != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: message.source == 'gemini'
                        ? SaveBiteTheme.tealPrimary
                        : SaveBiteTheme.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    message.source == 'gemini' ? 'Gemini' : 'Live data',
                    style: SaveBiteTheme.eyebrow(
                      size: 9,
                      color: message.source == 'gemini'
                          ? SaveBiteTheme.tealPrimary
                          : SaveBiteTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: SaveBiteTheme.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: SaveBiteTheme.cardShadow(),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (_c.value - i * 0.2) % 1.0;
                final opacity = (phase < 0.5 ? phase : 1 - phase) * 2;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Opacity(
                    opacity: 0.3 + opacity * 0.7,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: SaveBiteTheme.tealPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
