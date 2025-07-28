import 'package:flutter/material.dart';
import 'important_dates_screen.dart'; // Import the important dates screen
import 'profile_screen.dart'; // Import the profile screen (will create next)

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of screens to display in the bottom navigation bar
  final List<Widget> _screens = [
    const ImportantDatesScreen(), // Screen for important dates
    const ProfileScreen(), // Screen for user profile (will create next)
  ];

  // Function to handle tab changes
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar can be here or in individual screens.
      // For simplicity now, we'll let individual screens have their AppBars.
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Date',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue, // Customize selected item color
        onTap: _onItemTapped, // Handle tap events
      ),
    );
  }
}
