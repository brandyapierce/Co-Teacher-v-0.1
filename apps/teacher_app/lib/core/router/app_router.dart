import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/enrollment/presentation/pages/enrollment_list_page.dart';
import '../../features/enrollment/presentation/pages/face_enrollment_page.dart';
import '../../features/attendance/presentation/pages/attendance_scan_page.dart';
import '../../features/attendance/presentation/pages/attendance_list_page.dart';

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
      GoRoute(
        path: '/attendance/scan',
        builder: (context, state) {
          final extra = (state.extra as Map<String, dynamic>?) ?? {};
          return AttendanceScanPage(
            teacherId: extra['teacherId'] as String? ?? 'teacher-1',
            classId: extra['classId'] as String? ?? 'class-001',
            totalStudents: extra['totalStudents'] as int? ?? 25,
          );
        },
      ),
      // NEW ROUTE: Attendance History Page
      GoRoute(
        path: '/attendance/history',
        builder: (context, state) => const AttendanceListPage(),
      ),
    ],
  );
}
