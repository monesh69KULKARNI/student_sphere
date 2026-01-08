import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/event_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int _maxParticipants = 50;
  bool _requiresVolunteers = false;
  int _maxVolunteers = 0;
  String _category = 'general';
  
  // Role restrictions
  bool _allowStudents = true;
  bool _allowFaculty = true;
  bool _allowAdmin = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          if (isStart) {
            _startDate = DateTime(
              picked.year,
              picked.month,
              picked.day,
              time.hour,
              time.minute,
            );
          } else {
            _endDate = DateTime(
              picked.year,
              picked.month,
              picked.day,
              time.hour,
              time.minute,
            );
          }
        });
      }
    }
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start and end dates')),
        );
        return;
      }

      // Validate that at least one role is selected
      if (!_allowStudents && !_allowFaculty && !_allowAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one role that can register')),
        );
        return;
      }

      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;

      // Build allowed roles list
      final List<String> allowedRoles = [];
      if (_allowStudents) allowedRoles.add('student');
      if (_allowFaculty) allowedRoles.add('faculty');
      if (_allowAdmin) allowedRoles.add('admin');

      final event = EventModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        location: _locationController.text.trim(),
        organizerId: user.uid,
        organizerName: user.name,
        maxParticipants: _maxParticipants,
        registeredParticipants: [],
        volunteers: [],
        requiresVolunteers: _requiresVolunteers,
        maxVolunteers: _maxVolunteers,
        category: _category,
        allowedRoles: allowedRoles,
        createdAt: DateTime.now(),
      );

      try {
        await EventService().createEvent(event);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Event "${event.title}" created successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_startDate == null
                    ? 'Start Date & Time *'
                    : 'Start: ${_startDate!.toString()}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_endDate == null
                    ? 'End Date & Time *'
                    : 'End: ${_endDate!.toString()}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _maxParticipants.toString(),
                decoration: const InputDecoration(
                  labelText: 'Max Participants',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxParticipants = int.tryParse(value) ?? 50;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'academic', child: Text('Academic')),
                  DropdownMenuItem(value: 'cultural', child: Text('Cultural')),
                  DropdownMenuItem(value: 'sports', child: Text('Sports')),
                  DropdownMenuItem(value: 'workshop', child: Text('Workshop')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Who can register for this event?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Students'),
                        subtitle: const Text('Allow students to register'),
                        value: _allowStudents,
                        onChanged: (value) {
                          setState(() {
                            _allowStudents = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Faculty'),
                        subtitle: const Text('Allow faculty members to register'),
                        value: _allowFaculty,
                        onChanged: (value) {
                          setState(() {
                            _allowFaculty = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Admin'),
                        subtitle: const Text('Allow admin users to register'),
                        value: _allowAdmin,
                        onChanged: (value) {
                          setState(() {
                            _allowAdmin = value ?? false;
                          });
                        },
                      ),
                      if (!_allowStudents && !_allowFaculty && !_allowAdmin)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Please select at least one role that can register',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Requires Volunteers'),
                value: _requiresVolunteers,
                onChanged: (value) {
                  setState(() {
                    _requiresVolunteers = value ?? false;
                  });
                },
              ),
              if (_requiresVolunteers) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _maxVolunteers.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Max Volunteers',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _maxVolunteers = int.tryParse(value) ?? 0;
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createEvent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Create Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

