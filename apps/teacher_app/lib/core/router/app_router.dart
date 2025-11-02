import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/enrollment/presentation/pages/enrollment_list_page.dart';
import '../../features/enrollment/presentation/pages/face_enrollment_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/enrollment',
        builder: (context, state) => const EnrollmentListPage(),
      ),
      GoRoute(
        path: '/enrollment/capture',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return FaceEnrollmentPage(
            studentId: extra['studentId'] as String,
            studentName: extra['studentName'] as String,
          );
        },
      ),
    ],
  );
}
