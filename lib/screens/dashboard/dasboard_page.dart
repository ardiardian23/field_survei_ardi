import 'package:flutter/material.dart';
import 'package:flutter_application_2/profile/profile_page.dart';
import 'package:flutter_application_2/screens/dashboard/survey_page.dart';
// import 'package:flutter_application_2/screens/profile/profile_page.dart';
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

  // ============================================================
  // AMBIL TOKEN
  // ============================================================

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
    // ============================================================
    // LOADING
    // ============================================================

    if (isLoadingToken) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ============================================================
    // DASHBOARD
    // ============================================================

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),

      body: IndexedStack(
        index: currentIndex,

        children: [
          // ======================================================
          // HOME
          // ======================================================

          const HomePage(),

          // ======================================================
          // SURVEY
          // ======================================================

          const SurveyScreen(),

          // ======================================================
          // PROFILE
          // ======================================================

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

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

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
          // ======================================================
          // HOME
          // ======================================================

          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),

          // ======================================================
          // SURVEY
          // ======================================================

          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Survey',
          ),

          // ======================================================
          // PROFILE
          // ======================================================

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

// ================================================================
// HOME PAGE
// ================================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const primary = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,

        backgroundColor: const Color.fromARGB(255, 1, 17, 87),

        foregroundColor: const Color.fromARGB(255, 223, 221, 243),

        elevation: 0,
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // ====================================================
            // ICON
            // ====================================================

            Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,

                shape: BoxShape.circle,

                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: const Icon(
                Icons.assignment_rounded,
                size: 60,
                color: primary,
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // TITLE
            // ====================================================

            const Text(
              'FIELD SURVEY',

              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B),
              ),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // SUBTITLE
            // ====================================================

            const Text(
              'Selamat datang di Field Survey',

              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}