import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import your screen files from the new locations
import 'package:ai_transcript_app/features/meeting_records/presentation/screens/home_screen.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/screens/meeting_details_screen.dart';
import 'package:ai_transcript_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:ai_transcript_app/features/recording/presentation/screens/record_screen.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/screens/saved_screen.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/screens/edit_meeting_screen.dart';

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
          // No parentNavigatorKey here; it will use the ShellRoute's _shellNavigatorKey
        ),
        GoRoute(
          path: '/saved', // Renamed path for clarity
          name: 'saved', // Renamed name
          pageBuilder:
              (context, state) => const NoTransitionPage(
                key: ValueKey('saved'), // Add unique keys for pages
                child: SavedScreen(), // Updated location and name
              ),
          // No parentNavigatorKey here
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder:
              (context, state) => const NoTransitionPage(
                key: ValueKey('profile'), // Add unique keys for pages
                child: ProfileScreen(), // Updated location
              ),
          // No parentNavigatorKey here
        ),
      ],
    ),
    // Top-level routes (no BottomNavBar, will use _rootNavigatorKey by default)
    GoRoute(
      path: '/record',
      name: 'record',
      // parentNavigatorKey: _rootNavigatorKey, // Can be omitted for top-level routes
      builder: (context, state) => const RecordScreen(), // Updated location
    ),
    GoRoute(
      path: '/details/:meetingId',
      name: 'details',
      // parentNavigatorKey: _rootNavigatorKey, // Can be omitted for top-level routes
      builder: (context, state) {
        final meetingId = state.pathParameters['meetingId']!;
        return MeetingDetailsScreen(meetingId: meetingId); // Updated location
      },
    ),
    GoRoute(
      path: '/edit/:meetingId', // MOVED to be a top-level route
      name: 'editMeeting',
      // parentNavigatorKey: _rootNavigatorKey, // Can be omitted for top-level routes
      builder: (context, state) {
        final meetingId = state.pathParameters['meetingId']!;
        return EditMeetingScreen(meetingId: meetingId);
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
    // Add checks for other shell routes if necessary
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
        showSelectedLabels: false, // Hide label for selected item
        showUnselectedLabels: false, // Hide label for unselected items
        // type: BottomNavigationBarType.fixed, // Optional: ensures items don't shift if you have more than 3
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '', // Set label to empty string
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: '', // Set label to empty string
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '', // Set label to empty string
          ),
        ],
      ),
    );
  }
}
