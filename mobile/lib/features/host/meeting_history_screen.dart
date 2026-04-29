import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/visitor_model.dart';
import '../../services/visitor_service.dart';

class MeetingHistoryScreen extends ConsumerStatefulWidget {
  const MeetingHistoryScreen({super.key});

  @override
  ConsumerState<MeetingHistoryScreen> createState() => _MeetingHistoryScreenState();
}

class _MeetingHistoryScreenState extends ConsumerState<MeetingHistoryScreen> {
  List<VisitorModel> _visitors = [];
  bool _isLoading = true;
  String? _error;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await VisitorService().getVisitors(status: _filterStatus, limit: 50);
      setState(() {
        _visitors = result['visitors'] as List<VisitorModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting History'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (v) { setState(() => _filterStatus = v); _load(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'denied', child: Text('Denied')),
              const PopupMenuItem(value: 'checkedOut', child: Text('Checked Out')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget2(message: _error!, onRetry: _load)
              : _visitors.isEmpty
                  ? const EmptyWidget(message: 'No meeting history yet')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24, top: 8),
                        itemCount: _visitors.length,
                        itemBuilder: (context, i) => _HistoryCard(visitor: _visitors[i]),
                      ),
                    ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final VisitorModel visitor;
  const _HistoryCard({required this.visitor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: visitor.visitorPhoto != null ? NetworkImage(visitor.visitorPhoto!) : null,
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
                  Text(visitor.visitorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(visitor.purpose,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(AppUtils.formatDateTime(visitor.checkInTime),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            StatusBadge(status: visitor.status),
          ],
        ),
      ),
    );
  }
}
