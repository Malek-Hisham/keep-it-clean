import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';
import 'courses_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TasksScreen(),
    CoursesScreen(),
    ChatScreen(isTab: true),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4))],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: theme.brightness == Brightness.dark ? Colors.white38 : Colors.black38,
              backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home_rounded), label: isAr ? 'الرئيسية' : 'Home'),
                BottomNavigationBarItem(icon: const Icon(Icons.task_alt_outlined), activeIcon: const Icon(Icons.task_alt_rounded), label: isAr ? 'المهام' : 'Tasks'),
                BottomNavigationBarItem(icon: const Icon(Icons.school_outlined), activeIcon: const Icon(Icons.school_rounded), label: isAr ? 'الكورسات' : 'Courses'),
                BottomNavigationBarItem(icon: const Icon(Icons.chat_outlined), activeIcon: const Icon(Icons.chat_rounded), label: isAr ? 'المحادثات' : 'Chat'),
                BottomNavigationBarItem(
                  icon: _NotifBadge(uid: uid, active: false),
                  activeIcon: _NotifBadge(uid: uid, active: true),
                  label: isAr ? 'الملف' : 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotifBadge extends StatelessWidget {
  final String uid;
  final bool active;
  const _NotifBadge({required this.uid, required this.active});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('targetUid', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Stack(clipBehavior: Clip.none, children: [
          Icon(active ? Icons.person_rounded : Icons.person_outline_rounded),
          if (count > 0)
            Positioned(
              top: -4, right: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
        ]);
      },
    );
  }
}