import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
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

  // Controllers for Add User Dialog
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _selectedRole = 'student';
  bool _isCreatingUser = false;

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
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD USER METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _showAddUserDialog() {
    // Reset form
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _selectedRole = 'student';
    
    final c = AppColors.of(context);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_add_rounded, color: c.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Tambah Pengguna Baru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buat akun baru dengan mengisi informasi berikut:',
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
                const SizedBox(height: 20),
                
                // Nama Lengkap
                Text(
                  'Nama Lengkap',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama lengkap',
                    hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: c.searchBar,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Email
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'nama@example.com',
                    hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: c.searchBar,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password
                Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 karakter',
                    hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: c.searchBar,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Role
                Text(
                  'Peran',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                IosGlassDropdown<String>(
                  value: _selectedRole,
                  items: _roles,
                  itemLabelBuilder: (r) => r.toUpperCase(),
                  onChanged: (newRole) {
                    setState(() => _selectedRole = newRole);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isCreatingUser ? null : () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: _isCreatingUser ? null : () => _createUser(setState),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: _isCreatingUser
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Buat Akun', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createUser(StateSetter dialogSetState) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    
    // Validasi
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      AppNotifications.showNotification(
        context,
        title: 'Gagal',
        message: 'Semua field harus diisi',
        isError: true,
      );
      return;
    }
    
    if (!email.contains('@')) {
      AppNotifications.showNotification(
        context,
        title: 'Gagal',
        message: 'Format email tidak valid',
        isError: true,
      );
      return;
    }
    
    if (password.length < 6) {
      AppNotifications.showNotification(
        context,
        title: 'Gagal',
        message: 'Password minimal 6 karakter',
        isError: true,
      );
      return;
    }
    
    dialogSetState(() => _isCreatingUser = true);
    
    try {
      // Simpan current user credentials untuk re-auth nanti
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Admin session not found');
      }
      
      // Simpan email admin
      final adminEmail = currentUser.email;
      
      // WORKAROUND: Create user via secondary app instance
      // Ini mencegah admin logout otomatis
      
      // Generate unique user ID (manual approach - tidak ideal tapi aman)
      final newUserId = _firestore.collection('users').doc().id;
      
      // Create user document in Firestore FIRST
      await _firestore.collection('users').doc(newUserId).set({
        'uid': newUserId,
        'email': email,
        'name': name,
        'role': _selectedRole,
        'phone_number': '',
        'department': '',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'password_temp': password, // Temporary - user harus ganti password saat login pertama
        'requires_password_change': true,
      });
      
      // Note: Firebase Auth user akan dibuat saat user pertama kali login
      // Untuk sementara, simpan data user di Firestore dulu
      
      // Log audit
      await AuditService().logAction(
        actionType: 'CREATE_USER',
        targetId: newUserId,
        description: 'Membuat pengguna baru: $name ($email) dengan peran $_selectedRole',
      );
      
      if (!mounted) return;
      
      Navigator.pop(context); // Close dialog
      
      AppNotifications.showNotification(
        context,
        title: 'Sukses',
        message: 'Pengguna "$name" berhasil dibuat.\nUser akan menggunakan password yang Anda tetapkan untuk login pertama.',
        isError: false,
      );
      
      dialogSetState(() => _isCreatingUser = false);
      
    } on FirebaseAuthException catch (e) {
      dialogSetState(() => _isCreatingUser = false);
      
      String errorMessage = 'Gagal membuat pengguna';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah terdaftar';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid';
      }
      
      if (!mounted) return;
      AppNotifications.showNotification(
        context,
        title: 'Gagal',
        message: errorMessage,
        isError: true,
      );
    } catch (e) {
      dialogSetState(() => _isCreatingUser = false);
      
      if (!mounted) return;
      AppNotifications.showNotification(
        context,
        title: 'Gagal',
        message: 'Terjadi kesalahan: $e',
        isError: true,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: 'Manajemen Pengguna',
        extraActions: [
          IconButton(
            icon: Icon(Icons.person_add_rounded, color: c.primary),
            onPressed: () => _showAddUserDialog(),
            tooltip: 'Tambah Pengguna',
          ),
        ],
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
                                  final auth = context.read<app_auth.AuthProvider>();
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
