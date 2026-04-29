import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/guard/guard_home_screen.dart';
import '../features/guard/add_visitor_screen.dart';
import '../features/host/host_home_screen.dart';
import '../features/host/approval_detail_screen.dart';
import '../features/host/meeting_history_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/manage_users_screen.dart';
import '../features/super_admin/super_admin_dashboard_screen.dart';
import '../features/super_admin/manage_companies_screen.dart';
import '../features/super_admin/add_company_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isLoggedIn = authState.isAuthenticated;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) {
        return _homeRouteForRole(authState.user!.role);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // Guard
      GoRoute(
        path: '/guard',
        builder: (_, __) => const GuardHomeScreen(),
        routes: [
          GoRoute(path: 'add-visitor', builder: (_, __) => const AddVisitorScreen()),
        ],
      ),

      // Host
      GoRoute(
        path: '/host',
        builder: (_, __) => const HostHomeScreen(),
        routes: [
          GoRoute(
            path: 'approval/:visitorId',
            builder: (_, state) => ApprovalDetailScreen(
              visitorId: state.pathParameters['visitorId']!,
            ),
          ),
          GoRoute(path: 'history', builder: (_, __) => const MeetingHistoryScreen()),
        ],
      ),

      // Admin
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminDashboardScreen(),
        routes: [
          GoRoute(path: 'users', builder: (_, __) => const ManageUsersScreen()),
        ],
      ),

      // Super Admin
      GoRoute(
        path: '/super-admin',
        builder: (_, __) => const SuperAdminDashboardScreen(),
        routes: [
          GoRoute(path: 'companies', builder: (_, __) => const ManageCompaniesScreen()),
          GoRoute(path: 'companies/add', builder: (_, __) => const AddCompanyScreen()),
        ],
      ),
    ],
  );
});

String _homeRouteForRole(String role) {
  switch (role) {
    case UserRole.guard: return '/guard';
    case UserRole.host: return '/host';
    case UserRole.admin: return '/admin';
    case UserRole.superAdmin: return '/super-admin';
    default: return '/login';
  }
}
