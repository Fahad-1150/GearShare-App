import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'landingPage.dart';
import 'pages/sign_in_page.dart';
import 'pages/sign_up_page.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://nhataoydgtqovvznijrx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oYXRhb3lkZ3Rxb3Z2em5panJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MjQzMTQsImV4cCI6MjA5MTMwMDMxNH0.0jsJsdCOLxVciiYxB6cehdtQCPAC78DFzGGpU5RzpwM',
  );

  runApp(const GearShareApp());
}

class GearShareApp extends StatelessWidget {
  const GearShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GearShare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

// Home Page - Shows user profile and verifies Supabase connection
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final currentUser = SupabaseService().getCurrentUser();
    if (currentUser != null) {
      _userDataFuture = SupabaseService().getUserData(currentUser.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseService().getCurrentUser();

    return Scaffold(
      appBar: AppBar(title: const Text('GearShare Home'), centerTitle: true),
      body: currentUser == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not logged in'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/signin');
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to GearShare!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C4B7C),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<Map<String, dynamic>?>(
                          future: _userDataFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Text(
                                'Error loading profile: ${snapshot.error}',
                                style: TextStyle(color: Colors.red.shade700),
                              );
                            }

                            final userData = snapshot.data;
                            if (userData == null) {
                              return Text(
                                'No profile data found. Please ensure the SQL setup is complete.',
                                style: TextStyle(color: Colors.orange.shade700),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                  'Name',
                                  userData['name'] ?? 'N/A',
                                ),
                                _buildInfoRow(
                                  'Email',
                                  userData['email'] ?? 'N/A',
                                ),
                                _buildInfoRow(
                                  'Phone',
                                  userData['phone'] ?? 'N/A',
                                ),
                                _buildInfoRow(
                                  'Member Since',
                                  userData['created_at'] ?? 'N/A',
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    '✅ Supabase Status: Connected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text(
                              'Are you sure you want to sign out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await SupabaseService().signOut();
                                  if (context.mounted) {
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/');
                                  }
                                },
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
