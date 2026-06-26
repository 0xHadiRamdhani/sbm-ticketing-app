import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_notifications.dart';

/// Web Admin Users Screen - User management with CRUD operations
class WebAdminUsersScreen extends StatefulWidget {
  const WebAdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<WebAdminUsersScreen> createState() => _WebAdminUsersScreenState();
}

class _WebAdminUsersScreenState extends State<WebAdminUsersScreen> {
  String? _selectedRole;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final _roles = ['admin', 'technician', 'staff', 'student'];

  @override
  void dispose() {
    _searchCtrl.dispose();
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: TextStyle(color: c.textSecondary),
              ),
            );
          }

          final allUsers = snap.data!.docs
              .map((doc) => UserModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          final filteredUsers = _filterUsers(allUsers);

          return Column(
            children: [
              _buildHeader(c, allUsers),
              _buildFilterBar(c),
              _buildStatsBar(allUsers, c),
              Expanded(
                child: filteredUsers.isEmpty
                    ? _buildEmptyState(c)
                    : _buildUsersList(filteredUsers, c),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppColors c, List<UserModel> users) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manajemen Pengguna',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${users.length} pengguna terdaftar',
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddUserDialog(),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Tambah Pengguna'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A5C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: TextStyle(fontSize: 14, color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari pengguna (nama, email)...',
                hintStyle: TextStyle(color: c.textMuted),
                prefixIcon: Icon(Icons.search, color: c.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 18, color: c.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: c.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Role filter chips
          ...['Semua', ..._roles].map((role) {
            final isAll = role == 'Semua';
            final selected = isAll
                ? _selectedRole == null
                : _selectedRole == role;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text(_getRoleLabel(role)),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    _selectedRole = isAll ? null : role;
                  });
                },
                backgroundColor: c.background,
                selectedColor: c.primary.withOpacity(0.1),
                checkmarkColor: c.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: selected ? c.primary : c.textSecondary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: selected ? c.primary : c.border,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatsBar(List<UserModel> users, AppColors c) {
    final adminCount = users.where((u) => u.role == 'admin').length;
    final technicianCount = users.where((u) => u.role == 'technician').length;
    final staffCount = users.where((u) => u.role == 'staff').length;
    final studentCount = users.where((u) => u.role == 'student').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1A2332) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _StatChip(
            label: 'Admin',
            count: adminCount,
            color: const Color(0xFF1A3A5C),
          ),
          _StatChip(
            label: 'Teknisi',
            count: technicianCount,
            color: const Color(0xFF2196F3),
          ),
          _StatChip(
            label: 'Staff/Dosen',
            count: staffCount,
            color: const Color(0xFF66BB6A),
          ),
          _StatChip(
            label: 'Mahasiswa',
            count: studentCount,
            color: const Color(0xFFFFA726),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<UserModel> users, AppColors c) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 300));
      },
      color: c.primary,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(c.isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.divider)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        '#',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Nama',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Role',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Departemen',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Aksi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Table Body
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserListItem(
                    user: user,
                    index: index,
                    onEdit: () => _showEditUserDialog(user),
                    onDelete: () => _confirmDeleteUser(user),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: c.textMuted),
          const SizedBox(height: 16),
          Text(
            'Tidak ada pengguna ditemukan',
            style: TextStyle(fontSize: 16, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((u) {
      // Role filter
      if (_selectedRole != null && u.role != _selectedRole) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        return u.name.toLowerCase().contains(_searchQuery) ||
            u.email.toLowerCase().contains(_searchQuery) ||
            u.department.toLowerCase().contains(_searchQuery);
      }

      return true;
    }).toList();
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'technician':
        return 'Teknisi';
      case 'staff':
        return 'Staff/Dosen';
      case 'student':
        return 'Mahasiswa';
      case 'Semua':
        return 'Semua';
      default:
        return role;
    }
  }

  void _showAddUserDialog() {
    // TODO: Implement add user dialog
    AppNotifications.showNotification(
      context,
      title: 'Coming Soon',
      message: 'Fitur tambah pengguna akan segera hadir',
      isError: false,
    );
  }

  void _showEditUserDialog(UserModel user) {
    // TODO: Implement edit user dialog
    AppNotifications.showNotification(
      context,
      title: 'Edit User',
      message: 'Mengedit ${user.name}',
      isError: false,
    );
  }

  Future<void> _confirmDeleteUser(UserModel user) async {
    final confirmed = await AppNotifications.showConfirmDialog(
      context,
      title: 'Hapus Pengguna?',
      message: 'Apakah Anda yakin ingin menghapus ${user.name}? Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        if (!mounted) return;
        AppNotifications.showNotification(
          context,
          title: 'Sukses',
          message: 'Pengguna berhasil dihapus',
          isError: false,
        );
      } catch (e) {
        if (!mounted) return;
        AppNotifications.showNotification(
          context,
          title: 'Gagal',
          message: 'Gagal menghapus pengguna: $e',
          isError: true,
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: color),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListItem extends StatefulWidget {
  final UserModel user;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserListItem({
    required this.user,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    Color roleColor;
    IconData roleIcon;
    switch (widget.user.role) {
      case 'admin':
        roleColor = const Color(0xFF1A3A5C);
        roleIcon = Icons.shield_outlined;
        break;
      case 'technician':
        roleColor = const Color(0xFF2196F3);
        roleIcon = Icons.build_circle_outlined;
        break;
      case 'staff':
        roleColor = const Color(0xFF66BB6A);
        roleIcon = Icons.school_outlined;
        break;
      case 'student':
        roleColor = const Color(0xFFFFA726);
        roleIcon = Icons.person_outline;
        break;
      default:
        roleColor = c.textMuted;
        roleIcon = Icons.help_outline;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _isHovered ? c.primary.withOpacity(0.05) : Colors.transparent,
          border: Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            // Index
            SizedBox(
              width: 50,
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  fontSize: 13,
                  color: c.textMuted,
                ),
              ),
            ),

            // Name with Avatar
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: roleColor.withOpacity(0.1),
                    child: Text(
                      widget.user.name.isNotEmpty
                          ? widget.user.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.user.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Email
            Expanded(
              flex: 3,
              child: Text(
                widget.user.email,
                style: TextStyle(
                  fontSize: 13,
                  color: c.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Role Badge
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: roleColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, size: 12, color: roleColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _getRoleLabel(widget.user.role),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: roleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Department
            Expanded(
              flex: 2,
              child: Text(
                widget.user.department.isNotEmpty 
                    ? widget.user.department 
                    : '-',
                style: TextStyle(
                  fontSize: 13,
                  color: c.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Actions
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: _isHovered ? c.primary : c.textMuted,
                    ),
                    onPressed: widget.onEdit,
                    tooltip: 'Edit',
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: _isHovered ? Colors.red : c.textMuted,
                    ),
                    onPressed: widget.onDelete,
                    tooltip: 'Hapus',
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'technician':
        return 'Teknisi';
      case 'staff':
        return 'Staff/Dosen';
      case 'student':
        return 'Mahasiswa';
      default:
        return role;
    }
  }
}
