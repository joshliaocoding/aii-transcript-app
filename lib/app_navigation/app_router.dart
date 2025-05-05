import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import your screen files from the new locations
import 'package:ai_transcript_app/features/meeting_records/presentation/screens/home_screen.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/screens/meeting_details_screen.dart';
import 'package:ai_transcript_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:ai_transcript_app/features/recording/presentation/screens/record_screen.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/screens/saved_screen.dart';

// Navigator keys
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

// The router configuration
final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/', // Start at the home screen
  routes: [
    // ShellRoute for main screens with BottomNavBar
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        // The _MainScreen widget provides the Scaffold structure
        return _MainScreen(child: child);
      },
      routes: [
        // Routes accessible via BottomNavigationBar
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder:
              (context, state) => const NoTransitionPage(
                key: ValueKey('home'), // Add unique keys for pages
                child: HomeScreen(), // Updated location
              ),
        ),
        GoRoute(
          path: '/saved', // Renamed path for clarity
          name: 'saved', // Renamed name
          pageBuilder:
              (context, state) => const NoTransitionPage(
                key: ValueKey('saved'), // Add unique keys for pages
                child: SavedScreen(), // Updated location and name
              ),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder:
              (context, state) => const NoTransitionPage(
                key: ValueKey('profile'), // Add unique keys for pages
                child: ProfileScreen(), // Updated location
              ),
        ),
      ],
    ),
    // Top-level routes (no BottomNavBar)
    GoRoute(
      path: '/record',
      name: 'record',
      parentNavigatorKey:
          _rootNavigatorKey, // Use root key to navigate OVER the shell
      builder: (context, state) => const RecordScreen(), // Updated location
    ),
    GoRoute(
      path: '/details/:meetingId',
      name: 'details',
      parentNavigatorKey: _rootNavigatorKey, // Use root key
      builder: (context, state) {
        final meetingId = state.pathParameters['meetingId']!;
        return MeetingDetailsScreen(meetingId: meetingId); // Updated location
      },
    ),
  ],
  // Optional: Error handling
  errorBuilder:
      (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(child: Text('No route defined for ${state.uri}')),
      ),
);

// --- The Shell Widget (_MainScreen) ---
// Stateless widget providing the Scaffold with BottomNavBar
class _MainScreen extends StatelessWidget {
  const _MainScreen({required this.child, super.key});

  final Widget child;

  // Calculates the selected BottomNavBar index based on the current route
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/saved')) {
      // Updated path check
      return 1;
    }
    if (location.startsWith('/profile')) {
      return 2;
    }
    return 0; // Default to home
  }

  // Handles navigation when a BottomNavBar item is tapped
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('home');
        break;
      case 1:
        context.goNamed('saved'); // Updated name
        break;
      case 2:
        context.goNamed('profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child, // Display the screen content

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved', // Updated label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
