import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isAr => localeNotifier.value.languageCode == 'ar';

  void _openChatbot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatbotSheet(isAr: _isAr),
    );
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case 'Drug Alert': return Icons.warning_amber_rounded;
      case 'Volunteer Achievement': return Icons.emoji_events_rounded;
      case 'Campaign Update': return Icons.campaign_rounded;
      default: return Icons.newspaper_rounded;
    }
  }

  Color _categoryColor(String? category, Color primary, Color secondary) {
    switch (category) {
      case 'Drug Alert': return Colors.redAccent;
      case 'Volunteer Achievement': return Colors.amber;
      case 'Campaign Update': return secondary;
      default: return primary;
    }
  }

  String _categoryLabel(String? category) {
    if (!_isAr) return category ?? 'News';
    switch (category) {
      case 'Drug Alert': return 'تنبيه مخدرات';
      case 'Volunteer Achievement': return 'إنجاز متطوع';
      case 'Campaign Update': return 'تحديث حملة';
      case 'Announcement': return 'إعلان';
      default: return 'أخبار';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final card = theme.cardColor;

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            floatingActionButton: FloatingActionButton(
              onPressed: () => _openChatbot(context),
              backgroundColor: primaryBlue,
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen])),
                  ),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [primaryBlue, primaryGreen.withOpacity(0.9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8))],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(isAr ? 'إدارة المتطوعين' : 'Volunteer Management', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(height: 4),
                                        Text(isAr ? 'صندوق مكافحة الإدمان' : 'Drug Addiction Control Fund', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primaryBlue, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen())),
                                          icon: const Icon(Icons.map_rounded, size: 18),
                                          label: Text(isAr ? 'فتح الخريطة' : 'Open Map', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.volunteer_activism_rounded, color: Colors.white38, size: 70),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _statCard(isAr ? 'متطوعون نشطون' : 'Active Volunteers', Icons.groups_2_rounded, primaryBlue, 'users', card, isDark, context)),
                                const SizedBox(width: 12),
                                Expanded(child: _statCard(isAr ? 'مناطق الحملات' : 'Campaign Zones', Icons.location_city_rounded, primaryGreen, null, card, isDark, context)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Text(isAr ? 'آخر الأخبار' : 'Latest News', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue)),
                                const Spacer(),
                                Icon(Icons.fiber_new_rounded, color: primaryGreen, size: 28),
                              ],
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('news').orderBy('createdAt', descending: true).snapshots(),
                              builder: (context, snap) {
                                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                                final docs = snap.data!.docs;
                                if (docs.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
                                    child: Center(child: Column(children: [
                                      Icon(Icons.newspaper_rounded, color: isDark ? Colors.white24 : Colors.black12, size: 48),
                                      const SizedBox(height: 8),
                                      Text(isAr ? 'لا توجد أخبار بعد' : 'No news yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
                                    ])),
                                  );
                                }
                                return Column(
                                  children: docs.map((doc) {
                                    final d = doc.data() as Map<String, dynamic>;
                                    final category = d['category'] as String?;
                                    final color = _categoryColor(category, primaryBlue, primaryGreen);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3))]),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(height: 46, width: 46, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(_categoryIcon(category), color: color, size: 24)),
                                          const SizedBox(width: 12),
                                          Expanded(child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                                child: Text(_categoryLabel(category), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(d['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF101828))),
                                              const SizedBox(height: 4),
                                              Text(d['body'] ?? '', style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white60 : Colors.black54)),
                                            ],
                                          )),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String title, IconData icon, Color color, String? collection, Color card, bool isDark, BuildContext context) {
    if (collection == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 42, width: 42, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 12),
          Text('18', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
        ]),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 42, width: 42, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 22)),
            const SizedBox(height: 12),
            Text('$count', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
          ]),
        );
      },
    );
  }
}

// ─── CHATBOT (Groq) ───
class _ChatMessage {
  final String text;
  final bool isBot;
  _ChatMessage({required this.text, required this.isBot});
}

class _ChatbotSheet extends StatefulWidget {
  final bool isAr;
  const _ChatbotSheet({this.isAr = false});

  @override
  State<_ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<_ChatbotSheet> {
  late final List<_ChatMessage> _messages;
  final List<Map<String, String>> _history = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isLoading = false;

  static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';
static const String _model = 'llama-3.1-8b-instant';
  static const String _systemPrompt =
      'You are a helpful assistant for a volunteer management app called "Volunteer Management - Drug Addiction Control Fund". '
      'Answer questions about volunteering, courses, tasks, campaigns, and the app features. '
      'Be concise and friendly. Reply in the same language the user writes in. '
      'If asked in Arabic, respond in Arabic. If asked in English, respond in English.';

  @override
  void initState() {
    super.initState();
    _messages = [
      _ChatMessage(
        text: widget.isAr
            ? 'مرحباً! 👋 أنا مساعدك الذكي. اسألني أي شيء عن التطوع والكورسات والمهام!'
            : 'Hi! 👋 I\'m your Volunteer Assistant. Ask me anything about volunteering, courses, and tasks!',
        isBot: true,
      ),
    ];
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isBot: false));
      _isLoading = true;
    });
    _input.clear();
    _scrollToBottom();

    _history.add({'role': 'user', 'content': text});

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ..._history,
          ],
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        _history.add({'role': 'assistant', 'content': reply});
        if (mounted) {
          setState(() {
            _isLoading = false;
            _messages.add(_ChatMessage(text: reply, isBot: true));
          });
          _scrollToBottom();
        }
      } else {
        final errBody = jsonDecode(response.body);
        final errMsg = errBody['error']?['message'] ?? 'Status ${response.statusCode}';
        if (mounted) setState(() { _isLoading = false; _messages.add(_ChatMessage(text: 'خطأ: $errMsg', isBot: true)); });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _messages.add(_ChatMessage(text: 'خطأ في الاتصال: $e', isBot: true)); });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final card = theme.cardColor;
    final bg = theme.scaffoldBackgroundColor;
    final isAr = widget.isAr;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24)],
        ),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), height: 4, width: 44, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(8))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    height: 46, width: 46,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen]), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isAr ? 'مساعد المتطوعين' : 'Volunteer Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? Colors.white : const Color(0xFF101828))),
                      Text(isAr ? 'مدعوم بـ Groq AI ✨' : 'Powered by Groq AI ✨', style: TextStyle(fontSize: 13, color: primaryGreen, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Spacer(),
                  Container(height: 10, width: 10, decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle)),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) return _loadingBubble(primaryBlue, primaryGreen, isDark);
                  return _bubble(_messages[index], primaryBlue, primaryGreen, card, isDark);
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: BoxDecoration(color: card, border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: isAr ? 'اسألني أي شيء...' : 'Ask me anything...',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _sendMessage(_input.text),
                    child: Container(
                      height: 48, width: 48,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen]), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
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

  Widget _loadingBubble(Color primaryBlue, Color primaryGreen, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(height: 32, width: 32, decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1.0),
                duration: Duration(milliseconds: 500 + i * 150),
                builder: (_, v, __) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 8, height: 8, decoration: BoxDecoration(color: primaryBlue.withOpacity(v), shape: BoxShape.circle)),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_ChatMessage msg, Color primaryBlue, Color primaryGreen, Color card, bool isDark) {
    final isBot = msg.isBot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(height: 32, width: 32, decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isBot ? (isDark ? Colors.white.withOpacity(0.08) : Colors.white) : primaryBlue,
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isBot ? 4 : 18), bottomRight: Radius.circular(isBot ? 18 : 4)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(msg.text, style: TextStyle(fontSize: 14.5, height: 1.5, color: isBot ? (isDark ? Colors.white : const Color(0xFF101828)) : Colors.white)),
            ),
          ),
          if (!isBot) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
