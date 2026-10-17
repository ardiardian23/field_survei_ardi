
import 'package:flutter/material.dart';
import 'package:flutter_application_2/profile/profile_page.dart';
import 'package:flutter_application_2/screens/dashboard/survey_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentIndex = 0;

  String? token;
  bool isLoadingToken = true;

  static const primary = Color(0xFF4F46E5);

  @override
  void initState() {
    super.initState();
    getToken();
  }

  // AMBIL TOKEN
  Future<void> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      token = prefs.getString('token');
      isLoadingToken = false;
    });

    debugPrint('TOKEN DASHBOARD: $token');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingToken) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),

      body: IndexedStack(
        index: currentIndex,
        children: [
          const HomePage(),
          const SurveyScreen(),

          if (token != null && token!.isNotEmpty)
            ProfilePage(token: token!)
          else
            const Center(
              child: Text(
                'Token tidak ditemukan',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Survey',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME PAGE / DASHBOARD STATIS
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const primary = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),

      // APP BAR
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 1, 17, 87),
        foregroundColor: const Color.fromARGB(255, 223, 221, 243),
        elevation: 0,
      ),

      // BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SAMBUTAN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E4BAF),
                    Color(0xFF1E4BAF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E4BAF).withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Selamat Datang!',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Selamat datang di aplikasi Field Survey. '
                    'Semoga aktivitas survei Anda berjalan lancar.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // JUDUL STATISTIK
            const Text(
              'Ringkasan Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B),
              ),
            ),

            const SizedBox(height: 16),

            // KARTU TOTAL SURVEY
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      size: 35,
                      color: primary,
                    ),
                  ),

                  const SizedBox(width: 20),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Survey',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '3',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        Text(
                          'Data survey',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // INFORMASI DASHBOARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: primary,
                    size: 26,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dashboard ini menampilkan ringkasan '
                      'survei secara statis. Total survey saat ini '
                      'ditampilkan sebanyak 3.',
                      style: TextStyle(
                        color: Color(0xFF312E81),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
