import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
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
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primaryBlue, primaryGreen]),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tasks')
                          .where('assignedTo', arrayContains: uid)
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red)));
                        }
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snap.data!.docs;

                        docs.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final aDate = aData['dueDate'];
                          final bDate = bData['dueDate'];
                          if (aDate == null) return 1;
                          if (bDate == null) return -1;
                          return (aDate as Timestamp).compareTo(bDate as Timestamp);
                        });

                        final pending = docs.where((d) => (d.data() as Map)['status'] != 'done').toList();
                        final done = docs.where((d) => (d.data() as Map)['status'] == 'done').toList();

                        double totalHours = 0;
                        for (final d in done) {
                          final data = d.data() as Map<String, dynamic>;
                          totalHours += (data['hours'] as num? ?? 0).toDouble();
                        }

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'مهامي' : 'My Tasks',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryBlue),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr ? 'تابع مهامك التطوعية' : 'Track your volunteer assignments',
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  _summaryCard('${pending.length}', isAr ? 'قيد التنفيذ' : 'Pending', primaryBlue, card, isDark, Icons.pending_actions_rounded),
                                  const SizedBox(width: 10),
                                  _summaryCard('${done.length}', isAr ? 'مكتملة' : 'Completed', primaryGreen, card, isDark, Icons.check_circle_rounded),
                                  const SizedBox(width: 10),
                                  _summaryCard('${totalHours.toStringAsFixed(0)}h', isAr ? 'ساعات' : 'Hours', Colors.orange, card, isDark, Icons.timer_rounded),
                                ],
                              ),
                              const SizedBox(height: 24),

                              if (docs.isEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24)),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.task_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                                        const SizedBox(height: 12),
                                        Text(isAr ? 'لا توجد مهام معيّنة بعد' : 'No tasks assigned yet', style: TextStyle(fontSize: 16, color: isDark ? Colors.white38 : Colors.black38)),
                                        const SizedBox(height: 6),
                                        Text(isAr ? 'سيقوم المدير بتعيين مهام لك قريباً' : 'Your admin will assign tasks to you soon', style: TextStyle(fontSize: 13, color: isDark ? Colors.white24 : Colors.black26)),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                if (pending.isNotEmpty) ...[
                                  Text(isAr ? 'المهام قيد التنفيذ' : 'Pending Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
                                  const SizedBox(height: 12),
                                  ...pending.map((doc) => _TaskCard(doc: doc, uid: uid, isDark: isDark, card: card, isAr: isAr)),
                                  const SizedBox(height: 20),
                                ],
                                if (done.isNotEmpty) ...[
                                  Text(isAr ? 'المهام المكتملة' : 'Completed Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen)),
                                  const SizedBox(height: 12),
                                  ...done.map((doc) => _TaskCard(doc: doc, uid: uid, isDark: isDark, card: card, isDone: true, isAr: isAr)),
                                ],
                              ],
                              const SizedBox(height: 30),
                            ],
                          ),
                        );
                      },
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

  Widget _summaryCard(String value, String label, Color color, Color cardColor, bool isDark, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String uid;
  final bool isDark;
  final Color card;
  final bool isDone;
  final bool isAr;

  const _TaskCard({
    required this.doc,
    required this.uid,
    required this.isDark,
    required this.card,
    this.isDone = false,
    this.isAr = false,
  });

  Future<void> _markDone() async {
    await FirebaseFirestore.instance.collection('tasks').doc(doc.id).update({
      'status': 'done',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _markPending() async {
    await FirebaseFirestore.instance.collection('tasks').doc(doc.id).update({'status': 'pending'});
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'campaign': return Icons.campaign_rounded;
      case 'school': return Icons.school_rounded;
      case 'event': return Icons.groups_rounded;
      case 'report': return Icons.assignment_rounded;
      case 'visit': return Icons.location_on_rounded;
      default: return Icons.task_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final color = isDone ? primaryGreen : primaryBlue;
    final hours = (data['hours'] as num? ?? 0).toDouble();

    String dateStr = '';
    final dueDate = data['dueDate'];
    if (dueDate is Timestamp) {
      final dt = dueDate.toDate();
      dateStr = '${dt.day}/${dt.month}/${dt.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: isDone ? Border.all(color: primaryGreen.withOpacity(0.3)) : null,
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 50, width: 50,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(15)),
                  child: Icon(_getIcon(data['type']), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? (isDark ? Colors.white38 : Colors.black45) : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if ((data['location'] ?? '').isNotEmpty)
                        Text('📍 ${data['location']}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                      if (dateStr.isNotEmpty)
                        Text('📅 $dateStr', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                      if (hours > 0)
                        Text(
                          '⏱ ${hours.toStringAsFixed(0)} ${isAr ? "ساعة تطوع" : "volunteer hours"}',
                          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    isDone ? (isAr ? 'مكتمل' : 'Done') : (isAr ? 'قيد التنفيذ' : 'Pending'),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
          ),
          if (data['description'] != null && (data['description'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                child: Text(data['description'], style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54, height: 1.5)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: isDone
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryGreen,
                        side: BorderSide(color: primaryGreen.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _markPending,
                      icon: const Icon(Icons.undo_rounded, size: 16),
                      label: Text(isAr ? 'إعادة للمعلقة' : 'Mark as Pending', style: const TextStyle(fontSize: 13)),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _markDone,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(isAr ? 'تم الإنجاز' : 'Mark as Done', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}