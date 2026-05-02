import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import all screens (add as you build them)
// import '../../screens/auth/sign_in_screen.dart';
// import '../../screens/home/home_screen.dart';
// ... etc

// Placeholder widget until screens are built
class PlaceholderScreen extends StatelessWidget {
  final String name;
  const PlaceholderScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3D2E),
      appBar: AppBar(title: Text(name), backgroundColor: Colors.transparent),
      body: Center(
        child: Text(
          '$name\n(coming soon)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/sign-in',

    // Auth redirect guard
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isOnAuthPage =
          state.matchedLocation.startsWith('/sign-in') ||
          state.matchedLocation.startsWith('/onboarding');

      if (user == null && !isOnAuthPage) return '/sign-in';
      if (user != null && isOnAuthPage) return '/home';
      return null;
    },

    routes: [
      // ─── Auth ──────────────────────────────────────
      GoRoute(
        path: '/sign-in',
        name: 'signIn',
        builder: (_, __) => const PlaceholderScreen(name: 'Sign In'),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const PlaceholderScreen(name: 'Onboarding'),
      ),

      // ─── Main Shell with Bottom Nav ────────────────
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (_, __) => const PlaceholderScreen(name: 'Home'),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (_, __) => const PlaceholderScreen(name: 'History'),
            routes: [
              GoRoute(
                path: ':date',
                name: 'dayDetail',
                builder: (_, s) => PlaceholderScreen(
                  name: 'Day Detail: ${s.pathParameters['date']}',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/friends',
            name: 'friends',
            builder: (_, __) => const PlaceholderScreen(name: 'Friends'),
            routes: [
              GoRoute(
                path: 'invite',
                name: 'invite',
                builder: (_, __) => const PlaceholderScreen(name: 'Invite'),
              ),
              GoRoute(
                path: 'group-sheet',
                name: 'groupSheet',
                builder: (_, __) =>
                    const PlaceholderScreen(name: 'Group Sheet'),
              ),
              GoRoute(
                path: 'group-manage',
                name: 'groupManage',
                builder: (_, __) =>
                    const PlaceholderScreen(name: 'Group Manage'),
              ),
              GoRoute(
                path: ':uid',
                name: 'friendProfile',
                builder: (_, s) => PlaceholderScreen(
                  name: 'Friend: ${s.pathParameters['uid']}',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/leaderboard',
            name: 'leaderboard',
            builder: (_, __) => const PlaceholderScreen(name: 'Leaderboard'),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (_, __) => const PlaceholderScreen(name: 'Notifications'),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (_, __) => const PlaceholderScreen(name: 'Profile'),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (_, __) => const PlaceholderScreen(name: 'Settings'),
            routes: [
              GoRoute(
                path: 'quiet-hours',
                name: 'quietHours',
                builder: (_, __) =>
                    const PlaceholderScreen(name: 'Quiet Hours'),
              ),
            ],
          ),
        ],
      ),

      // ─── Full-screen (no bottom nav) ───────────────
      GoRoute(
        path: '/day-complete',
        name: 'dayComplete',
        builder: (_, __) => const PlaceholderScreen(name: 'Day Complete'),
      ),
    ],
  );
});

// Shell wrapper that adds bottom navigation
class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithBottomNav({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/friends') || location.startsWith('/leaderboard'))
      return 2;
    if (location.startsWith('/notifications') ||
        location.startsWith('/profile') ||
        location.startsWith('/settings'))
      return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/history');
            case 2:
              context.go('/friends');
            case 3:
              context.go('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
