import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/audit_service.dart';
import '../shared/ticket_card.dart';
import '../shared/ios_glass_dropdown.dart';
import '../../utils/app_notifications.dart';
import '../../utils/app_colors.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _roles = ['student', 'staff', 'technician', 'admin'];
  String? _selectedFilterRole; // null means 'All'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _deleteUser(String uid, String name) async {
    try {
      await _firestore.collection('users').doc(uid).delete();

      await AuditService().logAction(
        actionType: 'DELETE_USER',
        targetId: uid,
        description: 'Menghapus pengguna $name',
      );

      if (!mounted) return;
      AppNotifications.showNotification(
        context,
        title: 'Sukses',
        message: 'Pengguna "$name" berhasil dihapus',
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

  void _showDeleteConfirmationDialog(UserModel user) async {
    final confirm = await AppNotifications.showConfirmDialog(
      context,
      title: 'Hapus Pengguna?',
      message: 'Akun "${user.name}" akan dihapus secara permanen dari sistem.\n\nTindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDestructive: true,
    );
    if (confirm == true) {
      _deleteUser(user.uid, user.name);
    }
  }

  Future<void> _updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': newRole});
      if (!mounted) return;
      AppNotifications.showNotification(
        context,
        title: 'Sukses',
        message: 'Peran pengguna berhasil diperbarui',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showNotification(
        context,
        title: 'Gagal',
        message: 'Gagal memperbarui peran: $e',
        isError: true,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showConfirmationDialog(UserModel user, String newRole) async {
    final confirm = await AppNotifications.showConfirmDialog(
      context,
      title: 'Ubah Peran?',
      message: 'Anda yakin ingin mengubah peran ${user.name} menjadi ${newRole.toUpperCase()}?',
      confirmLabel: 'Ubah',
      cancelLabel: 'Batal',
      isDestructive: false,
    );
    if (confirm == true) {
      _updateUserRole(user.uid, newRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: 'Manajemen Pengguna',
      ),
      body: Column(
        children: [
          // ── Search Bar Section ─────────────────────────────────────────
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari nama pengguna...',
                hintStyle: TextStyle(
                    color: c.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded,
                    color: c.textMuted, size: 20),
                suffixIcon: Icon(Icons.tune_rounded,
                    color: c.textMuted, size: 20),
                filled: true,
                fillColor: c.searchBar,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // ── Filter Section ─────────────────────────────────────────────
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip(null, 'Semua', c),
                  const SizedBox(width: 8),
                  _buildFilterChip('student', 'Mahasiswa', c),
                  const SizedBox(width: 8),
                  _buildFilterChip('staff', 'Dosen/Staff', c),
                  const SizedBox(width: 8),
                  _buildFilterChip('technician', 'Teknisi', c),
                  const SizedBox(width: 8),
                  _buildFilterChip('admin', 'Admin', c),
                ],
              ),
            ),
          ),

          // ── User List ──────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: c.primary),
                  );
                }
                if (snapshot.hasError) {
                  return _emptyState(
                    Icons.error_outline,
                    'Terjadi kesalahan memuat data.',
                    c,
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _emptyState(
                    Icons.people_alt_outlined,
                    'Tidak ada pengguna terdaftar.',
                    c,
                  );
                }

                final allUsers = snapshot.data!.docs.map((doc) {
                  return UserModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                final filteredUsers = allUsers.where((u) {
                  final matchesRole =
                      _selectedFilterRole == null ||
                      u.role == _selectedFilterRole;
                  final matchesName = u.name.toLowerCase().contains(
                    _searchQuery,
                  );
                  return matchesRole && matchesName;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return _emptyState(
                    Icons.person_search_rounded,
                    _searchQuery.isEmpty
                        ? 'Tidak ada pengguna dengan peran ini.'
                        : 'Tidak ada hasil untuk "$_searchQuery"',
                    c,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
                        boxShadow: [
                          BoxShadow(
                            color: c.isDark ? Colors.transparent : Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: c.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: c.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name.isNotEmpty
                                          ? user.name
                                          : 'Tanpa Nama',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.email.isNotEmpty
                                          ? user.email
                                          : user.phoneNumber,
                                      style: TextStyle(
                                        color: c.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (user.department.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        user.department,
                                        style: TextStyle(
                                          color: c.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: c.divider, height: 1),
                          ),
                          Text(
                            'Peran Akses',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: c.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: IosGlassDropdown<String>(
                                  value: _roles.contains(user.role) ? user.role : 'student',
                                  items: _roles,
                                  itemLabelBuilder: (r) => r.toUpperCase(),
                                  onChanged: (newRole) {
                                    _showConfirmationDialog(user, newRole);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Tombol Login Sebagai (Impersonation)
                              GestureDetector(
                                onTap: () async {
                                  final auth = context.read<AuthProvider>();
                                  if (user.uid == auth.user?.uid) return;
                                  
                                  final confirm = await AppNotifications.showConfirmDialog(
                                    context,
                                    title: 'Login Sebagai',
                                    message: 'Anda akan masuk sebagai ${user.name}. Sesi Anda sebagai Admin akan tetap terjaga.',
                                    confirmLabel: 'Lanjutkan',
                                    cancelLabel: 'Batal',
                                    isDestructive: false,
                                  );

                                  if (confirm == true) {
                                    await AuditService().logAction(
                                      actionType: 'USER_IMPERSONATION',
                                      targetId: user.uid,
                                      description: 'Memulai sesi impersonasi sebagai ${user.name} (${user.role})',
                                    );
                                    auth.impersonateUser(user);
                                    Navigator.pop(context); // Kembali ke dashboard
                                  }
                                },
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: c.primary.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: c.primary.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.login_rounded, size: 16, color: c.primary),
                                      const SizedBox(width: 6),
                                      Text('Login', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c.primary)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Tombol Hapus Pengguna
                              GestureDetector(
                                onTap: () => _showDeleteConfirmationDialog(user),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: c.isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: c.isDark ? Colors.red.withOpacity(0.3) : Colors.red.shade200),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: c.isDark ? Colors.redAccent.shade100 : Colors.red.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildFilterChip(String? role, String label, AppColors c) {
    bool isSelected = _selectedFilterRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.chipSelected : c.chipUnselected,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? c.chipSelected
                : c.chipBorder,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _emptyState(IconData icon, String message, AppColors c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: c.textMuted),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: c.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
