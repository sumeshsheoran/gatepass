import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/visitor_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Map<String, dynamic>? _live;
  Map<String, dynamic>? _stats;
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
        CompanyService().getDashboardLive(),
        CompanyService().getDashboardStats(),
      ]);
      setState(() {
        _live = results[0];
        _stats = results[1];
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
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.people_rounded), tooltip: 'Manage Users',
              onPressed: () => context.push('/admin/users')),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
          IconButton(icon: const Icon(Icons.logout_rounded),
              onPressed: () => ref.read(authProvider.notifier).logout()),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
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
                        const SizedBox(height: 4),
                        const Text('Live overview for your company',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 20),

                        // Stats row
                        Row(children: [
                          _StatCard(
                            label: 'Inside Now',
                            value: '${_live?['currentlyInside'] ?? 0}',
                            icon: Icons.meeting_room_rounded,
                            color: AppColors.approved,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Pending',
                            value: '${_live?['pendingApproval'] ?? 0}',
                            icon: Icons.hourglass_top_rounded,
                            color: AppColors.pending,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Today',
                            value: '${_live?['todayTotal'] ?? 0}',
                            icon: Icons.today_rounded,
                            color: AppColors.primary,
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Weekly stats
                        if (_stats != null) ...[
                          _StatsSection(stats: _stats!),
                          const SizedBox(height: 24),
                        ],

                        // Currently inside
                        const Text('Currently Inside',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if ((_live?['approved'] as List?)?.isEmpty ?? true)
                          const _EmptySection(message: 'No visitors inside right now')
                        else
                          ...(_live!['approved'] as List)
                              .map((v) => _LiveVisitorTile(visitor: VisitorModel.fromJson(v))),

                        const SizedBox(height: 24),

                        // Pending approvals
                        const Text('Pending Approvals',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if ((_live?['pending'] as List?)?.isEmpty ?? true)
                          const _EmptySection(message: 'No pending approvals')
                        else
                          ...(_live!['pending'] as List)
                              .map((v) => _LiveVisitorTile(visitor: VisitorModel.fromJson(v))),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatLine(label: 'This Week', value: '${stats['weekVisitors'] ?? 0}')),
              Expanded(child: _StatLine(label: 'Total Ever', value: '${stats['totalVisitors'] ?? 0}')),
            ],
          ),
          if (stats['statusBreakdown'] != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in (stats['statusBreakdown'] as Map).entries)
                  StatusBadge(status: entry.key),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  const _StatLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _LiveVisitorTile extends StatelessWidget {
  final VisitorModel visitor;
  const _LiveVisitorTile({required this.visitor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(AppUtils.initials(visitor.visitorName),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(visitor.visitorName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Meeting ${visitor.hostName} • ${AppUtils.timeAgo(visitor.checkInTime)}',
            style: const TextStyle(fontSize: 12)),
        trailing: StatusBadge(status: visitor.status),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(message,
          style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
    );
  }
}
