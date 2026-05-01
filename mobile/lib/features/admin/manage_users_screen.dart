import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/user_model.dart';
import '../../services/company_service.dart';

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _hosts = [];
  List<UserModel> _guards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        CompanyService().getUsers(role: 'host'),
        CompanyService().getUsers(role: 'guard'),
      ]);
      setState(() {
        _hosts = results[0];
        _guards = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddUserDialog(onCreated: (user) {
        setState(() {
          if (user.role == 'host') _hosts.insert(0, user);
          else if (user.role == 'guard') _guards.insert(0, user);
        });
      }),
    );
  }

  void _showEditDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => _EditUserDialog(
        user: user,
        onUpdated: (updated) {
          setState(() {
            final hi = _hosts.indexWhere((u) => u.id == updated.id);
            if (hi >= 0) _hosts[hi] = updated;
            final gi = _guards.indexWhere((u) => u.id == updated.id);
            if (gi >= 0) _guards[gi] = updated;
          });
        },
      ),
    );
  }

  void _showChangePasswordDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => _ChangePasswordDialog(user: user),
    );
  }

  Future<void> _confirmDelete(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User'),
        content: Text(
          'Delete "${user.name}"?\nThis cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await CompanyService().deleteUser(user.id);
      setState(() {
        _hosts.removeWhere((u) => u.id == user.id);
        _guards.removeWhere((u) => u.id == user.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
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
                _UserList(
                  users: _hosts,
                  onRefresh: _load,
                  onEdit: _showEditDialog,
                  onChangePassword: _showChangePasswordDialog,
                  onDelete: _confirmDelete,
                ),
                _UserList(
                  users: _guards,
                  onRefresh: _load,
                  onEdit: _showEditDialog,
                  onChangePassword: _showChangePasswordDialog,
                  onDelete: _confirmDelete,
                ),
              ],
            ),
    );
  }
}

// ── User List ──────────────────────────────────────────────────────────────────

class _UserList extends StatelessWidget {
  final List<UserModel> users;
  final VoidCallback onRefresh;
  final void Function(UserModel) onEdit;
  final void Function(UserModel) onChangePassword;
  final void Function(UserModel) onDelete;

  const _UserList({
    required this.users,
    required this.onRefresh,
    required this.onEdit,
    required this.onChangePassword,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const EmptyWidget(message: 'No users found', icon: Icons.person_off_rounded);
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100, top: 8),
        itemCount: users.length,
        itemBuilder: (context, i) {
          final user = users[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(AppUtils.initials(user.name),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(user.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: user.isActive
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        color: user.isActive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text('${user.email}\n${user.phone}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (action) {
                  if (action == 'edit') onEdit(user);
                  if (action == 'password') onChangePassword(user);
                  if (action == 'delete') onDelete(user);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(
                    leading: Icon(Icons.edit_rounded, color: AppColors.primary),
                    title: Text('Edit Details'), contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'password', child: ListTile(
                    leading: Icon(Icons.lock_reset_rounded, color: AppColors.accent),
                    title: Text('Change Password'), contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'delete', child: ListTile(
                    leading: Icon(Icons.delete_rounded, color: AppColors.error),
                    title: Text('Delete User', style: TextStyle(color: AppColors.error)),
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Add User Dialog ───────────────────────────────────────────────────────────

class _AddUserDialog extends StatefulWidget {
  final void Function(UserModel) onCreated;
  const _AddUserDialog({required this.onCreated});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'host';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = await CompanyService().createUser({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'password': _passCtrl.text,
        'role': _role,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated(user);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add New User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppTextField(label: 'Full Name', controller: _nameCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            AppTextField(label: 'Email', controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
            const SizedBox(height: 12),
            AppTextField(label: 'Phone', controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            AppTextField(label: 'Password', controller: _passCtrl,
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Min 6 chars' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role, // ignore: deprecated_member_use
              decoration: const InputDecoration(
                  labelText: 'Role', filled: true, fillColor: Colors.white),
              items: const [
                DropdownMenuItem(value: 'host', child: Text('Host (Employee)')),
                DropdownMenuItem(value: 'guard', child: Text('Security Guard')),
              ],
              onChanged: (v) => setState(() => _role = v!),
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

// ── Edit User Dialog ──────────────────────────────────────────────────────────

class _EditUserDialog extends StatefulWidget {
  final UserModel user;
  final void Function(UserModel) onUpdated;
  const _EditUserDialog({required this.user, required this.onUpdated});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.user.name);
  late final _phoneCtrl = TextEditingController(text: widget.user.phone);
  late bool _isActive = widget.user.isActive;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updated = await CompanyService().updateUser(widget.user.id, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'isActive': _isActive,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppTextField(label: 'Full Name', controller: _nameCtrl,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            AppTextField(label: 'Phone', controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Account Active',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(_isActive ? 'User can log in' : 'User is blocked',
                  style: TextStyle(
                      fontSize: 12,
                      color: _isActive ? AppColors.success : AppColors.error)),
              value: _isActive,
              activeColor: AppColors.success,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        PrimaryButton(label: 'Save', isLoading: _isLoading, onPressed: _submit),
      ],
    );
  }
}

// ── Change Password Dialog ────────────────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  final UserModel user;
  const _ChangePasswordDialog({required this.user});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await CompanyService().updateUser(widget.user.id, {'password': _passCtrl.text});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Change Password\n${widget.user.name}',
          style: const TextStyle(fontSize: 16)),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AppTextField(
            label: 'New Password',
            controller: _passCtrl,
            obscureText: true,
            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Confirm Password',
            controller: _confirmCtrl,
            obscureText: true,
            validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        PrimaryButton(label: 'Update', isLoading: _isLoading, onPressed: _submit),
      ],
    );
  }
}
