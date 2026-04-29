import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/company_model.dart';
import '../../models/user_model.dart';
import '../../services/company_service.dart';

class SuperAdminUsersScreen extends StatefulWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  State<SuperAdminUsersScreen> createState() => _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState extends State<SuperAdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _admins = [];
  List<UserModel> _hosts = [];
  List<UserModel> _guards = [];
  List<CompanyModel> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        CompanyService().getUsers(role: 'admin'),
        CompanyService().getUsers(role: 'host'),
        CompanyService().getUsers(role: 'guard'),
        CompanyService().getCompanies(),
      ]);
      setState(() {
        _admins = results[0] as List<UserModel>;
        _hosts = results[1] as List<UserModel>;
        _guards = results[2] as List<UserModel>;
        _companies = results[3] as List<CompanyModel>;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddUserDialog(
        companies: _companies,
        onCreated: (user) {
          setState(() {
            if (user.role == 'admin') {
              _admins.insert(0, user);
            } else if (user.role == 'host') {
              _hosts.insert(0, user);
            } else if (user.role == 'guard') {
              _guards.insert(0, user);
            }
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Admins (${_admins.length})'),
            Tab(text: 'Hosts (${_hosts.length})'),
            Tab(text: 'Guards (${_guards.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _UserList(users: _admins, onRefresh: _load),
                _UserList(users: _hosts, onRefresh: _load),
                _UserList(users: _guards, onRefresh: _load),
              ],
            ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<UserModel> users;
  final VoidCallback onRefresh;

  const _UserList({required this.users, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const EmptyWidget(message: 'No users found', icon: Icons.person_off_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, top: 8),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final user = users[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(AppUtils.initials(user.name),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${user.email}\n${user.phone}'),
            isThreeLine: true,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.isActive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  color: user.isActive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  final List<CompanyModel> companies;
  final void Function(UserModel) onCreated;

  const _AddUserDialog({required this.companies, required this.onCreated});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'admin';
  String? _selectedCompanyId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await CompanyService().createUser({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'password': _passCtrl.text,
        'role': _role,
        'companyIds': [_selectedCompanyId],
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated(user);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User created successfully'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppTextField(
              label: 'Full Name',
              controller: _nameCtrl,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Email',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Phone',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Password',
              controller: _passCtrl,
              obscureText: true,
              validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _role,
              decoration: const InputDecoration(
                  labelText: 'Role', filled: true, fillColor: Colors.white),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'host', child: Text('Host (Employee)')),
                DropdownMenuItem(value: 'guard', child: Text('Security Guard')),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedCompanyId,
              decoration: const InputDecoration(
                  labelText: 'Company *', filled: true, fillColor: Colors.white),
              hint: const Text('Select company'),
              items: widget.companies
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCompanyId = v),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        PrimaryButton(label: 'Create', isLoading: _isLoading, onPressed: _submit),
      ],
    );
  }
}
