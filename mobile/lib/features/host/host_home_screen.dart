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

class HostHomeScreen extends ConsumerStatefulWidget {
  const HostHomeScreen({super.key});

  @override
  ConsumerState<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends ConsumerState<HostHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  void _loadPending() {
    ref.read(pendingVisitorProvider.notifier).loadVisitors(status: 'pending');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final pendingState = ref.watch(pendingVisitorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SecureGate'),
            Text('Welcome, ${user.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Meeting History',
            onPressed: () => context.push('/host/history'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pending count banner
          if (!pendingState.isLoading && pendingState.visitors.isNotEmpty)
            Container(
              width: double.infinity,
              color: AppColors.warning.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${pendingState.visitors.length} visitor${pendingState.visitors.length > 1 ? 's' : ''} waiting for your approval',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning),
                  ),
                ],
              ),
            ),

          Expanded(
            child: pendingState.isLoading
                ? const LoadingWidget(message: 'Loading approval requests...')
                : pendingState.error != null
                    ? ErrorWidget2(message: pendingState.error!, onRetry: _loadPending)
                    : pendingState.visitors.isEmpty
                        ? const EmptyWidget(
                            message: 'No pending approvals',
                            icon: Icons.check_circle_outline_rounded,
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadPending(),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24, top: 8),
                              itemCount: pendingState.visitors.length,
                              itemBuilder: (context, index) {
                                return _PendingVisitorCard(
                                  visitor: pendingState.visitors[index],
                                  onTap: () => context.push(
                                    '/host/approval/${pendingState.visitors[index].id}',
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _PendingVisitorCard extends StatelessWidget {
  final VisitorModel visitor;
  final VoidCallback onTap;

  const _PendingVisitorCard({required this.visitor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                backgroundImage: visitor.visitorPhoto != null
                    ? NetworkImage(visitor.visitorPhoto!)
                    : null,
                child: visitor.visitorPhoto == null
                    ? Text(AppUtils.initials(visitor.visitorName),
                        style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 18))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(visitor.visitorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(visitor.visitorPhone,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      visitor.purpose,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppUtils.timeAgo(visitor.checkInTime),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Column(
                children: [
                  StatusBadge(status: 'pending'),
                  SizedBox(height: 8),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
