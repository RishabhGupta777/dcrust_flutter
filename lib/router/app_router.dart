import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/events_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/complaints_screen.dart';
import '../screens/papers_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/alumni_directory_screen.dart';
import '../screens/verify_email_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/admin_dashboard_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        
        final unauthRoutes = [
          '/login', 
          '/register', 
          '/forgot-password', 
          '/reset-password',
          '/verify-email'
        ];
        
        final isAuthRoute = unauthRoutes.contains(state.matchedLocation);

        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        if (isAuthenticated && isAuthRoute) {
          return '/';
        }

        return null;
      },
      refreshListenable: authProvider,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(initialTab: 0),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/events',
          builder: (context, state) => const EventsScreen(),
        ),
        GoRoute(
          path: '/attendance',
          builder: (context, state) => const AttendanceScreen(),
        ),
        GoRoute(
          path: '/complaints',
          builder: (context, state) => const ComplaintsScreen(),
        ),
        GoRoute(
          path: '/papers',
          builder: (context, state) => const PapersScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const HomeScreen(initialTab: 1),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const HomeScreen(initialTab: 2),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/alumni',
          builder: (context, state) => const AlumniDirectoryScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return VerifyEmailScreen(
              email: extra?['email'] ?? '',
              message: extra?['message'],
            );
          },
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ResetPasswordScreen(
              email: extra?['email'] ?? '',
            );
          },
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],
    );
  }
}
