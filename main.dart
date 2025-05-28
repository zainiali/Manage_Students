import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:my_apis/screens/SplashScreen.dart';

import 'package:my_apis/screens/add_Student_Screen.dart';
import 'package:my_apis/screens/requests_screens/login_screen.dart';
import 'package:my_apis/screens/requests_screens/signup_screen.dart';
import 'package:my_apis/screens/requests_screens/all_users_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Manager',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.indigo.shade100,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        appBarTheme: AppBarTheme(
          elevation: 3,
          centerTitle: true,
          backgroundColor: Colors.indigo.shade100,
          foregroundColor: Colors.indigo.shade900,
          iconTheme: IconThemeData(color: Colors.indigo.shade900),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade900,
          ),
        ),
      ),
      home: SplashScreen(),
      routes: {
        '/view': (context) => StudentScreen(),
        '/signup': (context) => SignupScreen(),
        '/login': (context) => LoginScreen(),
        '/all_user': (context) => AllUsersScreen(userId: 'default'),
        '/home': (context) => HomePage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Manager')),
      drawer: CustomDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/student_animation.json',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 24),
              Text(
                'Welcome, Zainab!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo.shade900,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Easily manage student records and user data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.indigo.shade200],
              ),
            ),
            accountName: Text('Zainab', style: TextStyle(fontSize: 18)),
            accountEmail: Text('zainab@gmail.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.indigo),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                buildDrawerItem(context, Icons.home, 'Home', '/home'),
                buildDrawerItem(context, Icons.person, 'Student Screen', '/view'),
                buildDrawerItem(context, Icons.app_registration, 'Signup Screen', '/signup'),
                buildDrawerItem(context, Icons.login, 'Login Screen', '/login'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListTile buildDrawerItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}
