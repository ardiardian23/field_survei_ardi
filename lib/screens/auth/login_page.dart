import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/auth/register_page.dart';
import 'package:flutter_application_2/screens/dashboard/dasboard_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  // ============================================================
  // WARNA
  // ============================================================

  final Color primaryColor = const Color(0xFF4F46E5);
  final Color secondaryColor = const Color(0xFF6366F1);
  final Color backgroundColor = const Color(0xFFF5F7FF);

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://sijala.biz.id/api/v1/login',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      print('STATUS LOGIN: ${response.statusCode}');
      print('RESPONSE LOGIN: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        // ========================================================
        // SIMPAN TOKEN
        // ========================================================

        String? token;

        if (data['token'] != null) {
          token = data['token'].toString();
        } else if (data['access_token'] != null) {
          token = data['access_token'].toString();
        } else if (data['data'] is Map &&
            data['data']['token'] != null) {
          token = data['data']['token'].toString();
        } else if (data['data'] is Map &&
            data['data']['access_token'] != null) {
          token = data['data']['access_token'].toString();
        }

        if (token != null && token.isNotEmpty) {
          await prefs.setString('token', token);

          print('TOKEN BERHASIL DISIMPAN');
        } else {
          print('API TIDAK MENGIRIM TOKEN');
        }

        // ========================================================
        // SIMPAN USER
        // ========================================================

        if (data['user'] != null) {
          await prefs.setString(
            'user',
            jsonEncode(data['user']),
          );
        }

        if (data['data'] is Map &&
            data['data']['user'] != null) {
          await prefs.setString(
            'user',
            jsonEncode(data['data']['user']),
          );
        }

        if (!mounted) return;

        // ========================================================
        // LOGIN BERHASIL
        // ========================================================

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Login berhasil',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // ========================================================
        // MASUK DASHBOARD
        // ========================================================

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardPage(),
          ),
        );
      } else {
        final message =
            data['message'] ?? 'Email atau password salah.';

        throw Exception(message);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

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

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [

                    // ==================================================
                    // ICON
                    // ==================================================

                    Center(
                      child: Container(
                        padding:
                            const EdgeInsets.all(18),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: primaryColor
                                  .withOpacity(0.15),
                              blurRadius: 20,
                              offset:
                                  const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: Icon(
                          Icons.assignment_rounded,
                          size: 60,
                          color: primaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // TITLE
                    // ==================================================

                    Text(
                      'FIELD SURVEY',

                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B4B),
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Selamat Datang!',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ==================================================
                    // CARD LOGIN
                    // ==================================================

                    Card(
                      elevation: 8,

                      shadowColor:
                          Colors.black.withOpacity(0.08),

                      color: Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(24),
                      ),

                      child: Padding(
                        padding:
                            const EdgeInsets.all(28),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,

                          children: [

                            // ==========================================
                            // EMAIL
                            // ==========================================

                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Colors.grey.shade700,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller:
                                  emailController,

                              keyboardType:
                                  TextInputType.emailAddress,

                              style: const TextStyle(
                                fontSize: 15,
                                color:
                                    Color(0xFF1F2937),
                              ),

                              decoration:
                                  InputDecoration(
                                hintText:
                                    'Masukkan email',

                                hintStyle:
                                    TextStyle(
                                  color:
                                      Colors.grey.shade500,
                                  fontSize: 14,
                                ),

                                filled: true,

                                fillColor:
                                    const Color(
                                  0xFFF8F9FC,
                                ),

                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color:
                                      primaryColor,
                                ),

                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 18,
                                  horizontal: 20,
                                ),

                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    30,
                                  ),
                                  borderSide:
                                      BorderSide.none,
                                ),

                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    30,
                                  ),
                                  borderSide:
                                      BorderSide.none,
                                ),

                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    30,
                                  ),
                                  borderSide:
                                      BorderSide(
                                    color:
                                        primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),

                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Email wajib diisi';
                                }

                                if (!value.contains('@')) {
                                  return 'Format email tidak valid';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // ==========================================
                            // PASSWORD
                            // ==========================================

                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Colors.grey.shade700,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller:
                                  passwordController,

                              obscureText:
                                  obscurePassword,

                              style: const TextStyle(
                                fontSize: 15,
                                color:
                                    Color(0xFF1F2937),
                              ),

                              decoration:
                                  InputDecoration(
                                hintText:
                                    'Masukkan password',

                                hintStyle:
                                    TextStyle(
                                  color:
                                      Colors.grey.shade500,
                                  fontSize: 14,
                                ),

                                filled: true,

                                fillColor:
                                    const Color(
                                  0xFFF8F9FC,
                                ),

                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color:
                                      primaryColor,
                                ),

                                suffixIcon:
                                    IconButton(
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons
                                            .visibility_off_outlined,

                                    color:
                                        Colors.grey.shade600,
                                  ),

                                  onPressed: () {
                                    setState(() {
                                      obscurePassword =
                                          !obscurePassword;
                                    });
                                  },
                                ),

                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 18,
                                  horizontal: 20,
                                ),

                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    30,
                                  ),
                                  borderSide:
                                      BorderSide.none,
                                ),

                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    30,
                                  ),
                                  borderSide:
                                      BorderSide.none,
                                ),

                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    30,
                                  ),
                                  borderSide:
                                      BorderSide(
                                    color:
                                        primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),

                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Password wajib diisi';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 28),

                            // ==========================================
                            // LOGIN BUTTON
                            // ==========================================

                            Container(
                              height: 52,

                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                  30,
                                ),

                                gradient:
                                    LinearGradient(
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
                                    color:
                                        primaryColor
                                            .withOpacity(
                                      0.25,
                                    ),
                                    blurRadius: 12,
                                    offset:
                                        const Offset(
                                      0,
                                      5,
                                    ),
                                  ),
                                ],
                              ),

                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : login,

                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      Colors.transparent,

                                  disabledBackgroundColor:
                                      Colors.transparent,

                                  shadowColor:
                                      Colors.transparent,

                                  foregroundColor:
                                      Colors.white,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      30,
                                    ),
                                  ),
                                ),

                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,

                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color:
                                              Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'LOGIN',

                                        style:
                                            TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ==========================================
                            // REGISTER
                            // ==========================================

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,

                              children: [
                                Text(
                                  'Belum punya akun? ',

                                  style: TextStyle(
                                    color:
                                        Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),

                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const RegisterPage(),
                                      ),
                                    );
                                  },

                                  child: Text(
                                    'Daftar',

                                    style: TextStyle(
                                      color:
                                          primaryColor,
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 14,
                                      decoration:
                                          TextDecoration
                                              .underline,
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
      ),
    );
  }
}