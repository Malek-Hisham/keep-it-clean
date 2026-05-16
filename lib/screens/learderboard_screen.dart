import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

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
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded, color: Colors.white),
                            ),
                            Expanded(
                              child: Text(
                                isAr ? 'لوحة المتصدرين' : 'Leaderboard',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _headerStat('🏆', isAr ? 'المتصدر' : 'Top Volunteer'),
                              _headerStat('⭐', isAr ? 'الساعات' : 'By Hours'),
                              _headerStat('✅', isAr ? 'المهام' : 'By Tasks'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadLeaderboard(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                        final volunteers = snap.data!;
                        if (volunteers.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.leaderboard_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                                const SizedBox(height: 12),
                                Text(isAr ? 'لا توجد بيانات بعد' : 'No data yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16)),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: volunteers.length,
                          itemBuilder: (context, i) {
                            final v = volunteers[i];
                            final rank = i + 1;
                            return _LeaderboardCard(
                              rank: rank,
                              data: v,
                              isDark: isDark,
                              card: card,
                              primaryBlue: primaryBlue,
                              primaryGreen: primaryGreen,
                              isAr: isAr,
                            );
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
      },
    );
  }

  Widget _headerStat(String emoji, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _loadLeaderboard() async {
    try {
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final List<Map<String, dynamic>> result = [];

      for (final userDoc in usersSnap.docs) {
        final uid = userDoc.id;
        final userData = userDoc.data();

        // Tasks done
        final tasksSnap = await FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedTo', arrayContains: uid)
            .where('status', isEqualTo: 'done')
            .get();
        final tasksDone = tasksSnap.docs.length;

        // Credit hours from courses
        final coursesSnap = await FirebaseFirestore.instance
            .collection('courses')
            .where('assignedTo', arrayContains: uid)
            .get();

        final progressDoc = await FirebaseFirestore.instance
            .collection('user_progress')
            .doc(uid)
            .get();
        final progressData = (progressDoc.data() as Map<String, dynamic>?) ?? {};
        final coursesProgress = (progressData['courses'] as Map<String, dynamic>?) ?? {};

        double creditHours = 0;
        for (final courseDoc in coursesSnap.docs) {
          final courseData = courseDoc.data();
          final hours = (courseData['creditHours'] as num? ?? 0).toDouble();
          final courseProgress = coursesProgress[courseDoc.id];
          final checklistDone = (courseProgress?['checklistDone'] as List?)?.length ?? 0;
          final checkSnap = await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseDoc.id)
              .collection('checklist')
              .get();
          final totalChecklist = checkSnap.docs.length;
          if (totalChecklist > 0 && checklistDone >= totalChecklist) {
            creditHours += hours;
          }
        }

        result.add({
          'uid': uid,
          'name': userData['name'] ?? 'Unknown',
          'photo': userData['photoBase64'],
          'tasksDone': tasksDone,
          'creditHours': creditHours,
          'score': (creditHours * 2) + (tasksDone * 10),
        });
      }

      result.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      return result;
    } catch (_) {
      return [];
    }
  }
}

class _LeaderboardCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;
  final bool isDark;
  final Color card;
  final Color primaryBlue;
  final Color primaryGreen;
  final bool isAr;

  const _LeaderboardCard({
    required this.rank,
    required this.data,
    required this.isDark,
    required this.card,
    required this.primaryBlue,
    required this.primaryGreen,
    required this.isAr,
  });

  Color get _rankColor {
    switch (rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return primaryBlue;
    }
  }

  String get _rankEmoji {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String;
    final tasksDone = data['tasksDone'] as int;
    final creditHours = (data['creditHours'] as double);
    final score = (data['score'] as double).toStringAsFixed(0);
    final isTop3 = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTop3 ? _rankColor.withOpacity(0.08) : card,
        borderRadius: BorderRadius.circular(20),
        border: isTop3 ? Border.all(color: _rankColor.withOpacity(0.3), width: 1.5) : null,
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 44,
            child: rank <= 3
                ? Text(_rankEmoji, style: const TextStyle(fontSize: 28), textAlign: TextAlign.center)
                : Container(
                    height: 36, width: 36,
                    decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 14))),
                  ),
          ),
          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: _rankColor.withOpacity(0.2),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'V', style: TextStyle(fontWeight: FontWeight.bold, color: _rankColor, fontSize: 18)),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF101828))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.school_rounded, size: 13, color: primaryBlue),
                    const SizedBox(width: 4),
                    Text('${creditHours.toStringAsFixed(0)}h', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                    const SizedBox(width: 12),
                    Icon(Icons.task_alt_rounded, size: 13, color: primaryGreen),
                    const SizedBox(width: 4),
                    Text('$tasksDone ${isAr ? "مهمة" : "tasks"}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                  ],
                ),
              ],
            ),
          ),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _rankColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(score, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _rankColor)),
          ),
        ],
      ),
    );
  }
}