import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'contact_screen.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _photoBase64;
  String _phone = '';
  String _address = '';
  String _name = '';
  double _creditHours = 0;
  int _tasksCompleted = 0;
  int _coursesCompleted = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStats();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get().timeout(const Duration(seconds: 5));
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _photoBase64 = data['photoBase64'];
          _phone = data['phone'] ?? '';
          _address = data['address'] ?? '';
          _name = data['name'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      final coursesSnap = await FirebaseFirestore.instance.collection('courses').where('assignedTo', arrayContains: uid).get();
      final progressDoc = await FirebaseFirestore.instance.collection('user_progress').doc(uid).get();
      final progressData = (progressDoc.data() as Map<String, dynamic>?) ?? {};
      final coursesProgress = (progressData['courses'] as Map<String, dynamic>?) ?? {};

      double totalHours = 0;
      int completedCourses = 0;

      for (final courseDoc in coursesSnap.docs) {
        final courseData = courseDoc.data();
        final creditHours = (courseData['creditHours'] as num? ?? 0).toDouble();
        final courseProgress = coursesProgress[courseDoc.id];
        final checklistDone = (courseProgress?['checklistDone'] as List?)?.length ?? 0;
        final checkSnap = await FirebaseFirestore.instance.collection('courses').doc(courseDoc.id).collection('checklist').get();
        final totalChecklist = checkSnap.docs.length;
        if (totalChecklist > 0 && checklistDone >= totalChecklist) {
          totalHours += creditHours;
          completedCourses++;
        }
      }

      final tasksSnap = await FirebaseFirestore.instance.collection('tasks').where('assignedTo', arrayContains: uid).where('status', isEqualTo: 'done').get();

      if (mounted) {
        setState(() {
          _creditHours = totalHours;
          _tasksCompleted = tasksSnap.docs.length;
          _coursesCompleted = completedCourses;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final card = theme.cardColor;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final email = user?.email ?? '';
    final displayName = _name.isNotEmpty ? _name : (user?.displayName?.isNotEmpty == true ? user!.displayName! : email.split('@')[0]);

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(isAr ? 'متطوع نشط' : 'Active Volunteer', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                            const Spacer(),
                            // Notification bell with badge
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('notifications')
                                  .where('targetUid', whereIn: [uid, 'all'])
                                  .where('read', isEqualTo: false)
                                  .snapshots(),
                              builder: (context, snap) {
                                final count = snap.data?.docs.length ?? 0;
                                return GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(left: 8, right: 8),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                    child: Stack(clipBehavior: Clip.none, children: [
                                      const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
                                      if (count > 0)
                                        Positioned(
                                          top: -6, right: -6,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                            child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                    ]),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              onPressed: () async {
                                final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                                if (updated == true && mounted) { _loadProfile(); setState(() {}); }
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3), width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))]),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: _photoBase64 != null ? MemoryImage(base64Decode(_photoBase64!)) : null,
                            child: _photoBase64 == null ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)) : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3)),
                        const SizedBox(height: 4),
                        Text(email, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                        if (_phone.isNotEmpty || _address.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          if (_phone.isNotEmpty)
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.phone_rounded, size: 14, color: Colors.white.withOpacity(0.7)),
                              const SizedBox(width: 5),
                              Text(_phone, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                            ]),
                          if (_address.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.location_on_rounded, size: 14, color: Colors.white.withOpacity(0.7)),
                              const SizedBox(width: 5),
                              Text(_address, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                            ]),
                          ],
                        ],
                        const SizedBox(height: 24),
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.15))),
                          child: _statsLoading
                              ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                              : Row(children: [
                                  _headerStat('${_creditHours.toStringAsFixed(0)}', isAr ? 'ساعات معتمدة' : 'Credit Hours', Icons.school_rounded),
                                  _vDivider(),
                                  _headerStat('$_tasksCompleted', isAr ? 'مهام منجزة' : 'Tasks Done', Icons.task_alt_rounded),
                                  _vDivider(),
                                  _headerStat('$_coursesCompleted', isAr ? 'كورسات' : 'Courses', Icons.verified_rounded),
                                ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Volunteer ID
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))]),
                        child: Row(children: [
                          Container(height: 52, width: 52, decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen]), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.badge_rounded, color: Colors.white, size: 26)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(isAr ? 'رقم المتطوع' : 'Volunteer ID', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 3),
                            Text(user?.uid.substring(0, 12).toUpperCase() ?? '—', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryBlue, letterSpacing: 1.5)),
                            const SizedBox(height: 3),
                            Text(isAr ? 'صندوق مكافحة الإدمان' : 'Drug Addiction Control Fund', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: primaryGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text(isAr ? 'نشط' : 'Active', style: TextStyle(fontSize: 12, color: primaryGreen, fontWeight: FontWeight.bold)),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(Icons.trending_up_rounded, color: primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            Text(isAr ? 'تقدم التطوع' : 'Volunteer Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF101828))),
                          ]),
                          const SizedBox(height: 16),
                          _progressRow(isAr ? 'الساعات المعتمدة' : 'Credit Hours', _creditHours, 100, primaryBlue, isDark),
                          const SizedBox(height: 12),
                          _progressRow(isAr ? 'المهام المنجزة' : 'Tasks Completed', _tasksCompleted.toDouble(), 20, primaryGreen, isDark),
                          const SizedBox(height: 12),
                          _progressRow(isAr ? 'الكورسات المكتملة' : 'Courses Completed', _coursesCompleted.toDouble(), 10, Colors.orange, isDark),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Menu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(isAr ? 'الحساب' : 'Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1.2)),
                        ),
                        _menuSection(card, [
                          _MenuTile(
                            icon: Icons.person_outline_rounded,
                            title: isAr ? 'تعديل الملف الشخصي' : 'Edit Profile',
                            color: primaryBlue,
                            onTap: () async {
                              final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                              if (updated == true && mounted) { _loadProfile(); setState(() {}); }
                            },
                          ),
                          _MenuTile(
                            icon: Icons.notifications_outlined,
                            title: isAr ? 'الإشعارات' : 'Notifications',
                            color: primaryBlue,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                          ),
                        ], isDark),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(isAr ? 'الدعم' : 'Support', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1.2)),
                        ),
                        _menuSection(card, [
                          _MenuTile(
                            icon: Icons.support_agent_rounded,
                            title: isAr ? 'التواصل مع المنظمة' : 'Contact Organization',
                            color: primaryGreen,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen())),
                          ),
                          _MenuTile(
                            icon: Icons.settings_outlined,
                            title: isAr ? 'الإعدادات' : 'Settings',
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                          ),
                        ], isDark),
                        const SizedBox(height: 16),
                        _menuSection(card, [
                          _MenuTile(
                            icon: Icons.logout_rounded,
                            title: isAr ? 'تسجيل الخروج' : 'Sign Out',
                            color: Colors.redAccent,
                            onTap: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginScreen()), (r) => false);
                            },
                            isDestructive: true,
                          ),
                        ], isDark),
                      ]),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(isAr ? 'صندوق مكافحة الإدمان © 2026' : 'Drug Addiction Control Fund © 2026', style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.black26)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _headerStat(String value, String label, IconData icon) {
    return Expanded(child: Column(children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65)), textAlign: TextAlign.center),
    ]));
  }

  Widget _vDivider() => Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2));

  Widget _progressRow(String label, double value, double max, Color color, bool isDark) {
    final percent = (value / max).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)),
        Text('${value.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: percent, backgroundColor: isDark ? Colors.white12 : const Color(0xFFEEEEEE), valueColor: AlwaysStoppedAnimation(color), minHeight: 7)),
    ]);
  }

  Widget _menuSection(Color card, List<_MenuTile> tiles, bool isDark) {
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3))]),
      child: Column(children: tiles.asMap().entries.map((entry) {
        final i = entry.key;
        final tile = entry.value;
        return Column(children: [
          ListTile(
            onTap: tile.onTap,
            leading: Container(height: 38, width: 38, decoration: BoxDecoration(color: tile.color.withOpacity(tile.isDestructive ? 0.08 : 0.1), borderRadius: BorderRadius.circular(11)), child: Icon(tile.icon, color: tile.color, size: 19)),
            title: Text(tile.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: tile.isDestructive ? Colors.redAccent : (isDark ? Colors.white : Colors.black87))),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: isDark ? Colors.white24 : Colors.black26),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          ),
          if (i < tiles.length - 1) Divider(height: 1, indent: 66, color: isDark ? Colors.white12 : const Color(0xFFF0F0F0)),
        ]);
      }).toList()),
    );
  }
}

class _MenuTile {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;
  const _MenuTile({required this.icon, required this.title, required this.color, required this.onTap, this.isDestructive = false});
}