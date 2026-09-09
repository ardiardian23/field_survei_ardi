import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedGender = 'L';
  bool _isLoading = false;

  // WARNA UTAMA
  final Color primaryColor = const Color(0xFF4F46E5);
  final Color secondaryColor = const Color(0xFF6366F1);
  final Color backgroundColor = const Color(0xFFF5F7FF);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // FUNGSI REGISTER
  // ============================================================
  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showSnackBar(
        'Harap isi semua kolom formulir!',
        Colors.redAccent,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final Uri url = Uri.parse(
      'https://sijala.biz.id/api/v1/register',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'gender': _selectedGender,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        _showSnackBar(
          'Pendaftaran berhasil! Silakan login.',
          Colors.green,
        );

        context.pop();
      } else {
        String errorMsg =
            data['message'] ?? 'Pendaftaran gagal!';

        if (data['errors'] != null) {
          final Map<String, dynamic> errors = data['errors'];

          final firstKey = errors.keys.first;

          errorMsg = errors[firstKey][0];
        }

        _showSnackBar(
          errorMsg,
          Colors.redAccent,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      _showSnackBar(
        'Kesalahan koneksi ke server.',
        Colors.redAccent,
      );
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================
  void _showSnackBar(
    String message,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FF),
              Color(0xFFEFF1FF),
            ],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // ==================================================
                  // HEADER
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,

                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),

                    child: Icon(
                      Icons.assignment_rounded,
                      size: 56,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Buat Akun Baru',

                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1B4B),
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Isi data diri untuk mendaftar akun',

                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ==================================================
                  // CARD FORM
                  // ==================================================

                  Card(
                    elevation: 8,

                    shadowColor:
                        Colors.black.withOpacity(0.08),

                    color: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(24),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(28),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,

                        children: [

                          // ================================
                          // NAMA
                          // ================================

                          _buildTextField(
                            controller: _nameController,
                            hintText: 'Nama Lengkap',
                            icon: Icons.person_outline,
                            primaryColor: primaryColor,
                          ),

                          const SizedBox(height: 16),

                          // ================================
                          // EMAIL
                          // ================================

                          _buildTextField(
                            controller: _emailController,
                            hintText: 'Alamat Email',
                            icon: Icons.email_outlined,
                            keyboardType:
                                TextInputType.emailAddress,
                            primaryColor: primaryColor,
                          ),

                          const SizedBox(height: 16),

                          // ================================
                          // PHONE
                          // ================================

                          _buildTextField(
                            controller: _phoneController,
                            hintText: 'Nomor Handphone',
                            icon: Icons.phone_outlined,
                            keyboardType:
                                TextInputType.phone,
                            primaryColor: primaryColor,
                          ),

                          const SizedBox(height: 16),

                          // ================================
                          // JENIS KELAMIN
                          // ================================

                          DropdownButtonFormField<String>(
                            value: _selectedGender,

                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                            ),

                            decoration: InputDecoration(
                              filled: true,

                              fillColor:
                                  const Color(0xFFF8F9FC),

                              prefixIcon: Icon(
                                Icons.people_outline,
                                color: primaryColor,
                              ),

                              contentPadding:
                                  const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 20,
                              ),

                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                                borderSide:
                                    BorderSide.none,
                              ),

                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                                borderSide:
                                    BorderSide.none,
                              ),

                              focusedBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                              ),
                            ),

                            items: const [
                              DropdownMenuItem(
                                value: 'L',
                                child: Text('Laki-Laki'),
                              ),

                              DropdownMenuItem(
                                value: 'P',
                                child: Text('Perempuan'),
                              ),
                            ],

                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 28),

                          // ==================================================
                          // TOMBOL DAFTAR
                          // ==================================================

                          Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(30),

                              gradient: LinearGradient(
                                begin:
                                    Alignment.centerLeft,
                                end:
                                    Alignment.centerRight,

                                colors: [
                                  primaryColor,
                                  secondaryColor,
                                ],
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor
                                      .withOpacity(0.25),

                                  spreadRadius: 1,

                                  blurRadius: 12,

                                  offset:
                                      const Offset(0, 5),
                                ),
                              ],
                            ),

                            child: ElevatedButton(
                              onPressed:
                                  _isLoading
                                      ? null
                                      : _handleRegister,

                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.transparent,

                                disabledBackgroundColor:
                                    Colors.transparent,

                                shadowColor:
                                    Colors.transparent,

                                foregroundColor:
                                    Colors.white,

                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(30),
                                ),
                              ),

                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,

                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'DAFTAR',

                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // KEMBALI KE LOGIN
                          // ==================================================

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,

                            children: [
                              Text(
                                'Sudah memiliki akun? ',

                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),

                              GestureDetector(
                                onTap: () => context.pop(),

                                child: Text(
                                  'Masuk',

                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 14,
                                    decoration:
                                        TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color primaryColor,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,

      keyboardType: keyboardType,

      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1F2937),
      ),

      decoration: InputDecoration(
        filled: true,

        fillColor:
            const Color(0xFFF8F9FC),

        hintText: hintText,

        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),

        prefixIcon: Icon(
          icon,
          color: primaryColor,
        ),

        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(30),

          borderSide:
              BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(30),

          borderSide:
              BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(30),

          borderSide: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}