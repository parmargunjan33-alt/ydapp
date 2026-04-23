// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/university/presentation/university_screen.dart';
import '../../features/course/presentation/course_screen.dart';
import '../../features/semester/presentation/semester_list_screen.dart';
import '../../features/semester/presentation/subject_list_screen.dart';
import '../../features/semester/presentation/semester_screen.dart';
import '../../features/pdf_viewer/presentation/pdf_viewer_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../core/models/models.dart';
import '../../features/main_layout/presentation/main_layout.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

/// A notifier that triggers the GoRouter to re-evaluate its redirect logic
/// whenever the authentication status changes.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider.select((s) => s.status), (_, __) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);
  
  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: refreshNotifier,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpVerificationScreen(
            mobile: extra['mobile'] as String,
            email: extra['email'] as String?,
            registrationData: extra['registrationData'] as Map<String, dynamic>,
          );
        },
      ),
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const UniversityScreen(),
                routes: [
                  GoRoute(
                    path: 'courses',
                    builder: (_, state) {
                      final extra = state.extra;
                      final university = extra is UniversityModel
                          ? extra
                          : UniversityModel.fromJson(extra as Map<String, dynamic>);
                      return CourseScreen(university: university);
                    },
                  ),
                  GoRoute(
                    path: 'semesters',
                    builder: (_, state) {
                      final extra = state.extra;
                      final course = extra is CourseModel
                          ? extra
                          : CourseModel.fromJson(extra as Map<String, dynamic>);
                      return SemesterListScreen(course: course);
                    },
                  ),
                  GoRoute(
                    path: 'subjects/:id',
                    builder: (_, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      final name = state.extra as String;
                      return SubjectListScreen(semesterId: id, semesterName: name);
                    },
                  ),
                  GoRoute(
                    path: 'semester/:id',
                    builder: (_, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      final extra = state.extra as Map<String, dynamic>;
                      return SemesterScreen(
                        semesterId: id,
                        semesterName: extra['semesterName'] as String,
                        subject: extra['subject'] as SubjectModel?,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/pdf-viewer',
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>;
          return PdfViewerScreen(
            url: args['url'] as String,
            title: args['title'] as String,
            isSubscribed: args['isSubscribed'] as bool,
            paperId: args['paperId'] as int,
            semesterId: args['semesterId'] as int?,
            semesterName: args['semesterName'] as String?,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final status = authState.status;
      final loc = state.matchedLocation;
      
      // 1. Handle Loading/Initialization
      if (status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }

      final isAuthenticated = status == AuthStatus.authenticated;
      
      // 2. Define Auth Routes
      final isAuthRoute = loc == '/login' || 
                          loc == '/register' || 
                          loc == '/verify-otp' || 
                          loc == '/forgot-password' ||
                          loc == '/splash';

      // 3. Redirect to login if not authenticated and trying to access protected routes
      if (!isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      // 4. Redirect to home if authenticated and trying to access auth routes
      if (isAuthRoute) {
        return '/home';
      }

      // 5. No redirection needed
      return null;
    },
  );
});
