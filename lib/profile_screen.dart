import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo Utente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Profile Picture
            Center(
              child: Stack(
                children: <Widget>[
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        _user?.photoURL != null
                            ? NetworkImage(_user!.photoURL!) as ImageProvider
                            : const AssetImage(
                              'assets/images/default_profile.png',
                            ), // Use a default asset image
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Funzionalità non ancora implementata',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Display Name
            Text(
              'Nome Utente:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextFormField(
              initialValue: _user?.displayName ?? '',
              decoration: const InputDecoration(
                hintText: 'Inserisci il tuo nome',
              ),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),

            // Email Address
            Text('Email:', style: Theme.of(context).textTheme.titleMedium),
            Text(
              _user?.email ?? 'N/A',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Change Password
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funzionalità non ancora implementata'),
                  ),
                );
              },
              child: const Text('Cambia Password'),
            ),
            const SizedBox(height: 16),

            // Sign Out
            ElevatedButton(
              onPressed: () async {
                await _auth.signOut();
                // Navigate back to the authentication page is handled by StreamBuilder in main.dart
              },
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 16),

            // Delete Account (Optional, use with caution)
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funzionalità non ancora implementata'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Elimina Account',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
