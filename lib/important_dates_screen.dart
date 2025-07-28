import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImportantDatesScreen extends StatefulWidget {
  const ImportantDatesScreen({super.key}); // Use super.key

  @override
  _ImportantDatesScreenState createState() => _ImportantDatesScreenState();
}

class _ImportantDatesScreenState extends State<ImportantDatesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for the text fields in the add date dialog
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController(); // Optional year

  // To manage the type of date
  String _selectedType = 'Compleanno'; // Default type
  final List<String> _dateTypes = ['Compleanno', 'Anniversario', 'Matrimonio', 'Altro'];


  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    _nameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      // Should not happen if accessed from MyHomePage after login, but good practice
      return Scaffold( // Removed const here
        appBar: AppBar(
          title: const Text('Date importanti'),
        ),
        body: const Center( // Added const here as Center and its children are const
          child: Text('Utente non autenticato.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Date importanti'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users')
                           .doc(currentUser.uid)
                           .collection('importantDates')
                           .snapshots(), // Listen for changes in the importantDates collection
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Errore nel caricamento delle date: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nessuna data importante aggiunta ancora.'));
          }

          // Display the list of important dates
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              // Safely access data, checking if it's a Map<String, dynamic>
              final data = doc.data(); // Get the raw data
              if (data is Map<String, dynamic>) { // Check if it's the expected type
                 // Corrected string interpolation for subtitle
                 final day = data['day']?.toString() ?? '?';
                 final month = data['month']?.toString() ?? '?';
                 final year = data['year'] != null ? '/${data['year']}' : '';
                 return ListTile(
                   title: Text(data['name'] ?? 'Nome sconosciuto'),
                   subtitle: Text('${data['type'] ?? 'Tipo sconosciuto'} - $day/$month$year'),
                   // TODO: Add onTap for viewing/editing details
                 );
              } else {
                 // Handle cases where the document data is not in the expected format
                 return const ListTile(
                   title: Text('Errore nel formato dei dati'),
                 );
              }
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Reset text controllers before showing the dialog
          _nameController.clear();
          _dayController.clear();
          _monthController.clear();
          _yearController.clear();
          _selectedType = 'Compleanno'; // Reset selected type
          _showAddDateDialog(context);
        },
        tooltip: 'Aggiungi data importante',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Dialog to add a new important date
  void _showAddDateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aggiungi data importante'),
          content: SingleChildScrollView( // Use SingleChildScrollView for potentially long content
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome persona'),
                ),
                TextField(
                  controller: _dayController,
                  decoration: const InputDecoration(labelText: 'Giorno'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _monthController,
                  decoration: const InputDecoration(labelText: 'Mese'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _yearController,
                  decoration: const InputDecoration(labelText: 'Anno (opzionale)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo di data'),
                  items: _dateTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() { // Use setState to update the dialog's state
                         _selectedType = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Salva'),
              onPressed: () {
                _saveImportantDate(context); // Pass context to show SnackBar
              },
            ),
          ],
        );
      },
    );
  }

  // Implement saving data to Firestore and validation
  void _saveImportantDate(BuildContext context) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Should not happen here, but as a safeguard
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Errore: Utente non autenticato.')),
       );
      return;
    }

    final String name = _nameController.text.trim();
    final int? day = int.tryParse(_dayController.text.trim());
    final int? month = int.tryParse(_monthController.text.trim());
    final int? year = int.tryParse(_yearController.text.trim()); // Year is optional

    // Basic validation
    if (name.isEmpty || day == null || month == null || day < 1 || day > 31 || month < 1 || month > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Per favore, inserisci nome, giorno e mese validi.')),
      );
      return;
    }

    // Prepare data to save
    final Map<String, dynamic> dateData = {
      'name': name,
      'day': day,
      'month': month,
      'year': year, // Will be null if not entered
      'type': _selectedType,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    try {
      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('importantDates')
          .add(dateData); // Use .add() to let Firestore generate a unique ID

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data importante salvata con successo!')),
      );

      // Close the dialog after successful save
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel salvataggio della data: $e')),
      );
    }
  }
}
