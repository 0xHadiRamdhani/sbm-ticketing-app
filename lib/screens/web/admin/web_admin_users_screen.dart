import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_notifications.dart';
import '../../../services/audit_service.dart';

class WebAdminUsersScreen extends StatefulWidget {
  const WebAdminUsersScreen({Key? key}) : super(key: key);
  @override
  State<WebAdminUsersScreen> createState() => _WebAdminUsersScreenState();
}

class _WebAdminUsersScreenState extends State<WebAdminUsersScreen> {
  String? _selectedRole;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _selectedNewRole = 'student';
  bool _isCreatingUser = false;

  final _roles = ['admin', 'technician', 'staff', 'student'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: const Color(0xFF3B82F6), strokeWidth: 2.5));
          }
          final allUsers = snap.data!.docs
              .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList();
          final filtered = _filterUsers(allUsers);
          return Column(
            children: [
              _buildHeader(c, allUsers),
              _buildFilterBar(c),
              _buildStatsBar(allUsers, c),
              Expanded(child: filtered.isEmpty ? _buildEmpty(c) : _buildTable(filtered, c)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppColors c, List<UserModel> users) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
      decoration: BoxDecoration(color: c.surface, border: Border(bottom: BorderSide(color: c.border.withOpacity(0.6)))),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Manajemen Pengguna', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c.textPrimary, letterSpacing: -0.5)),
            Text('${users.length} akun terdaftar dalam sistem', style: TextStyle(fontSize: 13, color: c.textSecondary)),
          ]),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Tambah Pengguna'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: c.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: TextStyle(fontSize: 13, color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari nama atau email...',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: c.textMuted, size: 19),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: Icon(Icons.close_rounded, size: 16, color: c.textMuted),
                        onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                    : null,
                filled: true, fillColor: c.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ...['Semua', ..._roles].map((role) {
            final isAll = role == 'Semua';
            final sel = isAll ? _selectedRole == null : _selectedRole == role;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_roleLabel(role)),
                selected: sel,
                onSelected: (_) => setState(() => _selectedRole = isAll ? null : role),
                backgroundColor: c.surface,
                selectedColor: const Color(0xFF1D4ED8).withOpacity(0.12),
                checkmarkColor: const Color(0xFF1D4ED8),
                side: BorderSide(color: sel ? const Color(0xFF1D4ED8) : c.border),
                labelStyle: TextStyle(fontSize: 12, color: sel ? const Color(0xFF1D4ED8) : c.textSecondary, fontWeight: sel ? FontWeight.bold : FontWeight.normal),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatsBar(List<UserModel> users, AppColors c) {
    final stats = {
      'Admin': [users.where((u) => u.role == 'admin').length, const Color(0xFF1D4ED8)],
      'Teknisi': [users.where((u) => u.role == 'technician').length, const Color(0xFF3B82F6)],
      'Staff/Dosen': [users.where((u) => u.role == 'staff').length, const Color(0xFF10B981)],
      'Mahasiswa': [users.where((u) => u.role == 'student').length, const Color(0xFFF59E0B)],
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(color: c.surface, border: Border(bottom: BorderSide(color: c.border.withOpacity(0.5)))),
      child: Wrap(
        spacing: 12, runSpacing: 8,
        children: stats.entries.map((e) {
          final col = e.value[1] as Color;
          final cnt = e.value[0] as int;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: col.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withOpacity(0.25))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('${e.key}: ', style: TextStyle(fontSize: 14, color: col)),
              Text('$cnt', style: TextStyle(fontSize: 14, color: col, fontWeight: FontWeight.bold)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTable(List<UserModel> users, AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(c.isDark ? 0.15 : 0.04), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: c.isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: c.divider)),
              ),
              child: Row(children: [
                _H('#', width: 40),
                _H('Pengguna', flex: 4),
                _H('Email', flex: 4),
                _H('Peran', flex: 2),
                _H('Departemen', flex: 3),
                _H('Aksi', width: 80),
              ]),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (ctx, i) => _UserRow(
                user: users[i], index: i, isLast: i == users.length - 1,
                onDelete: () => _confirmDelete(users[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppColors c) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.08), shape: BoxShape.circle),
      child: const Icon(Icons.people_outline_rounded, size: 52, color: Color(0xFF3B82F6))),
    const SizedBox(height: 18),
    Text('Tidak ada pengguna ditemukan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
    const SizedBox(height: 6),
    Text('Coba ubah filter atau tambah pengguna baru', style: TextStyle(fontSize: 13, color: c.textSecondary)),
  ]));

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((u) {
      if (_selectedRole != null && u.role != _selectedRole) return false;
      if (_searchQuery.isNotEmpty) {
        return u.name.toLowerCase().contains(_searchQuery) || u.email.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'Admin';
      case 'technician': return 'Teknisi';
      case 'staff': return 'Staff/Dosen';
      case 'student': return 'Mahasiswa';
      case 'Semua': return 'Semua';
      default: return role;
    }
  }

  void _showAddDialog() {
    _emailCtrl.clear(); _passwordCtrl.clear(); _nameCtrl.clear();
    _selectedNewRole = 'student';
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF1D4ED8).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_add_rounded, color: Color(0xFF1D4ED8), size: 24)),
          const SizedBox(width: 12),
          Text('Tambah Pengguna Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
        ]),
        content: SingleChildScrollView(child: SizedBox(width: 420, child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Isi informasi berikut untuk membuat akun baru.', style: TextStyle(fontSize: 13, color: c.textSecondary)),
            const SizedBox(height: 20),
            _DialogField(label: 'Nama Lengkap', ctrl: _nameCtrl, hint: 'Masukkan nama lengkap', c: c),
            const SizedBox(height: 14),
            _DialogField(label: 'Email', ctrl: _emailCtrl, hint: 'nama@example.com', type: TextInputType.emailAddress, c: c),
            const SizedBox(height: 14),
            _DialogField(label: 'Password', ctrl: _passwordCtrl, hint: 'Min. 6 karakter', obscure: true, c: c),
            const SizedBox(height: 14),
            Text('Peran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: c.searchBar, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                isExpanded: true, dropdownColor: c.surface, value: _selectedNewRole,
                icon: Icon(Icons.keyboard_arrow_down, color: c.textSecondary),
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(_roleLabel(r), style: TextStyle(color: c.textPrimary)))).toList(),
                onChanged: (v) { if (v != null) setState(() => _selectedNewRole = v); },
              )),
            ),
          ],
        ))),
        actions: [
          TextButton(onPressed: _isCreatingUser ? null : () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: c.textSecondary))),
          ElevatedButton(
            onPressed: _isCreatingUser ? null : () => _createUser(setState),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            child: _isCreatingUser
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Buat Akun', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      )),
    );
  }

  Future<void> _createUser(StateSetter dialogSetState) async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      AppNotifications.showNotification(context, title: 'Gagal', message: 'Semua field wajib diisi', isError: true); return;
    }
    if (!email.contains('@')) {
      AppNotifications.showNotification(context, title: 'Gagal', message: 'Format email tidak valid', isError: true); return;
    }
    if (password.length < 6) {
      AppNotifications.showNotification(context, title: 'Gagal', message: 'Password minimal 6 karakter', isError: true); return;
    }
    dialogSetState(() => _isCreatingUser = true);
    try {
      final newId = FirebaseFirestore.instance.collection('users').doc().id;
      await FirebaseFirestore.instance.collection('users').doc(newId).set({
        'uid': newId, 'email': email, 'name': name, 'role': _selectedNewRole,
        'phone_number': '', 'department': '',
        'created_at': FieldValue.serverTimestamp(), 'updated_at': FieldValue.serverTimestamp(),
        'password_temp': password, 'requires_password_change': true,
      });
      await AuditService().logAction(actionType: 'CREATE_USER', targetId: newId,
        description: 'Membuat pengguna baru: $name ($email) — $_selectedNewRole');
      if (!mounted) return;
      Navigator.pop(context);
      AppNotifications.showNotification(context, title: 'Sukses', message: 'Pengguna "$name" berhasil dibuat.', isError: false);
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showNotification(context, title: 'Gagal', message: 'Terjadi kesalahan: $e', isError: true);
    } finally {
      dialogSetState(() => _isCreatingUser = false);
    }
  }

  Future<void> _confirmDelete(UserModel user) async {
    final confirmed = await AppNotifications.showConfirmDialog(context,
      title: 'Hapus Pengguna?',
      message: 'Akun "${user.name}" akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'Hapus', cancelLabel: 'Batal', isDestructive: true);
    if (confirmed) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        if (!mounted) return;
        AppNotifications.showNotification(context, title: 'Sukses', message: 'Pengguna berhasil dihapus', isError: false);
      } catch (e) {
        if (!mounted) return;
        AppNotifications.showNotification(context, title: 'Gagal', message: 'Gagal menghapus: $e', isError: true);
      }
    }
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _H extends StatelessWidget {
  final String label;
  final int? flex;
  final double? width;
  const _H(this.label, {this.flex, this.width});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final child = Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textMuted, letterSpacing: 0.3));
    return width != null ? SizedBox(width: width, child: child) : Expanded(flex: flex ?? 1, child: child);
  }
}

class _UserRow extends StatefulWidget {
  final UserModel user;
  final int index;
  final bool isLast;
  final VoidCallback onDelete;
  const _UserRow({required this.user, required this.index, required this.isLast, required this.onDelete});
  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final roleColors = {'admin': const Color(0xFF1D4ED8), 'technician': const Color(0xFF3B82F6), 'staff': const Color(0xFF10B981), 'student': const Color(0xFFF59E0B)};
    final col = roleColors[widget.user.role] ?? c.textMuted;
    final roleLbls = {'admin': 'Admin', 'technician': 'Teknisi', 'staff': 'Staff/Dosen', 'student': 'Mahasiswa'};
    final roleLabel = roleLbls[widget.user.role] ?? widget.user.role;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFF3B82F6).withOpacity(0.03) : Colors.transparent,
          border: Border(bottom: widget.isLast ? BorderSide.none : BorderSide(color: c.divider.withOpacity(0.5))),
          borderRadius: widget.isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : null,
        ),
        child: Row(children: [
          SizedBox(width: 40, child: Text('${widget.index + 1}', style: TextStyle(fontSize: 14, color: c.textMuted))),
          Expanded(flex: 4, child: Row(children: [
            CircleAvatar(radius: 20, backgroundColor: col.withOpacity(0.15),
              child: Text(widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: col))),
            const SizedBox(width: 14),
            Expanded(child: Text(widget.user.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ])),
          Expanded(flex: 4, child: Text(widget.user.email, style: TextStyle(fontSize: 15, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withOpacity(0.3))),
            child: Text(roleLabel, style: TextStyle(fontSize: 13, color: col, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Expanded(flex: 3, child: Text(widget.user.department.isNotEmpty ? widget.user.department : '-',
            style: TextStyle(fontSize: 15, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: Icon(Icons.delete_outline_rounded, size: 20, color: _hovered ? Colors.red : c.textMuted),
              onPressed: widget.onDelete, tooltip: 'Hapus', splashRadius: 20),
          ])),
        ]),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final TextInputType type;
  final bool obscure;
  final AppColors c;
  const _DialogField({required this.label, required this.ctrl, required this.hint, required this.c, this.type = TextInputType.text, this.obscure = false});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, keyboardType: type, obscureText: obscure, style: TextStyle(color: c.textPrimary),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: c.textMuted, fontSize: 13), filled: true, fillColor: c.searchBar,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
    ]);
  }
}
