import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/company_model.dart';
import '../../models/user_model.dart';
import '../../services/company_service.dart';

class ManageCompaniesScreen extends StatefulWidget {
  const ManageCompaniesScreen({super.key});

  @override
  State<ManageCompaniesScreen> createState() => _ManageCompaniesScreenState();
}

class _ManageCompaniesScreenState extends State<ManageCompaniesScreen> {
  List<CompanyModel> _companies = [];
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
      final companies = await CompanyService().getCompanies();
      setState(() { _companies = companies; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _toggleActive(CompanyModel company) async {
    try {
      final updated = await CompanyService().updateCompany(company.id, {'isActive': !company.isActive});
      if (!mounted) return;
      setState(() {
        _companies = _companies.map((c) => c.id == company.id ? updated : c).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  void _showAssignGuardDialog(CompanyModel company) {
    showDialog(
      context: context,
      builder: (_) => _AssignGuardDialog(company: company),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Companies')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/super-admin/companies/add');
          _load();
        },
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Company'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget2(message: _error!, onRetry: _load)
              : _companies.isEmpty
                  ? const EmptyWidget(message: 'No companies yet', icon: Icons.business_outlined)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100, top: 8),
                        itemCount: _companies.length,
                        itemBuilder: (context, i) {
                          final c = _companies[i];
                          return Card(
                            child: ExpansionTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.business_rounded, color: AppColors.primary),
                              ),
                              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(c.address, style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: c.isActive,
                                    activeThumbColor: AppColors.success,
                                    activeTrackColor: AppColors.success.withValues(alpha: 0.4),
                                    onChanged: (_) => _toggleActive(c),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: Column(
                                    children: [
                                      if (c.phone != null)
                                        _Detail(icon: Icons.phone_rounded, text: c.phone!),
                                      if (c.email != null)
                                        _Detail(icon: Icons.email_rounded, text: c.email!),
                                      const SizedBox(height: 12),
                                      Row(children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showAssignGuardDialog(c),
                                            icon: const Icon(Icons.security_rounded, size: 16),
                                            label: const Text('Assign Guard'),
                                          ),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Detail({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _AssignGuardDialog extends StatefulWidget {
  final CompanyModel company;
  const _AssignGuardDialog({required this.company});

  @override
  State<_AssignGuardDialog> createState() => _AssignGuardDialogState();
}

class _AssignGuardDialogState extends State<_AssignGuardDialog> {
  List<UserModel> _guards = [];
  bool _isLoading = true;
  String? _assigningId;

  @override
  void initState() {
    super.initState();
    _loadGuards();
  }

  Future<void> _loadGuards() async {
    try {
      final guards = await CompanyService().getUsers(role: 'guard');
      setState(() { _guards = guards; _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assign(String guardId) async {
    setState(() => _assigningId = guardId);
    try {
      await CompanyService().assignGuard(widget.company.id, guardId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guard assigned'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _assigningId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Guard to\n${widget.company.name}',
          style: const TextStyle(fontSize: 16)),
      content: _isLoading
          ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()))
          : _guards.isEmpty
              ? const Text('No guards registered yet.')
              : SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    itemCount: _guards.length,
                    itemBuilder: (_, i) {
                      final g = _guards[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(AppUtils.initials(g.name),
                              style: const TextStyle(color: AppColors.primary)),
                        ),
                        title: Text(g.name),
                        subtitle: Text(g.phone),
                        trailing: _assigningId == g.id
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                        onTap: () => _assign(g.id),
                      );
                    },
                  ),
                ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    );
  }
}
