import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  final String? targetUid;
  final String? targetName;
  final bool isTab;
  const ChatScreen({super.key, this.targetUid, this.targetName, this.isTab = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';
  bool _isAdmin = false;
  bool _checked = false;
  String _chatId = '';
  final Map<String, String?> _photoCache = {};

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      final doc = await FirebaseFirestore.instance.collection('admins').doc(email).get();
      if (mounted) {
        _isAdmin = doc.exists;
        _chatId = _isAdmin && widget.targetUid != null ? widget.targetUid! : _currentUid;
        setState(() => _checked = true);
      }
    } catch (_) {
      if (mounted) setState(() => _checked = true);
    }
  }

  Future<String?> _getPhoto(String uid) async {
    if (uid.isEmpty) return null;
    if (_photoCache.containsKey(uid)) return _photoCache[uid];
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final photo = (doc.data() as Map?)?['photoBase64'] as String?;
      _photoCache[uid] = photo;
      return photo;
    } catch (_) {
      _photoCache[uid] = null;
      return null;
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _chatId.isEmpty) return;
    _input.clear();
    try {
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').add({
        'text': text,
        'senderUid': _currentUid,
        'senderEmail': _currentEmail,
        'isAdmin': _isAdmin,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
        'lastMessage': text,
        'lastAt': FieldValue.serverTimestamp(),
        'volunteerUid': _chatId,
      }, SetOptions(merge: true));
      _scrollToBottom();
    } catch (e) {
      debugPrint('Send error: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
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
    final isAr = localeNotifier.value.languageCode == 'ar';

    if (!_checked) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chatTitle = _isAdmin
        ? (widget.targetName ?? (isAr ? 'متطوع' : 'Volunteer'))
        : (isAr ? 'الدعم والمساعدة' : 'Support Chat');

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !widget.isTab,
          leading: widget.isTab ? null : IconButton(
            icon: Icon(isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
            
          ),
          title: Row(children: [
            FutureBuilder<String?>(
              future: _isAdmin ? _getPhoto(widget.targetUid ?? '') : Future.value(null),
              builder: (context, snap) {
                final photo = snap.data;
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: photo != null ? MemoryImage(base64Decode(photo)) : null,
                  child: photo == null
                      ? Text(chatTitle.isNotEmpty ? chatTitle[0].toUpperCase() : 'V',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                      : null,
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(chatTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(isAr ? 'متصل الآن' : 'Online',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
            ])),
          ]),
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(_chatId)
                      .collection('messages')
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text(isAr ? 'حدث خطأ' : 'Error',
                          style: const TextStyle(color: Colors.redAccent)));
                    }
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                    final docs = snap.data!.docs;
                    docs.sort((a, b) {
                      final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
                      final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
                      if (aTs == null) return -1;
                      if (bTs == null) return 1;
                      return aTs.compareTo(bTs);
                    });

                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    if (docs.isEmpty) {
                      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 64,
                            color: isDark ? Colors.white24 : Colors.black12),
                        const SizedBox(height: 12),
                        Text(isAr ? 'ابدأ المحادثة!' : 'Start the conversation!',
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16)),
                      ]));
                    }

                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        final isMine = d['senderUid'] == _currentUid;
                        final text = d['text'] as String? ?? '';
                        final isAdminMsg = d['isAdmin'] as bool? ?? false;
                        final senderUid = d['senderUid'] as String? ?? '';
                        final ts = d['createdAt'] as Timestamp?;
                        final timeStr = ts != null
                            ? '${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
                            : '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMine) ...[
                                FutureBuilder<String?>(
                                  future: isAdminMsg ? Future.value(null) : _getPhoto(senderUid),
                                  builder: (context, photoSnap) {
                                    final photo = photoSnap.data;
                                    return CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isAdminMsg
                                          ? primaryBlue.withOpacity(0.2)
                                          : primaryGreen.withOpacity(0.2),
                                      backgroundImage: photo != null ? MemoryImage(base64Decode(photo)) : null,
                                      child: photo == null
                                          ? Icon(isAdminMsg ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                              size: 18, color: isAdminMsg ? primaryBlue : primaryGreen)
                                          : null,
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                              Column(
                                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMine ? primaryBlue : (isDark ? Colors.white.withOpacity(0.1) : card),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isMine ? 18 : 4),
                                        bottomRight: Radius.circular(isMine ? 4 : 18),
                                      ),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                                    ),
                                    child: Text(text, style: TextStyle(fontSize: 14.5, height: 1.4,
                                        color: isMine ? Colors.white : (isDark ? Colors.white : Colors.black87))),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(timeStr, style: TextStyle(fontSize: 10,
                                      color: isDark ? Colors.white38 : Colors.black38)),
                                ],
                              ),
                              if (isMine) ...[
                                const SizedBox(width: 8),
                                FutureBuilder<String?>(
                                  future: _isAdmin ? Future.value(null) : _getPhoto(_currentUid),
                                  builder: (context, photoSnap) {
                                    final photo = photoSnap.data;
                                    return CircleAvatar(
                                      radius: 18,
                                      backgroundColor: primaryBlue.withOpacity(0.2),
                                      backgroundImage: photo != null ? MemoryImage(base64Decode(photo)) : null,
                                      child: photo == null
                                          ? Icon(_isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                              size: 18, color: primaryBlue)
                                          : null,
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Input bar — بدون viewInsets عشان SafeArea + resizeToAvoidBottomInset بيعملوه تلقائي
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: card,
                  border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: isAr ? 'اكتب رسالة...' : 'Type a message...',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      height: 48, width: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primaryBlue, primaryGreen]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Admin Chat List ───
class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final card = theme.cardColor;
    final isAr = localeNotifier.value.languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(child: Column(children: [
          Container(height: 8, decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen]))),
          Padding(padding: const EdgeInsets.all(18),
              child: Text(isAr ? 'المحادثات' : 'Chats',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue))),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final users = snap.data!.docs;
                if (users.isEmpty) return Center(child: Text(isAr ? 'لا يوجد متطوعون' : 'No volunteers yet',
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final d = users[i].data() as Map<String, dynamic>;
                    final uid = users[i].id;
                    final name = d['name'] ?? 'Unknown';
                    final photo = d['photoBase64'] as String?;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)]),
                      child: ListTile(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ChatScreen(targetUid: uid, targetName: name))),
                        leading: CircleAvatar(
                          backgroundColor: primaryBlue.withOpacity(0.15),
                          backgroundImage: photo != null ? MemoryImage(base64Decode(photo)) : null,
                          child: photo == null
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'V',
                                  style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF101828))),
                        subtitle: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('chats').doc(uid)
                              .collection('messages').orderBy('createdAt', descending: true).limit(1).snapshots(),
                          builder: (context, msgSnap) {
                            if (!msgSnap.hasData || msgSnap.data!.docs.isEmpty) {
                              return Text(isAr ? 'ابدأ المحادثة' : 'Start chatting',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38));
                            }
                            final lastMsg = (msgSnap.data!.docs.first.data() as Map)['text'] ?? '';
                            return Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45));
                          },
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.chat_rounded, color: primaryBlue, size: 20),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ])),
      ),
    );
  }
}