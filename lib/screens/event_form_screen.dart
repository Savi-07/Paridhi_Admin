// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/events_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../widgets/animated_background.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;

  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _venueController;
  late TextEditingController _registrationFeeController;
  late TextEditingController _minPlayersController;
  late TextEditingController _maxPlayersController;
  late TextEditingController _prizePoolController;
  late TextEditingController _coordinatorDetailsController;
  late TextEditingController _ruleBookController;
  DateTime _eventDate = DateTime.now();
  String _selectedDomain = 'CODING';
  String _selectedEventType = 'MAIN';
  bool _registrationOpen = false;
  bool _isLoading = false;

  final List<String> _domains = [
    'CODING',
    'GAMING',
    'ROBOTICS',
    'CIVIL',
    'ELECTRICAL',
    'GENERAL',
    'EXCLUSIVE'
  ];
  final List<String> _eventTypes = ['MAIN', 'ON_SPOT'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.event?.description ?? '');
    _venueController = TextEditingController(text: widget.event?.venue ?? '');
    _registrationFeeController = TextEditingController(
        text: widget.event?.registrationFee.toString() ?? '');
    _minPlayersController =
        TextEditingController(text: widget.event?.minPlayers.toString() ?? '');
    _maxPlayersController =
        TextEditingController(text: widget.event?.maxPlayers.toString() ?? '');
    _prizePoolController =
        TextEditingController(text: widget.event?.prizePool.toString() ?? '');
    _coordinatorDetailsController = TextEditingController(
        text: widget.event?.coordinatorDetails.join('\n') ?? '');
    _ruleBookController =
        TextEditingController(text: widget.event?.ruleBook ?? '');

    if (widget.event != null) {
      _eventDate = widget.event!.eventDate;
      _selectedDomain = widget.event!.domain;
      _selectedEventType = widget.event!.eventType;
      _registrationOpen = widget.event!.registrationOpen;
    } else {
      // For new events, set registration open to true by default
      _registrationOpen = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _registrationFeeController.dispose();
    _minPlayersController.dispose();
    _maxPlayersController.dispose();
    _prizePoolController.dispose();
    _coordinatorDetailsController.dispose();
    _ruleBookController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _eventDate) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });
    if (_formKey.currentState!.validate()) {
      final event = Event(
        imageDetails: widget.event?.imageDetails,
        id: widget.event?.id ?? 0,
        domain: _selectedDomain,
        name: _nameController.text,
        eventType: _selectedEventType,
        eventDate: _eventDate,
        description: _descriptionController.text,
        venue: _venueController.text,
        coordinatorDetails: _coordinatorDetailsController.text.split('\n'),
        ruleBook: _ruleBookController.text,
        minPlayers: int.parse(_minPlayersController.text),
        maxPlayers: int.parse(_maxPlayersController.text),
        registrationFee: double.parse(_registrationFeeController.text),
        prizePool: _prizePoolController.text.isEmpty
            ? null
            : double.parse(_prizePoolController.text),
        registrationOpen: _registrationOpen,
      );

      final success = widget.event == null
          ? await context.read<EventsProvider>().createEvent(event)
          : await context.read<EventsProvider>().updateEvent(event);

      if (success && mounted) {
        // If this is a new event, show the picture upload dialog
        if (widget.event == null) {
          final createdEvent = context.read<EventsProvider>().events.last;
          final shouldUpload = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Upload Event Picture'),
              content: const Text(
                  'Would you like to upload a picture for this event?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Skip'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Upload'),
                ),
              ],
            ),
          );

          if (shouldUpload == true && mounted) {
            await _uploadEventPicture(createdEvent);
            setState(() {
              _isLoading = false;
            });
          }
        }
        Navigator.pop(context, true);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error message
        final error = context.read<EventsProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save event'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Form validation failed
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadEventPicture(Event event) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        dynamic imageData;
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await image.readAsBytes();
          if (bytes.isEmpty) {
            throw Exception('Failed to read image data');
          }
          imageData = bytes;
        } else {
          // For mobile, use path
          imageData = image.path;
        }

        if (!mounted) return;

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final success = await context.read<EventsProvider>().uploadEventPicture(
              event.id,
              imageData,
            );

        // Hide loading indicator
        if (mounted) {
          Navigator.pop(context); // Remove loading dialog
          final error = context.read<EventsProvider>().error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Picture uploaded successfully'
                    : error ?? 'Failed to upload picture',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator if it's showing
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var colour = Colors.white;
    return Scaffold(
      appBar: AppBar(
        foregroundColor: colour,
        backgroundColor: const Color(0xFF1A1C1E),
        title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
      ),
      body: Container(
        height: double.infinity,
        child: AnimatedGradientBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    // backgroundColor: const Color(0xFF1A1C1E),
                    dropdownColor: const Color(0xFF1A1C1E),
                    style: TextStyle(color: colour),
                    value: _selectedDomain,
                    decoration: InputDecoration(
                      labelText: 'Domain',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    items: _domains.map((domain) {
                      return DropdownMenuItem(
                        value: domain,
                        child: Text(domain),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDomain = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    style: TextStyle(color: colour),
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Event Name',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter event name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1A1C1E),
                    style: TextStyle(color: colour),
                    value: _selectedEventType,
                    decoration: InputDecoration(
                      labelText: 'Event Type',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    items: _eventTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEventType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    style: TextStyle(color: colour),
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter event description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    
                    // style: ListTileStyle.drawer,
                    // contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    // tileColor: const Color(0xFF1A1C1E),
                    // selectedTileColor: Color(0xFF1A1C1E),
                    title: Text('Event Date', style: TextStyle(color: colour)),
                    subtitle: Text(_eventDate.toString().split(' ')[0], style: TextStyle(color: colour)),
                    trailing: Icon(Icons.calendar_today,color: colour,),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    style: TextStyle(color: colour),
                    controller: _venueController,
                    decoration: InputDecoration(
                      labelText: 'Venue',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter venue';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    style: TextStyle(color: colour),
                    controller: _coordinatorDetailsController,
                    decoration: InputDecoration(
                      labelText: 'Coordinator Details (one per line)',
                      labelStyle: TextStyle(color: colour),
                      border: OutlineInputBorder(),
                      hintText: 'Name - Phone\nName - Phone',
                      hintStyle: TextStyle(color: colour.withOpacity(0.7)),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter coordinator details';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    style: TextStyle(color: colour),
                    controller: _ruleBookController,
                    decoration: InputDecoration(
                      labelText: 'Rule Book URL',
                      hintText: 'https://example.com/rules.pdf',
                      hintStyle: TextStyle(color: colour.withOpacity(0.7)),
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the rule book URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          style: TextStyle(color: colour),
                          controller: _minPlayersController,
                          decoration: InputDecoration(
                      labelText: 'Min Players',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          style: TextStyle(color: colour),
                          controller: _maxPlayersController,
                          decoration: InputDecoration(
                      labelText: 'Max Players',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    style: TextStyle(color: colour),
                    controller: _registrationFeeController,
                    decoration: InputDecoration(
                      labelText: 'Registration Fee',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter registration fee';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    style: TextStyle(color: colour),
                    controller: _prizePoolController,
                    decoration: InputDecoration(
                      labelText: 'Prize Pool (optional)',
                      hintText: 'Enter prize pool amount',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      // Validate only if value is not empty
                      if (value != null &&
                          value.isNotEmpty &&
                          double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Registration Open', style: TextStyle(color: colour)),
                    value: _registrationOpen,
                    onChanged: (bool value) {
                      setState(() {
                        _registrationOpen = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (widget.event != null) {
                        _uploadEventPicture(widget.event!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please create the event first'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Event Picture'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Save Event'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
