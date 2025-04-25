import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/events_provider.dart';
import 'event_form_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/event_filter.dart';
import '../widgets/event_card.dart';
import '../widgets/animated_background.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final ImagePicker _picker = ImagePicker();
  EventFilter? _currentFilter;
  final List<String> _domains = [
    'CODING',
    'GAMING',
    'ROBOTICS',
    'CIVIL',
    'ELECTRICAL',
    'GENERAL'
  ];
  final List<String> _eventTypes = ['MAIN', 'ON_SPOT'];

  List<Event> _getFilteredEvents(List<Event> events) {
    if (_currentFilter == null) return events;

    return events.where((event) {
      final eventMap = event.toJson();
      return _currentFilter!.matches(eventMap);
    }).toList();
  }

  void _handleFilterChanged(EventFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (url.isEmpty) {
        throw 'Invalid URL';
      }

      final uri = Uri.parse(url);
      if (!uri.hasScheme) {
        throw 'Invalid URL format';
      }

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          throw 'Failed to launch URL';
        }
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<EventsProvider>().fetchEvents());
  }

  Future<void> _editEvent(Event event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(event: event),
      ),
    );
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await context.read<EventsProvider>().deleteEvent(event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Event deleted successfully' : 'Failed to delete event',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadEventPicture(Event event) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
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

        final success = await context.read<EventsProvider>().uploadEventPicture(
              event.id,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1A1C1E),
        title: const Text(
          'Events',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EventFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Event',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: AnimatedGradientBackground(
        child: Consumer<EventsProvider>(
          builder: (context, eventsProvider, child) {
            if (eventsProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (eventsProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      eventsProvider.error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => eventsProvider.fetchEvents(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final allEvents = eventsProvider.events;
            final filteredEvents = _getFilteredEvents(allEvents);

            return Column(
              children: [
                EventFilterWidget(
                  onFilterChanged: _handleFilterChanged,
                  domains: _domains,
                  eventTypes: _eventTypes,
                ),
                if (_currentFilter?.hasActiveFilters == true) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Active Filters:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              if (_currentFilter?.domain != null)
                                Chip(
                                  label:
                                      Text('Domain: ${_currentFilter!.domain}'),
                                  onDeleted: () {
                                    setState(() {
                                      _currentFilter = EventFilter(
                                        registrationOpen:
                                            _currentFilter?.registrationOpen,
                                        eventType: _currentFilter?.eventType,
                                        id: _currentFilter?.id,
                                      );
                                    });
                                  },
                                ),
                              if (_currentFilter?.eventType != null)
                                Chip(
                                  label: Text(
                                      'Type: ${_currentFilter!.eventType}'),
                                  onDeleted: () {
                                    setState(() {
                                      _currentFilter = EventFilter(
                                        domain: _currentFilter?.domain,
                                        registrationOpen:
                                            _currentFilter?.registrationOpen,
                                        id: _currentFilter?.id,
                                      );
                                    });
                                  },
                                ),
                              if (_currentFilter?.registrationOpen != null)
                                Chip(
                                  label: Text(
                                      'Status: ${_currentFilter!.registrationOpen! ? 'Open' : 'Closed'}'),
                                  onDeleted: () {
                                    setState(() {
                                      _currentFilter = EventFilter(
                                        domain: _currentFilter?.domain,
                                        eventType: _currentFilter?.eventType,
                                        id: _currentFilter?.id,
                                      );
                                    });
                                  },
                                ),
                              if (_currentFilter?.id != null)
                                Chip(
                                  label: Text('ID: ${_currentFilter!.id}'),
                                  onDeleted: () {
                                    setState(() {
                                      _currentFilter = EventFilter(
                                        domain: _currentFilter?.domain,
                                        eventType: _currentFilter?.eventType,
                                        registrationOpen:
                                            _currentFilter?.registrationOpen,
                                      );
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: filteredEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No events found matching your filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${allEvents.length} events available',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _currentFilter = null;
                                  });
                                },
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear All Filters'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(1),
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = filteredEvents[index];
                            return EventCard(
                              event: event,
                              onEdit: () => _editEvent(event),
                              onDelete: () => _deleteEvent(event),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
