import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controller tambahan untuk Register
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  String _selectedRole = 'student';

  final _formKey = GlobalKey<FormState>();

  bool _isObscure = true;
  bool _isLogin = true; // Mode saklar: Login atau Register

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        if (_isLogin) {
          // Mode Login
          await authProvider.login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        } else {
          // Mode Register
          await authProvider.register(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
            _selectedRole,
            _departmentController.text.trim(),
          );
        }
        // Jika sukses, auth wrapper otomatis memindahkan ke halaman dashboard yang benar
      } catch (e) {
        if (!mounted) return;
        String msg = e.toString();
        // Bersihkan pesan error khas firebase jika ada
        if (msg.contains(']')) {
          msg = msg.split(']').last.trim();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/sbm.png', height: 200),
                  SizedBox(height: 16),
                  Text(
                    'SBM ITB Ticketing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Masuk dengan akun Anda' : 'Daftarkan akun baru',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 32),

                  // Hanya dimunculkan saat Register
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline),

                      ),
                      validator: (val) =>
                          val!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Peran / Role',
                        prefixIcon: Icon(Icons.badge_outlined),

                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Mahasiswa'),
                        ),
                        DropdownMenuItem(
                          value: 'staff',
                          child: Text('Staf / Dosen'),
                        ),
                        DropdownMenuItem(
                          value: 'technician',
                          child: Text('Teknisi IT'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedRole = val!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _departmentController,
                      decoration: InputDecoration(
                        labelText: 'Departemen/Angkatan (Opsional)',
                        prefixIcon: Icon(Icons.apartment_outlined),

                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email (@itb.ac.id / @sbm-itb.ac.id)',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!val.endsWith('@itb.ac.id') &&
                          !val.endsWith('@sbm-itb.ac.id')) {
                        return 'Hanya gunakan domain email institusi';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi',
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return 'Kata sandi bebas, tidak boleh kosong';
                      if (!_isLogin && val.length < 6)
                        return 'Sandi minimal 6 karakter';
                      return null;
                    },
                  ),
                  SizedBox(height: 32),

                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),

                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                        ),
                        child: auth.isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isLogin ? 'Masuk' : 'Daftar Sekarang',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),

                  SizedBox(height: 16),
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _isLogin
                          ? 'Belum punya akun? Daftar di sini.'
                          : 'Sudah punya akun? Masuk di sini.',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
