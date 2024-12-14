import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'signup.dart';
import 'dashboards/userDashboard/user_dashboard.dart';
import 'dashboards/counsellorDashboard/counsellor_dashboard.dart';
import 'dashboards/adminDashboard/admin_dashboard.dart';
import '../services/auth_service.dart';

final storage = FlutterSecureStorage();

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoggedInStatus();
  }

  Future<void> _checkLoggedInStatus() async {
    final role = await storage.read(key: 'role');
    final username = await storage.read(key: 'username');
    if (role != null && username != null) {
      _navigateToDashboard(role, username);
    }
  }

  Future<void> _signIn() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    final role = await AuthService.signIn(username, password);
    if (role == 'user' || role == 'counsellor' || role == 'admin') {
      await storage.write(key: 'role', value: role);
      await storage.write(key: 'username', value: username);
      _navigateToDashboard(role, username);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(role)));
    }
  }

  void _navigateToDashboard(String role, String username) {
    Widget dashboard;
    if (role == 'user') {
      dashboard = UserDashboard(onSignOut: _signOut, username: username);
    } else if (role == 'counsellor') {
      dashboard = CounsellorDashboard(onSignOut: _signOut);
    } else if (role == 'admin') {
      dashboard = AdminDashboard(onSignOut: _signOut);
    } else {
      return;
    }

    // Use pushAndRemoveUntil to clear the stack and prevent users from navigating back to SignInScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
      (route) => false, // Removes all previous routes
    );
  }

  void _signOut() async {
    await storage.deleteAll(); // Clear all data from secure storage

    if (!mounted) return; // Check if widget is still mounted

    // Navigate to SignInScreen and clear the stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign In")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signIn,
              child: Text("Sign In"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SignUpScreen()));
              },
              child: Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}
