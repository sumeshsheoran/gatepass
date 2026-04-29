import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/visitor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../services/visitor_service.dart';

class GuardHomeScreen extends ConsumerStatefulWidget {
  const GuardHomeScreen({super.key});

  @override
  ConsumerState<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends ConsumerState<GuardHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  void _load() {
    ref.read(visitorProvider.notifier).loadVisitors(status: _selectedStatus);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final visitorState = ref.watch(visitorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SecureGate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(user.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (i) {
            setState(() {
              _selectedStatus = ['', 'pending', 'approved'][i].isEmpty ? null : ['', 'pending', 'approved'][i];
            });
            _load();
          },
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Inside'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/guard/add-visitor'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('New Visitor', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: visitorState.isLoading
          ? const LoadingWidget(message: 'Loading visitors...')
          : visitorState.error != null
              ? ErrorWidget2(message: visitorState.error!, onRetry: _load)
              : visitorState.visitors.isEmpty
                  ? const EmptyWidget(message: 'No visitors yet today', icon: Icons.people_outline_rounded)
                  : RefreshIndicator(
                      onRefresh: () async => _load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100, top: 8),
                        itemCount: visitorState.visitors.length,
                        itemBuilder: (context, index) {
                          return _VisitorCard(
                            visitor: visitorState.visitors[index],
                            onCheckout: () async {
                              try {
                                final updated = await VisitorService()
                                    .checkoutVisitor(visitorState.visitors[index].id);
                                ref.read(visitorProvider.notifier).updateVisitor(updated);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _VisitorCard extends StatelessWidget {
  final VisitorModel visitor;
  final VoidCallback onCheckout;

  const _VisitorCard({required this.visitor, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: visitor.visitorPhoto != null
                      ? NetworkImage(visitor.visitorPhoto!)
                      : null,
                  child: visitor.visitorPhoto == null
                      ? Text(AppUtils.initials(visitor.visitorName),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(visitor.visitorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(visitor.visitorPhone,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                StatusBadge(status: visitor.status),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.person_outline, label: 'Meeting', value: visitor.hostName),
            const SizedBox(height: 4),
            _InfoRow(icon: Icons.notes_rounded, label: 'Purpose', value: visitor.purpose),
            const SizedBox(height: 4),
            _InfoRow(icon: Icons.access_time_rounded, label: 'Check-in', value: AppUtils.formatDateTime(visitor.checkInTime)),
            if (visitor.status == 'approved') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCheckout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Mark Check-out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                  ),
                ),
              ),
            ],
            if (visitor.status == 'denied' && visitor.denialReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${visitor.denialReason}',
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
