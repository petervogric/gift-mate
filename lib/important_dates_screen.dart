import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class ImportantDatesScreen extends StatefulWidget {
  const ImportantDatesScreen({super.key});

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
  final TextEditingController _yearController =
      TextEditingController(); // Optional year

  // To manage the type of date
  String _selectedType = 'Compleanno'; // Default type
  final List<String> _dateTypes = [
    'Compleanno',
    'Anniversario',
    'Matrimonio',
    'Altro',
  ];

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events =
      {}; // Changed to store full event details

  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    _nameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // New method to get all events for the focused month
  List<Map<String, dynamic>> _getEventsForMonth(DateTime month) {
    List<Map<String, dynamic>> monthEvents = [];
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    for (int i = 1; i <= daysInMonth; i++) {
      final day = DateTime(month.year, month.month, i);
      final normalizedDay = DateTime(day.year, day.month, day.day);
      if (_events.containsKey(normalizedDay)) {
        monthEvents.addAll(_events[normalizedDay]!);
      }
    }
    // Sort events by day for better readability
    monthEvents.sort((a, b) {
      final aDay = (a['day'] as int?) ?? 0;
      final bDay = (b['day'] as int?) ?? 0;
      return aDay.compareTo(bDay);
    });
    return monthEvents;
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      // Should not happen if accessed from MyHomePage after login, but good practice
      return Scaffold(
        appBar: AppBar(title: const Text('Date importanti')),
        body: const Center(child: Text('Utente non autenticato.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Date importanti')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('users')
                .doc(currentUser.uid)
                .collection('importantDates')
                .snapshots(), // Listen for changes in the importantDates collection
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Errore nel caricamento delle date: ${snapshot.error}',
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nessuna data importante aggiunta ancora.'),
            );
          }

          // Convert Firestore data to events
          _events = {}; // Reset events map
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final day = data['day'] as int;
            final month = data['month'] as int;
            final year = data['year'] as int?;

            final eventDetails = {
              'name': data['name'] as String,
              'type': data['type'] as String,
              'day': day,
              'month': month,
              'year': year,
            };

            if (year != null) {
              // Specific year event: add for that year only
              final date = DateTime(year, month, day);
              final normalizedDate = DateTime(date.year, date.month, date.day);
              if (_events[normalizedDate] == null) {
                _events[normalizedDate] = [eventDetails];
              } else {
                _events[normalizedDate]!.add(eventDetails);
              }
            } else {
              // Recurring event (no year): add for all years from current year to 2125
              for (int y = DateTime.now().year; y <= 2125; y++) {
                final date = DateTime(y, month, day);
                final normalizedDate = DateTime(
                  date.year,
                  date.month,
                  date.day,
                );
                if (_events[normalizedDate] == null) {
                  _events[normalizedDate] = [eventDetails];
                } else {
                  _events[normalizedDate]!.add(eventDetails);
                }
              }
            }
          }

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2010, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) => _getEventsForDay(day),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.deepOrangeAccent,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible:
                      false, // Hide days from previous/next month
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                  weekendStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 16.0), // Spazio tra calendario e titolo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Eventi del Mese:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: ListView(
                  children:
                      _getEventsForMonth(_focusedDay).map((event) {
                        final yearString =
                            event['year'] != null ? '/${event['year']}' : '';
                        final dateString =
                            '${event['day']}/${event['month']}$yearString';
                        return ListTile(
                          title: Text('${event['name']} (${event['type']})'),
                          subtitle: Text(dateString),
                        );
                      }).toList(),
                ),
              ),
            ],
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
          content: SingleChildScrollView(
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
                  decoration: const InputDecoration(
                    labelText: 'Anno (opzionale)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo di data'),
                  items:
                      _dateTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore: Utente non autenticato.')),
        );
      }
      return;
    }

    final String name = _nameController.text.trim();
    final int? day = int.tryParse(_dayController.text.trim());
    final int? month = int.tryParse(_monthController.text.trim());
    final int? year = int.tryParse(
      _yearController.text.trim(),
    ); // Year is optional

    // Basic validation
    if (name.isEmpty ||
        day == null ||
        month == null ||
        day < 1 ||
        day > 31 ||
        month < 1 ||
        month > 12) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Per favore, inserisci nome, giorno e mese validi.'),
          ),
        );
      }
      return;
    }

    // More robust day validation based on the month
    if (day > DateTime(DateTime.now().year, month + 1, 0).day) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giorno non valido per il mese selezionato.'),
          ),
        );
      }
      return;
    }

    // Prepare data to save
    final Map<String, dynamic> dateData = {
      'name': name,
      'day': day,
      'month': month,
      'year': year,
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data importante salvata con successo!'),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog after successful save
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel salvataggio della data: \$e')),
        );
      }
    }
  }
}
