import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/company_model.dart';
import '../../models/user_model.dart';
import '../../providers/visitor_provider.dart';
import '../../services/company_service.dart';
import '../../services/visitor_service.dart';

class AddVisitorScreen extends ConsumerStatefulWidget {
  const AddVisitorScreen({super.key});

  @override
  ConsumerState<AddVisitorScreen> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends ConsumerState<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _hostSearchCtrl = TextEditingController();

  CompanyModel? _selectedCompany;
  UserModel? _selectedHost;
  List<CompanyModel> _companies = [];
  List<UserModel> _hosts = [];
  File? _visitorPhoto;
  File? _idProof;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final companies = await CompanyService().getCompanies();
      setState(() {
        _companies = companies;
        if (companies.length == 1) {
          _selectedCompany = companies[0];
          _loadHosts();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHosts([String? query]) async {
    if (_selectedCompany == null) return;
    try {
      final hosts = await CompanyService().searchHosts(_selectedCompany!.id, q: query);
      setState(() => _hosts = hosts);
    } catch (e) {
      setState(() => _hosts = []);
    }
  }

  Future<void> _pickImage(bool isVisitorPhoto) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) {
      setState(() {
        if (isVisitorPhoto) {
          _visitorPhoto = File(picked.path);
        } else {
          _idProof = File(picked.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompany == null) {
      _showError('Please select a company');
      return;
    }
    if (_selectedHost == null) {
      _showError('Please select the host (person to meet)');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await VisitorService().createVisitor(
        companyId: _selectedCompany!.id,
        hostId: _selectedHost!.id,
        visitorName: _nameCtrl.text.trim(),
        visitorPhone: _phoneCtrl.text.trim(),
        visitorEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        purpose: _purposeCtrl.text.trim(),
        visitorPhoto: _visitorPhoto,
        idProof: _idProof,
      );
      ref.read(visitorProvider.notifier).loadVisitors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visitor logged. Approval request sent to host.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Visitor Entry')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(_loadError!, textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadCompanies, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Company & Host'),
                    const SizedBox(height: 12),

                    // Company dropdown
                    DropdownButtonFormField<CompanyModel>(
                      value: _selectedCompany, // ignore: deprecated_member_use
                      decoration: const InputDecoration(
                        labelText: 'Select Company',
                        prefixIcon: Icon(Icons.business_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: _companies.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                      onChanged: (company) {
                        setState(() {
                          _selectedCompany = company;
                          _selectedHost = null;
                          _hosts = [];
                        });
                        _loadHosts();
                      },
                      validator: (v) => v == null ? 'Select a company' : null,
                    ),
                    const SizedBox(height: 16),

                    // Host search
                    AppTextField(
                      label: 'Search Host (Person to Meet)',
                      controller: _hostSearchCtrl,
                      prefixIcon: const Icon(Icons.search_rounded),
                      onChanged: _loadHosts,
                    ),
                    if (_hosts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _hosts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final host = _hosts[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: Text(host.name[0].toUpperCase(),
                                    style: const TextStyle(color: AppColors.primary)),
                              ),
                              title: Text(host.name),
                              subtitle: Text(host.email),
                              selected: _selectedHost?.id == host.id,
                              selectedTileColor: AppColors.primary.withValues(alpha: 0.05),
                              onTap: () {
                                setState(() {
                                  _selectedHost = host;
                                  _hostSearchCtrl.text = host.name;
                                  _hosts = [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    if (_selectedHost != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                            const SizedBox(width: 8),
                            Text('Host: ${_selectedHost!.name} (${_selectedHost!.phone})',
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const _SectionTitle('Visitor Details'),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Full Name',
                      controller: _nameCtrl,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Phone Number',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: (v) => v == null || v.isEmpty ? 'Phone required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email (Optional)',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Purpose of Visit',
                      controller: _purposeCtrl,
                      maxLines: 2,
                      prefixIcon: const Icon(Icons.notes_rounded),
                      validator: (v) => v == null || v.isEmpty ? 'Purpose required' : null,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Photos (Optional)'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _PhotoPicker(
                            label: 'Visitor Photo',
                            icon: Icons.face_rounded,
                            file: _visitorPhoto,
                            onTap: () => _pickImage(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PhotoPicker(
                            label: 'ID Proof',
                            icon: Icons.badge_rounded,
                            file: _idProof,
                            onTap: () => _pickImage(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: 'Log Visitor & Request Approval',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                      icon: Icons.send_rounded,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final File? file;
  final VoidCallback onTap;

  const _PhotoPicker({required this.label, required this.icon, this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? AppColors.success : AppColors.divider,
            width: file != null ? 2 : 1,
          ),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(file!, fit: BoxFit.cover, width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.textSecondary, size: 28),
                  const SizedBox(height: 6),
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                ],
              ),
      ),
    );
  }
}
