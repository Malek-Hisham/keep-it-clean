import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription? _sub1;
  static StreamSubscription? _sub2;

  static Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _local.initialize(initSettings);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n != null) _showLocalNotification(title: n.title ?? '', body: n.body ?? '');
    });
    await _saveToken();
    _messaging.onTokenRefresh.listen(_updateToken);
  }

  static Future<void> startListeningToNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _sub1?.cancel();
    await _sub2?.cancel();
    final Set<String> shown = {};

    // Query 1: للـ uid المحدد
    _sub1 = FirebaseFirestore.instance
        .collection('notifications')
        .where('targetUid', isEqualTo: uid)
        .where('delivered', isEqualTo: false)
        .snapshots()
        .listen((snap) => _handleSnap(snap, shown));

    // Query 2: للـ all
    _sub2 = FirebaseFirestore.instance
        .collection('notifications')
        .where('targetUid', isEqualTo: 'all')
        .where('delivered', isEqualTo: false)
        .snapshots()
        .listen((snap) => _handleSnap(snap, shown));
  }

  static void _handleSnap(QuerySnapshot snap, Set<String> shown) {
    for (final doc in snap.docs) {
      if (shown.contains(doc.id)) continue;
      shown.add(doc.id);
      final d = doc.data() as Map<String, dynamic>;
      _showLocalNotification(title: d['title'] ?? '', body: d['body'] ?? '');
      FirebaseFirestore.instance.collection('notifications').doc(doc.id).update({'delivered': true});
    }
  }

  static Future<void> stopListening() async {
    await _sub1?.cancel();
    await _sub2?.cancel();
    _sub1 = null;
    _sub2 = null;
  }

  static Future<void> _saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final token = await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  static Future<void> _updateToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
  }

  static Future<void> _showLocalNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'keep_it_clean_channel', 'Keep it Clean',
      channelDescription: 'Keep it Clean Volunteer App Notifications',
      importance: Importance.high, priority: Priority.high,
      showWhen: true, icon: '@mipmap/ic_launcher',
    );
    await _local.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, const NotificationDetails(android: androidDetails));
  }

  static Future<void> sendNotificationToUser({required String uid, required String title, required String body}) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'targetUid': uid, 'title': title, 'body': body,
      'read': false, 'delivered': false, 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendNotificationToAll({required String title, required String body}) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'targetUid': 'all', 'title': title, 'body': body,
      'read': false, 'delivered': false, 'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// ─── Notifications Screen ───
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final card = theme.cardColor;
    final isAr = localeNotifier.value.languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(child: Column(children: [
          Container(height: 8, decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen]))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded), color: primaryBlue),
              Text(isAr ? 'الإشعارات' : 'Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue)),
            ]),
          ),
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              // نجيب الاتنين queries مع بعض بدون orderBy
              future: Future.wait([
                FirebaseFirestore.instance.collection('notifications').where('targetUid', isEqualTo: uid).get().then((s) => s.docs),
                FirebaseFirestore.instance.collection('notifications').where('targetUid', isEqualTo: 'all').get().then((s) => s.docs),
              ]).then((results) {
                final all = [...results[0], ...results[1]];
                all.sort((a, b) {
                  final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
                  final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs);
                });
                return all;
              }),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!;
                if (docs.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.notifications_none_rounded, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                    const SizedBox(height: 12),
                    Text(isAr ? 'لا توجد إشعارات' : 'No notifications yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16)),
                  ]));
                }
                return RefreshIndicator(
                  onRefresh: () async { (context as Element).markNeedsBuild(); },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final isRead = d['read'] as bool? ?? false;
                      final ts = d['createdAt'] as Timestamp?;
                      String timeStr = '';
                      if (ts != null) {
                        final dt = ts.toDate();
                        timeStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      }
                      return GestureDetector(
                        onTap: () {
                          if (!isRead) {
                            FirebaseFirestore.instance.collection('notifications').doc(docs[i].id).update({'read': true});
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isRead ? card : primaryBlue.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: isRead ? null : Border.all(color: primaryBlue.withOpacity(0.2)),
                            boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)],
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(height: 42, width: 42, decoration: BoxDecoration(color: primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(isRead ? Icons.notifications_rounded : Icons.notifications_active_rounded, color: primaryBlue, size: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(d['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: isDark ? Colors.white : const Color(0xFF101828)))),
                                if (!isRead) Container(width: 8, height: 8, decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle)),
                              ]),
                              const SizedBox(height: 4),
                              Text(d['body'] ?? '', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54, height: 1.4)),
                              const SizedBox(height: 6),
                              Text(timeStr, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
                            ])),
                          ]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ])),
      ),
    );
  }
}

// ─── Send Notification Dialog ───
class SendNotificationDialog extends StatefulWidget {
  final String? targetUid;
  final String? targetName;
  const SendNotificationDialog({super.key, this.targetUid, this.targetName});

  @override
  State<SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<SendNotificationDialog> {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  bool _sending = false;
  bool get isAr => localeNotifier.value.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.targetUid == null ? (isAr ? 'إرسال لجميع المتطوعين' : 'Send to All Volunteers') : (isAr ? 'إرسال إلى ${widget.targetName}' : 'Send to ${widget.targetName}'),
        style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: isAr ? 'عنوان الإشعار' : 'Notification Title', labelStyle: TextStyle(color: primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 12),
        TextField(controller: bodyCtrl, maxLines: 3, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: isAr ? 'نص الإشعار' : 'Notification Body', labelStyle: TextStyle(color: primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _sending ? null : () async {
            if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
            setState(() => _sending = true);
            if (widget.targetUid != null) {
              await NotificationService.sendNotificationToUser(uid: widget.targetUid!, title: titleCtrl.text.trim(), body: bodyCtrl.text.trim());
            } else {
              await NotificationService.sendNotificationToAll(title: titleCtrl.text.trim(), body: bodyCtrl.text.trim());
            }
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'تم إرسال الإشعار ✅' : 'Notification sent ✅'), backgroundColor: Colors.green));
            }
          },
          child: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isAr ? 'إرسال' : 'Send'),
        ),
      ],
    );
  }
}