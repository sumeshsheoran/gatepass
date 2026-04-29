import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/visitor_model.dart';
import '../../providers/visitor_provider.dart';
import '../../services/visitor_service.dart';

class ApprovalDetailScreen extends ConsumerStatefulWidget {
  final String visitorId;
  const ApprovalDetailScreen({super.key, required this.visitorId});

  @override
  ConsumerState<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends ConsumerState<ApprovalDetailScreen> {
  VisitorModel? _visitor;
  bool _isLoading = true;
  bool _isActing = false;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await VisitorService().getVisitor(widget.visitorId);
      setState(() { _visitor = v; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approve() async {
    setState(() => _isActing = true);
    try {
      final updated = await VisitorService().approveVisitor(widget.visitorId);
      ref.read(pendingVisitorProvider.notifier).updateVisitor(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor approved. Guard notified.'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _deny() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deny Entry?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Optionally provide a reason:'),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deny', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isActing = true);
    try {
      final updated = await VisitorService().denyVisitor(
        widget.visitorId,
        reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      );
      ref.read(pendingVisitorProvider.notifier).updateVisitor(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry denied. Guard notified.'), backgroundColor: AppColors.error),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Request')),
      body: _isLoading
          ? const LoadingWidget()
          : _visitor == null
              ? const ErrorWidget2(message: 'Failed to load visitor details')
              : _visitor!.status != 'pending'
                  ? _AlreadyProcessed(status: _visitor!.status)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _VisitorInfoCard(visitor: _visitor!),
                          const SizedBox(height: 32),
                          const Text(
                            'Do you want to allow this person in?',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          SuccessButton(
                            label: 'Approve Entry',
                            isLoading: _isActing,
                            onPressed: _approve,
                          ),
                          const SizedBox(height: 12),
                          DangerButton(
                            label: 'Deny Entry',
                            isLoading: _isActing,
                            onPressed: _deny,
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _VisitorInfoCard extends StatelessWidget {
  final VisitorModel visitor;
  const _VisitorInfoCard({required this.visitor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Photo
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: visitor.visitorPhoto != null ? NetworkImage(visitor.visitorPhoto!) : null,
              child: visitor.visitorPhoto == null
                  ? Text(AppUtils.initials(visitor.visitorName),
                      style: const TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(visitor.visitorName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(visitor.visitorPhone, style: const TextStyle(color: AppColors.textSecondary)),
            const Divider(height: 32),
            _DetailRow(icon: Icons.notes_rounded, label: 'Purpose', value: visitor.purpose),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.security_rounded, label: 'Logged by', value: visitor.guardName),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.access_time_rounded,
              label: 'Arrived at',
              value: AppUtils.formatDateTime(visitor.checkInTime),
            ),
            if (visitor.idProofPhoto != null) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('ID Proof:', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(visitor.idProofPhoto!, height: 120, fit: BoxFit.cover, width: double.infinity),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(color: AppColors.textSecondary)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }
}

class _AlreadyProcessed extends StatelessWidget {
  final String status;
  const _AlreadyProcessed({required this.status});

  @override
  Widget build(BuildContext context) {
    final isApproved = status == 'approved';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 72,
            color: isApproved ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            isApproved ? 'Already Approved' : 'Already Denied',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('This request has already been processed.',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
