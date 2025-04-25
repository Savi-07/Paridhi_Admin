import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/combo_event_model.dart';
import '../models/event_model.dart';
import '../providers/combo_events_provider.dart';
import '../providers/events_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/animated_background.dart';

class ComboEventFormScreen extends StatefulWidget {
  final ComboEvent? combo;

  const ComboEventFormScreen({super.key, this.combo});

  @override
  State<ComboEventFormScreen> createState() => _ComboEventFormScreenState();
}

class _ComboEventFormScreenState extends State<ComboEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _registrationFeeController;
  String _selectedDomain = 'CODING';
  List<int> _selectedEventIds = [];
  bool _registrationOpen = false;
  List<Event> _availableEvents = [];
  bool _isLoading = false;
  bool _isImageUploading = false;

  final List<String> _domains = [
    'CODING',
    'GAMING',
    'ROBOTICS',
    'CIVIL',
    'ELECTRICAL',
    'GENERAL'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.combo?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.combo?.description ?? '');
    _registrationFeeController = TextEditingController(
        text: widget.combo?.registrationFee.toString() ?? '');

    if (widget.combo != null) {
      _selectedDomain = widget.combo!.domain;
      _selectedEventIds = widget.combo!.events.map((e) => e.id).toList();
      _registrationOpen = widget.combo!.registrationOpen;
    } else {
      // For new combos, set registration open to true by default
      _registrationOpen = true;
    }

    // Fetch available events
    Future.microtask(() => _fetchAvailableEvents());
  }

  Future<void> _fetchAvailableEvents() async {
    await context.read<EventsProvider>().fetchEvents();
    if (mounted) {
      setState(() {
        _availableEvents = context.read<EventsProvider>().events;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _registrationFeeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final combo = ComboEvent(
        id: widget.combo?.id ?? 0,
        name: _nameController.text,
        description: _descriptionController.text,
        domain: _selectedDomain,
        events: _availableEvents
            .where((e) => _selectedEventIds.contains(e.id))
            .toList(),
        registrationFee: double.parse(_registrationFeeController.text),
        registrationOpen: _registrationOpen,
        createdAt: widget.combo?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUsername: widget.combo?.createdByUsername ?? '',
        imageDetails: widget.combo?.imageDetails,
      );

      final success = widget.combo == null
          ? await context.read<ComboEventsProvider>().createCombo(combo)
          : await context.read<ComboEventsProvider>().updateCombo(combo);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.combo == null
                  ? 'Combo event created successfully'
                  : 'Combo event updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<ComboEventsProvider>().error ??
                  'Failed to ${widget.combo == null ? 'create' : 'update'} combo event',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadComboPicture(ComboEvent combo) async {
    try {
      setState(() {
        _isImageUploading = true;
      });
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        dynamic imageData;
        if (kIsWeb) {
          // For web, read as bytes
          imageData = await image.readAsBytes();
        } else {
          // For mobile, use path
          imageData = image.path;
        }

        if (!mounted) return;

        final success =
            await context.read<ComboEventsProvider>().uploadComboPicture(
                  combo.id,
                  imageData,
                );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Picture uploaded successfully'
                    : 'Failed to upload picture',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1A1C1E),
        title: Text(
          widget.combo == null ? 'Create Combo Event' : 'Edit Combo Event',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  TextFormField(
                    // style: TextStyle(color: colour),
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Name',
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
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedDomain,
                    dropdownColor: const Color(0xFF232528),
                    style: const TextStyle(color: Colors.white),
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
                        child: Text(domain, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDomain = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _registrationFeeController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a registration fee';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xFF232528),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Included Events',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._availableEvents.where((event) => event.domain == _selectedDomain).map((event) {
                            return CheckboxListTile(
                              title: Text(
                                event.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                event.domain,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              value: _selectedEventIds.contains(event.id),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedEventIds.add(event.id);
                                  } else {
                                    _selectedEventIds.remove(event.id);
                                  }
                                });
                              },
                              activeColor: Colors.white,
                              checkColor: const Color(0xFF232528),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      'Registration Open',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: _registrationOpen,
                    onChanged: (bool value) {
                      setState(() {
                        _registrationOpen = value;
                      });
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.5),
                    inactiveThumbColor: Colors.white.withOpacity(0.5),
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF232528),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.combo == null ? 'Create Combo Event' : 'Update Combo Event',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  if (widget.combo != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isImageUploading
                          ? null
                          : () => _uploadComboPicture(widget.combo!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF232528),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isImageUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Upload Picture',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
