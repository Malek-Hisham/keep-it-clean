import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import 'chat_screen.dart';
import 'attendance_screen.dart';
import '../services/notification_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  bool get _isAr => localeNotifier.value.languageCode == 'ar';

  List<Widget> get _screens => [
    const _AdminHomeTab(),
    const _AdminNewsTab(),
    const _AdminCoursesTab(),
    const _AdminTasksTab(),
    const _AdminCampaignsAdminTab(),
    const _AdminVolunteersTab(),
    const AdminChatListScreen(),
    const _AdminNotificationsTab(),
    const _AdminSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: _screens[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: theme.brightness == Brightness.dark ? Colors.white38 : Colors.black38,
              backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
              unselectedLabelStyle: const TextStyle(fontSize: 9),
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.dashboard_outlined), activeIcon: const Icon(Icons.dashboard_rounded), label: isAr ? 'الرئيسية' : 'Dashboard'),
                BottomNavigationBarItem(icon: const Icon(Icons.newspaper_outlined), activeIcon: const Icon(Icons.newspaper_rounded), label: isAr ? 'الأخبار' : 'News'),
                BottomNavigationBarItem(icon: const Icon(Icons.school_outlined), activeIcon: const Icon(Icons.school_rounded), label: isAr ? 'الكورسات' : 'Courses'),
                BottomNavigationBarItem(icon: const Icon(Icons.task_outlined), activeIcon: const Icon(Icons.task_rounded), label: isAr ? 'المهام' : 'Tasks'),
                BottomNavigationBarItem(icon: const Icon(Icons.campaign_outlined), activeIcon: const Icon(Icons.campaign_rounded), label: isAr ? 'الحملات' : 'Campaigns'),
                BottomNavigationBarItem(icon: const Icon(Icons.people_outline), activeIcon: const Icon(Icons.people_rounded), label: isAr ? 'المتطوعون' : 'Volunteers'),
                BottomNavigationBarItem(icon: const Icon(Icons.chat_outlined), activeIcon: const Icon(Icons.chat_rounded), label: isAr ? 'المحادثات' : 'Chat'),
                BottomNavigationBarItem(icon: const Icon(Icons.notifications_outlined), activeIcon: const Icon(Icons.notifications_rounded), label: isAr ? 'الإشعارات' : 'Notify'),
                BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined), activeIcon: const Icon(Icons.settings_rounded), label: isAr ? 'الإعدادات' : 'Settings'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── DASHBOARD ───
class _AdminHomeTab extends StatelessWidget {
  const _AdminHomeTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final isAr = localeNotifier.value.languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryBlue, primaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(height: 56, width: 56, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isAr ? 'لوحة التحكم' : 'Admin Dashboard', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ])),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(isAr ? 'إحصائيات سريعة' : 'Quick Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _statCard(isAr ? 'المتطوعون' : 'Volunteers', Icons.people_rounded, primaryBlue, 'users', context)),
                const SizedBox(width: 12),
                Expanded(child: _statCard(isAr ? 'الأخبار' : 'News', Icons.newspaper_rounded, primaryGreen, 'news', context)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _statCard(isAr ? 'الكورسات' : 'Courses', Icons.school_rounded, primaryBlue, 'courses', context)),
                const SizedBox(width: 12),
                Expanded(child: _statCard(isAr ? 'المهام' : 'Tasks', Icons.task_rounded, primaryGreen, 'tasks', context)),
              ]),
              const SizedBox(height: 24),
              _TotalHoursCard(primaryBlue: primaryBlue, primaryGreen: primaryGreen, isDark: isDark, isAr: isAr),
              const SizedBox(height: 24),
              Text(isAr ? 'أفضل المتطوعين' : 'Top Volunteers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
              const SizedBox(height: 12),
              _VolunteerLeaderboard(primaryBlue: primaryBlue, primaryGreen: primaryGreen, isDark: isDark, isAr: isAr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, IconData icon, Color color, String collection, BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 13, color: theme.brightness == Brightness.dark ? Colors.white54 : Colors.black54)),
          ]),
        );
      },
    );
  }
}

class _TotalHoursCard extends StatelessWidget {
  final Color primaryBlue, primaryGreen;
  final bool isDark, isAr;
  const _TotalHoursCard({required this.primaryBlue, required this.primaryGreen, required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
      builder: (context, snap) {
        double totalHours = 0;
        int doneTasks = 0, pendingTasks = 0;
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final hours = (d['hours'] as num? ?? 0).toDouble();
            if (d['status'] == 'done') { totalHours += hours; doneTasks++; } else { pendingTasks++; }
          }
        }
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.timer_rounded, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(isAr ? 'نظرة عامة على ساعات التطوع' : 'Volunteer Hours Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : primaryBlue)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _mini('${totalHours.toStringAsFixed(0)}h', isAr ? 'إجمالي الساعات' : 'Total Hours', primaryBlue, isDark)),
              Expanded(child: _mini('$doneTasks', isAr ? 'مهام منجزة' : 'Done Tasks', primaryGreen, isDark)),
              Expanded(child: _mini('$pendingTasks', isAr ? 'قيد التنفيذ' : 'Pending', Colors.orange, isDark)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _mini(String value, String label, Color color, bool isDark) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
    ]);
  }
}

class _VolunteerLeaderboard extends StatelessWidget {
  final Color primaryBlue, primaryGreen;
  final bool isDark, isAr;
  const _VolunteerLeaderboard({required this.primaryBlue, required this.primaryGreen, required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final volunteers = snap.data!;
        if (volunteers.isEmpty) return Center(child: Text(isAr ? 'لا يوجد متطوعون بعد' : 'No volunteers yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
        return Column(
          children: volunteers.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}';
            final medalColor = i == 0 ? Colors.amber : i == 1 ? Colors.grey : i == 2 ? Colors.brown.shade300 : (isDark ? Colors.white38 : Colors.black38);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: i == 0 ? primaryBlue.withOpacity(0.06) : theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: i == 0 ? Border.all(color: primaryBlue.withOpacity(0.2)) : null,
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: medalColor.withOpacity(0.15), shape: BoxShape.circle), child: Center(child: Text(medal, style: TextStyle(fontSize: i < 3 ? 18 : 13, fontWeight: FontWeight.bold, color: medalColor)))),
                const SizedBox(width: 12),
                CircleAvatar(radius: 18, backgroundColor: primaryBlue.withOpacity(0.15), child: Text((v['name'] ?? 'V')[0].toUpperCase(), style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF101828))),
                  Text(v['phone'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${(v['totalHours'] as double).toStringAsFixed(0)}h', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryBlue)),
                  Text('${v['completedTasks']} ${isAr ? "مهام" : "tasks"}', style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.w600)),
                ]),
              ]),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    final tasksSnap = await FirebaseFirestore.instance.collection('tasks').get();
    final List<Map<String, dynamic>> result = [];
    for (final userDoc in usersSnap.docs) {
      final uid = userDoc.id;
      final userData = userDoc.data();
      double totalHours = 0;
      int completedTasks = 0;
      for (final taskDoc in tasksSnap.docs) {
        final taskData = taskDoc.data();
        final assignedTo = (taskData['assignedTo'] as List?) ?? [];
        if (assignedTo.contains(uid) && taskData['status'] == 'done') {
          totalHours += (taskData['hours'] as num? ?? 0).toDouble();
          completedTasks++;
        }
      }
      result.add({'uid': uid, 'name': userData['name'] ?? 'Unknown', 'phone': userData['phone'] ?? '', 'totalHours': totalHours, 'completedTasks': completedTasks});
    }
    result.sort((a, b) => (b['totalHours'] as double).compareTo(a['totalHours'] as double));
    return result;
  }
}

// ─── NEWS TAB ───
class _AdminNewsTab extends StatefulWidget {
  const _AdminNewsTab();
  @override
  State<_AdminNewsTab> createState() => _AdminNewsTabState();
}

class _AdminNewsTabState extends State<_AdminNewsTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final isAr = localeNotifier.value.languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: () => showDialog(context: context, builder: (_) => _AddNewsDialog(isAr: isAr)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(18), child: Text(isAr ? 'إدارة الأخبار' : 'News Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue))),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('news').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) return Center(child: Text(isAr ? 'لا توجد أخبار بعد' : 'No news yet.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)));
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final hasImage = d['imageBase64'] != null && (d['imageBase64'] as String).isNotEmpty;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (hasImage) ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.memory(base64Decode(d['imageBase64']), width: double.infinity, height: 160, fit: BoxFit.cover)),
                    Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(d['category'] ?? '', style: TextStyle(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600))),
                        const SizedBox(height: 6),
                        Text(d['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF101828))),
                        const SizedBox(height: 4),
                        Text(d['body'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54)),
                      ])),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: () => FirebaseFirestore.instance.collection('news').doc(docs[i].id).delete()),
                    ])),
                  ]),
                );
              },
            );
          },
        )),
      ])),
    );
  }
}

class _AddNewsDialog extends StatefulWidget {
  final bool isAr;
  const _AddNewsDialog({this.isAr = false});
  @override
  State<_AddNewsDialog> createState() => _AddNewsDialogState();
}

class _AddNewsDialogState extends State<_AddNewsDialog> {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  String category = 'Drug Alert';
  String? _base64Image;
  bool _saving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 600, imageQuality: 75);
    if (picked == null) return;
    final bytes = await File(picked.path).readAsBytes();
    setState(() => _base64Image = base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final isAr = widget.isAr;

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(isAr ? 'إضافة خبر' : 'Add News', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 140, width: double.infinity,
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: primaryBlue.withOpacity(0.2))),
            child: _base64Image != null
                ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(base64Decode(_base64Image!), fit: BoxFit.cover, width: double.infinity))
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_rounded, color: primaryBlue, size: 36), const SizedBox(height: 8), Text(isAr ? 'أضف صورة (اختياري)' : 'Tap to add image (optional)', style: TextStyle(color: primaryBlue, fontSize: 13))]),
          ),
        ),
        if (_base64Image != null) ...[
          const SizedBox(height: 6),
          TextButton.icon(onPressed: () => setState(() => _base64Image = null), icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16), label: Text(isAr ? 'إزالة الصورة' : 'Remove image', style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: category,
          dropdownColor: theme.cardColor,
          decoration: InputDecoration(labelText: isAr ? 'التصنيف' : 'Category', labelStyle: TextStyle(color: primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: ['Drug Alert', 'Volunteer Achievement', 'Campaign Update', 'Announcement'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => category = v!),
        ),
        const SizedBox(height: 12),
        TextField(controller: titleCtrl, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: isAr ? 'العنوان' : 'Title', labelStyle: TextStyle(color: primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 12),
        TextField(controller: bodyCtrl, maxLines: 4, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: isAr ? 'المحتوى' : 'Content', labelStyle: TextStyle(color: primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _saving ? null : () async {
            if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
            setState(() => _saving = true);
            await FirebaseFirestore.instance.collection('news').add({'title': titleCtrl.text.trim(), 'body': bodyCtrl.text.trim(), 'category': category, 'imageBase64': _base64Image ?? '', 'createdAt': FieldValue.serverTimestamp(), 'author': FirebaseAuth.instance.currentUser?.email ?? ''});
            if (context.mounted) Navigator.pop(context);
          },
          child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isAr ? 'إضافة' : 'Add'),
        ),
      ],
    );
  }
}

// ─── COURSES TAB ───
class _AdminCoursesTab extends StatelessWidget {
  const _AdminCoursesTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final isAr = localeNotifier.value.languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AdminCourseEditScreen())),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(isAr ? 'كورس جديد' : 'New Course', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 8), child: Text(isAr ? 'إدارة الكورسات' : 'Courses Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue))),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('courses').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.school_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12), const SizedBox(height: 12), Text(isAr ? 'لا توجد كورسات بعد' : 'No courses yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16))]));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final colorHex = d['colorHex'] as String? ?? '#0B2C6B';
                final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                final assignedTo = (d['assignedTo'] as List?)?.length ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3))]),
                  child: Column(children: [
                    Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(18)))),
                    Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                      Container(height: 48, width: 48, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.school_rounded, color: color, size: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF101828))),
                        const SizedBox(height: 3),
                        Text('${d['instructor'] ?? ''} · ${d['duration'] ?? ''}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                        Row(children: [
                          Icon(Icons.people_rounded, size: 12, color: color),
                          const SizedBox(width: 4),
                          Text('$assignedTo ${isAr ? "متطوع" : "volunteers"}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                        ]),
                      ])),
                      Column(children: [
                        IconButton(icon: Icon(Icons.edit_rounded, color: primaryBlue, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AdminCourseEditScreen(courseId: docs[i].id, courseData: d)))),
                        IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => _confirmDelete(context, docs[i].id, isAr)),
                      ]),
                    ])),
                  ]),
                );
              },
            );
          },
        )),
      ])),
    );
  }

  void _confirmDelete(BuildContext context, String courseId, bool isAr) {
  showDialog(context: context, builder: (_) => AlertDialog(
    title: Text(isAr ? 'حذف الكورس؟' : 'Delete Course?'),
    content: Text(isAr ? 'سيتم حذف الكورس نهائياً.' : 'This will permanently delete the course.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Cancel')),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
        onPressed: () async {
          Navigator.pop(context);
          // احذف الـ subcollections الأول
          final sessSnap = await FirebaseFirestore.instance
              .collection('courses').doc(courseId).collection('sessions').get();
          for (final doc in sessSnap.docs) { await doc.reference.delete(); }

          final checkSnap = await FirebaseFirestore.instance
              .collection('courses').doc(courseId).collection('checklist').get();
          for (final doc in checkSnap.docs) { await doc.reference.delete(); }

          // بعدين احذف الـ course نفسه
          await FirebaseFirestore.instance.collection('courses').doc(courseId).delete();

          // امسح progress اليوزرز للكورس ده
          final progressSnap = await FirebaseFirestore.instance
              .collection('user_progress').get();
          for (final doc in progressSnap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final courses = data['courses'] as Map<String, dynamic>?;
            if (courses != null && courses.containsKey(courseId)) {
              await doc.reference.update({'courses.$courseId': FieldValue.delete()});
            }
          }
        },
        child: Text(isAr ? 'حذف' : 'Delete'),
      ),
    ],
  ));
}
}

// ─── COURSE EDIT SCREEN ───
class _AdminCourseEditScreen extends StatefulWidget {
  final String? courseId;
  final Map<String, dynamic>? courseData;
  const _AdminCourseEditScreen({this.courseId, this.courseData});

  @override
  State<_AdminCourseEditScreen> createState() => _AdminCourseEditScreenState();
}

class _AdminCourseEditScreenState extends State<_AdminCourseEditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final titleCtrl = TextEditingController();
  final instructorCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final creditHoursCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String _colorHex = '#0B2C6B';
  bool _saving = false;
  String? _courseId;
  final List<Map<String, dynamic>> _sessions = [];
  final List<Map<String, dynamic>> _checklist = [];
  List<Map<String, dynamic>> _volunteers = [];
  List<String> _assignedTo = [];

  final List<Map<String, String>> _colorOptions = [
    {'name': 'Navy', 'hex': '#0B2C6B'}, {'name': 'Green', 'hex': '#16A34A'},
    {'name': 'Purple', 'hex': '#7C3AED'}, {'name': 'Orange', 'hex': '#E16A2D'},
    {'name': 'Red', 'hex': '#DC2626'}, {'name': 'Teal', 'hex': '#0D9488'},
  ];

  bool get isAr => localeNotifier.value.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _courseId = widget.courseId;
    if (widget.courseData != null) {
      final d = widget.courseData!;
      titleCtrl.text = d['title'] ?? '';
      instructorCtrl.text = d['instructor'] ?? '';
      durationCtrl.text = d['duration'] ?? '';
      creditHoursCtrl.text = (d['creditHours'] ?? 0).toString();
      descCtrl.text = d['description'] ?? '';
      _colorHex = d['colorHex'] ?? '#0B2C6B';
      _assignedTo = List<String>.from(d['assignedTo'] ?? []);
    }
    _loadSubcollections();
    _loadVolunteers();
  }

  Future<void> _loadSubcollections() async {
    if (_courseId == null) return;
    final sessSnap = await FirebaseFirestore.instance.collection('courses').doc(_courseId).collection('sessions').orderBy('order').get();
    final checkSnap = await FirebaseFirestore.instance.collection('courses').doc(_courseId).collection('checklist').orderBy('order').get();
    setState(() {
      _sessions.clear();
      _sessions.addAll(sessSnap.docs.map((d) => {'id': d.id, ...d.data()}));
      _checklist.clear();
      _checklist.addAll(checkSnap.docs.map((d) => {'id': d.id, ...d.data()}));
    });
  }

  Future<void> _loadVolunteers() async {
    final snap = await FirebaseFirestore.instance.collection('users').get();
    setState(() => _volunteers = snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
  }

  Future<void> _saveCourse() async {
    if (titleCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    final data = {'title': titleCtrl.text.trim(), 'instructor': instructorCtrl.text.trim(), 'duration': durationCtrl.text.trim(), 'creditHours': double.tryParse(creditHoursCtrl.text) ?? 0, 'description': descCtrl.text.trim(), 'colorHex': _colorHex, 'assignedTo': _assignedTo, 'createdAt': FieldValue.serverTimestamp()};
    if (_courseId == null) {
      final ref = await FirebaseFirestore.instance.collection('courses').add(data);
      _courseId = ref.id;
    } else {
      await FirebaseFirestore.instance.collection('courses').doc(_courseId).update(data);
    }
    await _saveSubcollections();
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'تم حفظ الكورس ✅' : 'Course saved ✅'), backgroundColor: Colors.green));
  }

  Future<void> _saveSubcollections() async {
    if (_courseId == null) return;
    final sessRef = FirebaseFirestore.instance.collection('courses').doc(_courseId).collection('sessions');
    final checkRef = FirebaseFirestore.instance.collection('courses').doc(_courseId).collection('checklist');
    for (int i = 0; i < _sessions.length; i++) {
      final s = Map<String, dynamic>.from(_sessions[i]);
      final id = s.remove('id');
      s['order'] = i;
      if (id != null && id.toString().isNotEmpty) { await sessRef.doc(id).set(s); } else { await sessRef.add(s); }
    }
    for (int i = 0; i < _checklist.length; i++) {
      final c = Map<String, dynamic>.from(_checklist[i]);
      final id = c.remove('id');
      c['order'] = i;
      if (id != null && id.toString().isNotEmpty) { await checkRef.doc(id).set(c); } else { await checkRef.add(c); }
    }
  }

  @override
  void dispose() { _tabCtrl.dispose(); titleCtrl.dispose(); instructorCtrl.dispose(); durationCtrl.dispose(); creditHoursCtrl.dispose(); descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final color = Color(int.parse(_colorHex.replaceFirst('#', '0xFF')));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(widget.courseId == null ? (isAr ? 'كورس جديد' : 'New Course') : (isAr ? 'تعديل الكورس' : 'Edit Course'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_saving) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else TextButton.icon(onPressed: _saveCourse, icon: const Icon(Icons.save_rounded, color: Colors.white), label: Text(isAr ? 'حفظ' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [Tab(text: isAr ? 'المعلومات' : 'Info'), Tab(text: isAr ? 'الجلسات' : 'Sessions'), Tab(text: isAr ? 'القائمة' : 'Checklist'), Tab(text: isAr ? 'التعيين' : 'Assign')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _field(titleCtrl, isAr ? 'عنوان الكورس' : 'Course Title', Icons.title_rounded, isDark, primaryBlue),
            const SizedBox(height: 14),
            _field(instructorCtrl, isAr ? 'اسم المحاضر' : 'Instructor Name', Icons.person_rounded, isDark, primaryBlue),
            const SizedBox(height: 14),
            _field(durationCtrl, isAr ? 'المدة (مثال: 3 ساعات)' : 'Duration (e.g. 3 hours)', Icons.timer_rounded, isDark, primaryBlue),
            const SizedBox(height: 14),
            _field(creditHoursCtrl, isAr ? 'الساعات المعتمدة (مثال: 16)' : 'Credit Hours (e.g. 16)', Icons.school_rounded, isDark, primaryBlue, keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            _field(descCtrl, isAr ? 'الوصف' : 'Description', Icons.description_rounded, isDark, primaryBlue, maxLines: 5),
            const SizedBox(height: 20),
            Text(isAr ? 'لون الكورس' : 'Course Color', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, children: _colorOptions.map((c) {
              final hex = c['hex']!;
              final col = Color(int.parse(hex.replaceFirst('#', '0xFF')));
              final selected = _colorHex == hex;
              return GestureDetector(
                onTap: () => setState(() => _colorHex = hex),
                child: AnimatedContainer(duration: const Duration(milliseconds: 200), height: 44, width: 44, decoration: BoxDecoration(color: col, shape: BoxShape.circle, border: selected ? Border.all(color: Colors.white, width: 3) : null, boxShadow: selected ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null), child: selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null),
              );
            }).toList()),
          ])),
          _SessionsEditor(sessions: _sessions, onChanged: (s) => setState(() { _sessions.clear(); _sessions.addAll(s); }), color: color, isDark: isDark),
          _ChecklistEditor(checklist: _checklist, onChanged: (c) => setState(() { _checklist.clear(); _checklist.addAll(c); }), color: color, isDark: isDark),
          _AssignTab(volunteers: _volunteers, assignedTo: _assignedTo, onChanged: (a) => setState(() { _assignedTo.clear(); _assignedTo.addAll(a); }), color: color, isDark: isDark),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, bool isDark, Color color, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(controller: ctrl, maxLines: maxLines, keyboardType: keyboardType, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: color), prefixIcon: Icon(icon, color: color, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: 2))));
  }
}

// ─── SESSIONS EDITOR ───
class _SessionsEditor extends StatefulWidget {
  final List<Map<String, dynamic>> sessions;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final Color color;
  final bool isDark;
  const _SessionsEditor({required this.sessions, required this.onChanged, required this.color, required this.isDark});
  @override
  State<_SessionsEditor> createState() => _SessionsEditorState();
}

class _SessionsEditorState extends State<_SessionsEditor> {
  bool get isAr => localeNotifier.value.languageCode == 'ar';

  void _addSession() => showDialog(context: context, builder: (_) => _SessionDialog(color: widget.color, isDark: widget.isDark, onSave: (s) => widget.onChanged([...widget.sessions, s])));
  void _editSession(int i) => showDialog(context: context, builder: (_) => _SessionDialog(color: widget.color, isDark: widget.isDark, existing: widget.sessions[i], onSave: (s) { final u = [...widget.sessions]; u[i] = s; widget.onChanged(u); }));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Text('${isAr ? "الجلسات" : "Sessions"} (${widget.sessions.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.color)),
        const Spacer(),
        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: widget.color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _addSession, icon: const Icon(Icons.add, size: 18), label: Text(isAr ? 'إضافة جلسة' : 'Add Session')),
      ])),
      Expanded(child: widget.sessions.isEmpty
          ? Center(child: Text(isAr ? 'لا توجد جلسات بعد' : 'No sessions yet', style: TextStyle(color: widget.isDark ? Colors.white38 : Colors.black38)))
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.sessions.length,
              onReorder: (o, n) { if (n > o) n--; final u = [...widget.sessions]; u.insert(n, u.removeAt(o)); widget.onChanged(u); },
              itemBuilder: (context, i) {
                final s = widget.sessions[i];
                final type = s['type'] as String? ?? 'youtube';
                IconData icon;
                switch (type) { case 'video': icon = Icons.videocam_rounded; break; case 'file': icon = Icons.insert_drive_file_rounded; break; case 'image': icon = Icons.image_rounded; break; default: icon = Icons.play_circle_rounded; }
                return Container(key: ValueKey('s$i'), margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)]),
                  child: Row(children: [
                    Container(height: 40, width: 40, decoration: BoxDecoration(color: widget.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: widget.color, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: widget.isDark ? Colors.white : const Color(0xFF101828))),
                      Text('$type · ${s['duration'] ?? ''}', style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white54 : Colors.black45)),
                    ])),
                    IconButton(icon: Icon(Icons.edit_rounded, color: widget.color, size: 18), onPressed: () => _editSession(i)),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18), onPressed: () { final u = [...widget.sessions]..removeAt(i); widget.onChanged(u); }),
                    const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                  ]),
                );
              },
            )),
    ]);
  }
}

class _SessionDialog extends StatefulWidget {
  final Color color;
  final bool isDark;
  final Map<String, dynamic>? existing;
  final ValueChanged<Map<String, dynamic>> onSave;
  const _SessionDialog({required this.color, required this.isDark, this.existing, required this.onSave});
  @override
  State<_SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends State<_SessionDialog> {
  final titleCtrl = TextEditingController();
  final urlCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  String _type = 'youtube';
  bool get isAr => localeNotifier.value.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) { titleCtrl.text = widget.existing!['title'] ?? ''; urlCtrl.text = widget.existing!['url'] ?? ''; durationCtrl.text = widget.existing!['duration'] ?? ''; _type = widget.existing!['type'] ?? 'youtube'; }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.existing == null ? (isAr ? 'إضافة جلسة' : 'Add Session') : (isAr ? 'تعديل الجلسة' : 'Edit Session'), style: TextStyle(color: widget.color, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: isAr ? 'عنوان الجلسة' : 'Session Title', labelStyle: TextStyle(color: widget.color), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _type,
          dropdownColor: theme.cardColor,
          decoration: InputDecoration(labelText: isAr ? 'نوع المحتوى' : 'Content Type', labelStyle: TextStyle(color: widget.color), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: [
            DropdownMenuItem(value: 'youtube', child: Row(children: [const Icon(Icons.play_circle_rounded, color: Colors.red, size: 18), const SizedBox(width: 8), Text(isAr ? 'فيديو يوتيوب' : 'YouTube Video')])),
            DropdownMenuItem(value: 'video', child: Row(children: [const Icon(Icons.videocam_rounded, color: Colors.blue, size: 18), const SizedBox(width: 8), Text(isAr ? 'رابط فيديو' : 'Direct Video Link')])),
            DropdownMenuItem(value: 'file', child: Row(children: [const Icon(Icons.insert_drive_file_rounded, color: Colors.orange, size: 18), const SizedBox(width: 8), Text(isAr ? 'ملف (PDF)' : 'File (PDF/Doc)')])),
            DropdownMenuItem(value: 'image', child: Row(children: [const Icon(Icons.image_rounded, color: Colors.green, size: 18), const SizedBox(width: 8), Text(isAr ? 'صورة' : 'Image')])),
          ],
          onChanged: (v) => setState(() => _type = v!),
        ),
        const SizedBox(height: 12),
        TextField(controller: urlCtrl, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: 'URL', labelStyle: TextStyle(color: widget.color), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 12),
        TextField(controller: durationCtrl, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: isAr ? 'المدة (مثال: 45 دقيقة)' : 'Duration (e.g. 45 min)', labelStyle: TextStyle(color: widget.color), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: widget.color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () {
          if (titleCtrl.text.isEmpty) return;
          final session = {if (widget.existing != null && widget.existing!['id'] != null) 'id': widget.existing!['id'], 'title': titleCtrl.text.trim(), 'type': _type, 'url': urlCtrl.text.trim(), 'duration': durationCtrl.text.trim()};
          widget.onSave(session);
          Navigator.pop(context);
        }, child: Text(isAr ? 'حفظ' : 'Save')),
      ],
    );
  }
}

// ─── CHECKLIST EDITOR ───
class _ChecklistEditor extends StatefulWidget {
  final List<Map<String, dynamic>> checklist;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final Color color;
  final bool isDark;
  const _ChecklistEditor({required this.checklist, required this.onChanged, required this.color, required this.isDark});
  @override
  State<_ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends State<_ChecklistEditor> {
  bool get isAr => localeNotifier.value.languageCode == 'ar';

  void _addItem() {
    final ctrl = TextEditingController();
    final theme = Theme.of(context);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(isAr ? 'إضافة مهمة' : 'Add Checklist Item', style: TextStyle(color: widget.color, fontWeight: FontWeight.bold)),
      content: TextField(controller: ctrl, autofocus: true, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: isAr ? 'المهمة' : 'Task', labelStyle: TextStyle(color: widget.color), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: widget.color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { if (ctrl.text.isEmpty) return; widget.onChanged([...widget.checklist, {'task': ctrl.text.trim()}]); Navigator.pop(context); }, child: Text(isAr ? 'إضافة' : 'Add')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Text('${isAr ? "القائمة" : "Checklist"} (${widget.checklist.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.color)),
        const Spacer(),
        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: widget.color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _addItem, icon: const Icon(Icons.add, size: 18), label: Text(isAr ? 'إضافة' : 'Add Item')),
      ])),
      Expanded(child: widget.checklist.isEmpty
          ? Center(child: Text(isAr ? 'لا توجد مهام بعد' : 'No checklist items yet', style: TextStyle(color: widget.isDark ? Colors.white38 : Colors.black38)))
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.checklist.length,
              onReorder: (o, n) { if (n > o) n--; final u = [...widget.checklist]; u.insert(n, u.removeAt(o)); widget.onChanged(u); },
              itemBuilder: (context, i) {
                final item = widget.checklist[i];
                return Container(key: ValueKey('c$i'), margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)]),
                  child: Row(children: [
                    Container(height: 10, width: 10, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item['task'] ?? '', style: TextStyle(fontSize: 14, color: widget.isDark ? Colors.white : const Color(0xFF101828)))),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18), onPressed: () { final u = [...widget.checklist]..removeAt(i); widget.onChanged(u); }),
                    const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                  ]),
                );
              },
            )),
    ]);
  }
}

// ─── ASSIGN TAB ───
class _AssignTab extends StatelessWidget {
  final List<Map<String, dynamic>> volunteers;
  final List<String> assignedTo;
  final ValueChanged<List<String>> onChanged;
  final Color color;
  final bool isDark;
  const _AssignTab({required this.volunteers, required this.assignedTo, required this.onChanged, required this.color, required this.isDark});

  bool get isAr => localeNotifier.value.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Text(isAr ? 'تعيين المتطوعين' : 'Assign Volunteers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text('${assignedTo.length} ${isAr ? "معيّن" : "assigned"}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
      ])),
      Expanded(child: volunteers.isEmpty
          ? Center(child: Text(isAr ? 'لا يوجد متطوعون' : 'No volunteers found', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: volunteers.length,
              itemBuilder: (context, i) {
                final v = volunteers[i];
                final uid = v['uid'] as String;
                final isAssigned = assignedTo.contains(uid);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: isAssigned ? color.withOpacity(0.08) : theme.cardColor, borderRadius: BorderRadius.circular(14), border: isAssigned ? Border.all(color: color.withOpacity(0.3)) : null),
                  child: CheckboxListTile(value: isAssigned, activeColor: color, onChanged: (val) { final u = [...assignedTo]; if (val == true) { u.add(uid); } else { u.remove(uid); } onChanged(u); }, title: Text(v['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF101828))), subtitle: Text(v['phone'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)), secondary: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Text((v['name'] ?? 'V')[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold))), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                );
              },
            )),
    ]);
  }
}

// ─── TASKS TAB ───
class _AdminTasksTab extends StatelessWidget {
  const _AdminTasksTab();

  bool get isAr => localeNotifier.value.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AdminTaskEditScreen())),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(isAr ? 'مهمة جديدة' : 'New Task', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 8), child: Text(isAr ? 'إدارة المهام' : 'Tasks Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue))),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.task_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12), const SizedBox(height: 12), Text(isAr ? 'لا توجد مهام بعد' : 'No tasks yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16))]));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final isDone = d['status'] == 'done';
                final isPendingApproval = d['status'] == 'pending_approval';
                final assigned = (d['assignedTo'] as List?)?.length ?? 0;
                final hours = (d['hours'] as num? ?? 0).toDouble();
                String dateStr = '';
                final dueDate = d['dueDate'];
                if (dueDate is Timestamp) { final dt = dueDate.toDate(); dateStr = '${dt.day}/${dt.month}/${dt.year}'; }
                Color statusColor = Colors.orange;
                String statusLabel = isAr ? 'قيد التنفيذ' : 'Pending';
                if (isDone) { statusColor = Colors.green; statusLabel = isAr ? 'مكتمل' : 'Done'; }
                else if (isPendingApproval) { statusColor = Colors.blue; statusLabel = isAr ? 'بانتظار الموافقة' : 'Awaiting Approval'; }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(18), border: isPendingApproval ? Border.all(color: Colors.blue.withOpacity(0.4), width: 1.5) : isDone ? Border.all(color: Colors.green.withOpacity(0.3)) : null, boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3))]),
                  child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
                    Row(children: [
                      Container(height: 48, width: 48, decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.task_rounded, color: statusColor, size: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: isDark ? Colors.white : const Color(0xFF101828))),
                        if (dateStr.isNotEmpty) Text('📅 $dateStr · ⏱ ${hours.toStringAsFixed(0)}h', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                        Row(children: [
                          Icon(Icons.people_rounded, size: 12, color: primaryBlue),
                          const SizedBox(width: 4),
                          Text('$assigned ${isAr ? "معيّن" : "assigned"}', style: TextStyle(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor))),
                        ]),
                      ])),
                      Column(children: [
                        IconButton(icon: Icon(Icons.edit_rounded, color: primaryBlue, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AdminTaskEditScreen(taskId: docs[i].id, taskData: d)))),
                        IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => FirebaseFirestore.instance.collection('tasks').doc(docs[i].id).delete()),
                      ]),
                    ]),
                    if (isPendingApproval) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => FirebaseFirestore.instance.collection('tasks').doc(docs[i].id).update({'status': 'done', 'approvedAt': FieldValue.serverTimestamp()}), icon: const Icon(Icons.check_rounded, size: 16), label: Text(isAr ? 'موافقة' : 'Approve', style: const TextStyle(fontWeight: FontWeight.bold)))),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => FirebaseFirestore.instance.collection('tasks').doc(docs[i].id).update({'status': 'pending'}), icon: const Icon(Icons.close_rounded, size: 16), label: Text(isAr ? 'رفض' : 'Reject'))),
                      ]),
                    ],
                  ])),
                );
              },
            );
          },
        )),
      ])),
    );
  }
}

class _AdminTaskEditScreen extends StatefulWidget {
  final String? taskId;
  final Map<String, dynamic>? taskData;
  const _AdminTaskEditScreen({this.taskId, this.taskData});
  @override
  State<_AdminTaskEditScreen> createState() => _AdminTaskEditScreenState();
}

class _AdminTaskEditScreenState extends State<_AdminTaskEditScreen> {
  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final hoursCtrl = TextEditingController();
  String _type = 'campaign';
  DateTime? _dueDate;
  List<Map<String, dynamic>> _volunteers = [];
  List<String> _assignedTo = [];
  bool _saving = false;
  bool get isAr => localeNotifier.value.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    if (widget.taskData != null) {
      final d = widget.taskData!;
      titleCtrl.text = d['title'] ?? '';
      locationCtrl.text = d['location'] ?? '';
      descCtrl.text = d['description'] ?? '';
      hoursCtrl.text = (d['hours'] ?? 0).toString();
      _type = d['type'] ?? 'campaign';
      _assignedTo = List<String>.from(d['assignedTo'] ?? []);
      final dueDate = d['dueDate'];
      if (dueDate is Timestamp) _dueDate = dueDate.toDate();
    }
    _loadVolunteers();
  }

  Future<void> _loadVolunteers() async {
    final snap = await FirebaseFirestore.instance.collection('users').get();
    setState(() => _volunteers = snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _dueDate ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (titleCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    final data = {'title': titleCtrl.text.trim(), 'location': locationCtrl.text.trim(), 'description': descCtrl.text.trim(), 'hours': double.tryParse(hoursCtrl.text) ?? 0, 'type': _type, 'assignedTo': _assignedTo, 'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null, 'status': widget.taskData?['status'] ?? 'pending', 'createdAt': FieldValue.serverTimestamp()};
    if (widget.taskId == null) { await FirebaseFirestore.instance.collection('tasks').add(data); } else { await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update(data); }
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() { titleCtrl.dispose(); locationCtrl.dispose(); descCtrl.dispose(); hoursCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue, foregroundColor: Colors.white,
        title: Text(widget.taskId == null ? (isAr ? 'مهمة جديدة' : 'New Task') : (isAr ? 'تعديل المهمة' : 'Edit Task'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_saving) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else TextButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded, color: Colors.white), label: Text(isAr ? 'حفظ' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _field(titleCtrl, isAr ? 'عنوان المهمة' : 'Task Title', Icons.title_rounded, isDark, primaryBlue),
        const SizedBox(height: 14),
        _field(locationCtrl, isAr ? 'الموقع' : 'Location', Icons.location_on_rounded, isDark, primaryBlue),
        const SizedBox(height: 14),
        _field(descCtrl, isAr ? 'الوصف' : 'Description', Icons.description_rounded, isDark, primaryBlue, maxLines: 3),
        const SizedBox(height: 14),
        _field(hoursCtrl, isAr ? 'ساعات التطوع' : 'Volunteer Hours', Icons.timer_rounded, isDark, primaryBlue, keyboardType: TextInputType.number),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _type, dropdownColor: theme.cardColor,
          decoration: InputDecoration(labelText: isAr ? 'نوع المهمة' : 'Task Type', labelStyle: TextStyle(color: primaryBlue), prefixIcon: Icon(Icons.category_rounded, color: primaryBlue, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryBlue, width: 2))),
          items: [
            DropdownMenuItem(value: 'campaign', child: Text(isAr ? 'حملة' : 'Campaign')),
            DropdownMenuItem(value: 'school', child: Text(isAr ? 'زيارة مدرسة' : 'School Visit')),
            DropdownMenuItem(value: 'event', child: Text(isAr ? 'فعالية مجتمعية' : 'Community Event')),
            DropdownMenuItem(value: 'report', child: Text(isAr ? 'تقرير' : 'Report')),
            DropdownMenuItem(value: 'visit', child: Text(isAr ? 'زيارة ميدانية' : 'Field Visit')),
            DropdownMenuItem(value: 'other', child: Text(isAr ? 'أخرى' : 'Other')),
          ],
          onChanged: (v) => setState(() => _type = v!),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _pickDate,
          child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.white38 : Colors.black26), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [Icon(Icons.calendar_today_rounded, color: primaryBlue, size: 20), const SizedBox(width: 12), Text(_dueDate == null ? (isAr ? 'اختر تاريخ الاستحقاق' : 'Select Due Date') : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}', style: TextStyle(color: _dueDate == null ? (isDark ? Colors.white38 : Colors.black38) : (isDark ? Colors.white : Colors.black87)))]),
          ),
        ),
        const SizedBox(height: 24),
        Text(isAr ? 'تعيين المتطوعين' : 'Assign to Volunteers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue)),
        const SizedBox(height: 10),
        if (_volunteers.isEmpty) Text(isAr ? 'لا يوجد متطوعون' : 'No volunteers found', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38))
        else ..._volunteers.map((v) {
          final uid = v['uid'] as String;
          final isAssigned = _assignedTo.contains(uid);
          return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: isAssigned ? primaryBlue.withOpacity(0.08) : theme.cardColor, borderRadius: BorderRadius.circular(14), border: isAssigned ? Border.all(color: primaryBlue.withOpacity(0.3)) : null),
            child: CheckboxListTile(value: isAssigned, activeColor: primaryBlue, onChanged: (val) { setState(() { if (val == true) { _assignedTo.add(uid); } else { _assignedTo.remove(uid); } }); }, title: Text(v['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF101828))), subtitle: Text(v['phone'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)), secondary: CircleAvatar(backgroundColor: primaryBlue.withOpacity(0.15), child: Text((v['name'] ?? 'V')[0].toUpperCase(), style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          );
        }),
        const SizedBox(height: 30),
      ])),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, bool isDark, Color color, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(controller: ctrl, maxLines: maxLines, keyboardType: keyboardType, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: color), prefixIcon: Icon(icon, color: color, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: 2))));
  }
}

// ─── CAMPAIGNS TAB (Admin) ───
class _AdminCampaignsAdminTab extends StatelessWidget {
  const _AdminCampaignsAdminTab();

  bool get isAr => localeNotifier.value.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return AdminCampaignsTab();
  }
}

// ─── VOLUNTEERS TAB ───
class _AdminVolunteersTab extends StatelessWidget {
  const _AdminVolunteersTab();

  bool get isAr => localeNotifier.value.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(18), child: Text(isAr ? 'المتطوعون' : 'Volunteers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue))),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) return Center(child: Text(isAr ? 'لا يوجد متطوعون بعد' : 'No volunteers yet.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)));
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final uid = docs[i].id;
                final name = d['name'] ?? 'Unknown';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8)]),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: primaryBlue.withOpacity(0.15), child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'V', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF101828))),
                      Text(d['phone'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                    ])),
                    // Chat button
                    IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(targetUid: uid, targetName: name))),
                      icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.chat_rounded, color: primaryBlue, size: 18)),
                    ),
                    // Notification button
                    IconButton(
                      onPressed: () => showDialog(context: context, builder: (_) => SendNotificationDialog(targetUid: uid, targetName: name)),
                      icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.notifications_rounded, color: primaryGreen, size: 18)),
                    ),
                  ]),
                );
              },
            );
          },
        )),
      ])),
    );
  }
}

// ─── NOTIFICATIONS TAB ───
class _AdminNotificationsTab extends StatelessWidget {
  const _AdminNotificationsTab();

  bool get isAr => localeNotifier.value.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        onPressed: () => showDialog(context: context, builder: (_) => const SendNotificationDialog()),
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: Text(isAr ? 'إرسال للجميع' : 'Send to All', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(18), child: Text(isAr ? 'الإشعارات المرسلة' : 'Sent Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue))),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('notifications').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_none_rounded, size: 64, color: isDark ? Colors.white24 : Colors.black12), const SizedBox(height: 12), Text(isAr ? 'لا توجد إشعارات مرسلة بعد' : 'No notifications sent yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16))]));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final isAll = d['targetUid'] == 'all';
                final ts = d['createdAt'] as Timestamp?;
                String timeStr = '';
                if (ts != null) { final dt = ts.toDate(); timeStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'; }
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)]),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(height: 42, width: 42, decoration: BoxDecoration(color: (isAll ? primaryGreen : primaryBlue).withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(isAll ? Icons.group_rounded : Icons.person_rounded, color: isAll ? primaryGreen : primaryBlue, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: (isAll ? primaryGreen : primaryBlue).withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(isAll ? (isAr ? 'للجميع' : 'All Volunteers') : (isAr ? 'فردي' : 'Individual'), style: TextStyle(fontSize: 10, color: isAll ? primaryGreen : primaryBlue, fontWeight: FontWeight.bold))),
                      ]),
                      const SizedBox(height: 4),
                      Text(d['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF101828))),
                      const SizedBox(height: 2),
                      Text(d['body'] ?? '', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54)),
                      const SizedBox(height: 4),
                      Text(timeStr, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
                    ])),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18), onPressed: () => FirebaseFirestore.instance.collection('notifications').doc(docs[i].id).delete()),
                  ]),
                );
              },
            );
          },
        )),
      ])),
    );
  }
}

// ─── SETTINGS TAB ───
class _AdminSettingsTab extends StatelessWidget {
  const _AdminSettingsTab();

  bool get isAr => localeNotifier.value.languageCode == 'ar';

  void _showAddAdminDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(isAr ? 'إضافة مدير جديد' : 'Add New Admin', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: isAr ? 'الاسم' : 'Name', labelStyle: TextStyle(color: primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 12),
        TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: isAr ? 'البريد الإلكتروني' : 'Email', labelStyle: TextStyle(color: primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async {
          if (emailCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
          await FirebaseFirestore.instance.collection('admins').doc(emailCtrl.text.trim()).set({'email': emailCtrl.text.trim(), 'name': nameCtrl.text.trim(), 'canAddAdmins': false, 'createdAt': FieldValue.serverTimestamp()});
          if (context.mounted) Navigator.pop(context);
        }, child: Text(isAr ? 'إضافة' : 'Add')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isAr ? 'إعدادات الإدارة' : 'Admin Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue)),
        const SizedBox(height: 20),
        // Language
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(Icons.language_rounded, color: primaryBlue),
            const SizedBox(width: 12),
            Text(isAr ? 'اللغة' : 'Language', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            const Spacer(),
            ValueListenableBuilder<Locale>(
              valueListenable: localeNotifier,
              builder: (_, locale, __) => SegmentedButton<String>(
                segments: [ButtonSegment(value: 'en', label: Text('EN')), ButtonSegment(value: 'ar', label: Text('ع'))],
                selected: {locale.languageCode},
                onSelectionChanged: (v) => localeNotifier.value = Locale(v.first),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // Dark mode
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(Icons.dark_mode_rounded, color: primaryBlue),
            const SizedBox(width: 12),
            Text(isAr ? 'الوضع الداكن' : 'Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            const Spacer(),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) => Switch(value: mode == ThemeMode.dark, activeColor: primaryBlue, onChanged: (v) => themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(isAr ? 'المديرون' : 'Admins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('admins').snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            return Column(children: [
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Icon(Icons.admin_panel_settings_rounded, color: primaryBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                      Text(d['email'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                    ])),
                  ]),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: () => _showAddAdminDialog(context), icon: const Icon(Icons.person_add_rounded), label: Text(isAr ? 'إضافة مدير جديد' : 'Add New Admin', style: const TextStyle(fontWeight: FontWeight.bold)))),
            ]);
          },
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout_rounded), label: Text(isAr ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(fontWeight: FontWeight.bold)))),
      ]))),
    );
  }
}