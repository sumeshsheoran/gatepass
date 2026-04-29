import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_widget.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends ConsumerState<SuperAdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _live;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        CompanyService().getDashboardStats(),
        CompanyService().getDashboardLive(),
      ]);
      setState(() {
        _stats = results[0];
        _live = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.business_rounded),
            tooltip: 'Manage Companies',
            onPressed: () => context.push('/super-admin/companies'),
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading global dashboard...')
          : _error != null
              ? ErrorWidget2(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, ${user.name}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Text('Global Overview — All Companies',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 20),

                        // Top-level stats
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _BigStatCard(
                              label: 'Companies',
                              value: '${_stats?['companiesCount'] ?? 0}',
                              icon: Icons.business_rounded,
                              color: AppColors.primary,
                            ),
                            _BigStatCard(
                              label: 'Total Users',
                              value: '${_stats?['usersCount'] ?? 0}',
                              icon: Icons.people_rounded,
                              color: AppColors.primaryLight,
                            ),
                            _BigStatCard(
                              label: 'Today Visitors',
                              value: '${_stats?['todayVisitors'] ?? 0}',
                              icon: Icons.today_rounded,
                              color: AppColors.approved,
                            ),
                            _BigStatCard(
                              label: 'This Week',
                              value: '${_stats?['weekVisitors'] ?? 0}',
                              icon: Icons.date_range_rounded,
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Live status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Live Status',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            _LiveBadge(count: _live?['currentlyInside'] ?? 0),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _MiniStatCard(
                              label: 'Inside Now',
                              value: '${_live?['currentlyInside'] ?? 0}',
                              color: AppColors.approved,
                              icon: Icons.meeting_room_rounded,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _MiniStatCard(
                              label: 'Awaiting Approval',
                              value: '${_live?['pendingApproval'] ?? 0}',
                              color: AppColors.pending,
                              icon: Icons.hourglass_top_rounded,
                            )),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Total breakdown
                        const Text('All-Time Breakdown',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _TotalBreakdown(
                          total: _stats?['totalVisitors'] ?? 0,
                          breakdown: _stats?['statusBreakdown'] as Map? ?? {},
                        ),
                        const SizedBox(height: 24),

                        // Quick actions
                        const Text('Quick Actions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.add_business_rounded,
                              label: 'Add Company',
                              color: AppColors.primary,
                              onTap: () => context.push('/super-admin/companies/add'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.list_alt_rounded,
                              label: 'All Companies',
                              color: AppColors.primaryLight,
                              onTap: () => context.push('/super-admin/companies'),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BigStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  final int count;
  const _LiveBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.approved.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.approved, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$count inside', style: const TextStyle(color: AppColors.approved, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }
}

class _TotalBreakdown extends StatelessWidget {
  final int total;
  final Map breakdown;

  const _TotalBreakdown({required this.total, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      'pending': AppColors.pending,
      'approved': AppColors.approved,
      'denied': AppColors.denied,
      'checkedOut': AppColors.checkedOut,
    };
    final statusLabels = {
      'pending': 'Pending',
      'approved': 'Approved',
      'denied': 'Denied',
      'checkedOut': 'Checked Out',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Total Visitors: ', style: TextStyle(color: AppColors.textSecondary)),
              Text('$total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          ...statusColors.entries.map((e) {
            final count = breakdown[e.key] ?? 0;
            final pct = total > 0 ? count / total : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(statusLabels[e.key]!, style: TextStyle(fontSize: 13, color: e.value)),
                      Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: e.value)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pct.toDouble(),
                    backgroundColor: e.value.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(e.value),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
