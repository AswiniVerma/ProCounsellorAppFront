import 'package:flutter/material.dart';
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_community_page.dart';
import 'counsellor_dashboard.dart';
import 'counsellor_my_activities_page.dart'; // Import My Activities Page
import 'counsellor_learn_with_use_page.dart'; // Import Learn with Us Page
import 'counsellor_profile_page.dart';

class CounsellorBasePage extends StatefulWidget {
  final VoidCallback onSignOut;
  final String counsellorId;

  CounsellorBasePage({required this.onSignOut, required this.counsellorId});

  @override
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<CounsellorBasePage> {
  int _selectedIndex = 0;

  // Define the pages that can be navigated to
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    // Initialize the pages with dynamic data
    _pages.add(CounsellorDashboard(
        onSignOut: widget.onSignOut,
        counsellorId: widget.counsellorId)); // User Dashboard
    _pages.add(CounsellorLearnWithUsPage()); // Learn with Us Page
    _pages.add(CounsellorCommunityPage()); // Community Page
    _pages.add(CounsellorMyActivitiesPage(
        username: widget.counsellorId)); // My Activities Page
    _pages.add(
        CounsellorProfilePage(username: widget.counsellorId)); // Profile Page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pro Counsellor",
          style: TextStyle(
              color: Color(0xFFF0BB78)), // Set the title color to #F0BB78
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: widget.onSignOut, // Call sign-out function
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFFF0BB78), // Color for selected icon
        unselectedItemColor: Colors.grey, // Color for unselected icons
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb), label: "Learn with Us"),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Community"),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: "My Activities"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
