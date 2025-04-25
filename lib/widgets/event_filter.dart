import 'package:flutter/material.dart';

class EventFilter {
  final String? domain;
  final bool? registrationOpen;
  final String? eventType;
  final int? id;

  EventFilter({
    this.domain,
    this.registrationOpen,
    this.eventType,
    this.id,
  });

  bool matches(Map<String, dynamic> event) {
    if (domain != null && event['domain'] != domain) return false;
    if (registrationOpen != null &&
        event['registrationOpen'] != registrationOpen) return false;
    if (eventType != null && event['eventType'] != eventType) return false;
    if (id != null && event['id'] != id) return false;
    return true;
  }

  bool get hasActiveFilters =>
      domain != null ||
      registrationOpen != null ||
      eventType != null ||
      id != null;
}

class EventFilterWidget extends StatefulWidget {
  final Function(EventFilter) onFilterChanged;
  final List<String> domains;
  final List<String> eventTypes;

  const EventFilterWidget({
    super.key,
    required this.onFilterChanged,
    required this.domains,
    required this.eventTypes,
  });

  @override
  State<EventFilterWidget> createState() => _EventFilterWidgetState();
}

class _EventFilterWidgetState extends State<EventFilterWidget> {
  String? _selectedDomain;
  bool? _registrationOpen;
  String? _selectedEventType;
  final _idController = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final filter = EventFilter(
      domain: _selectedDomain,
      registrationOpen: _registrationOpen,
      eventType: _selectedEventType,
      id: _idController.text.isNotEmpty
          ? int.tryParse(_idController.text)
          : null,
    );
    widget.onFilterChanged(filter);
  }

  void _clearFilters() {
    setState(() {
      _selectedDomain = null;
      _registrationOpen = null;
      _selectedEventType = null;
      _idController.clear();
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _selectedDomain != null ||
        _registrationOpen != null ||
        _selectedEventType != null ||
        _idController.text.isNotEmpty;

    return Card(
      margin: const EdgeInsets.all(8),
      color: const Color(0xFF232528),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.filter_list, color: Colors.white70),
            title: const Text(
              'Filter Events',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasActiveFilters)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: _clearFilters,
                    tooltip: 'Clear Filters',
                  ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(color: Colors.white24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
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
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Domains', style: TextStyle(color: Colors.white)),
                            ),
                            ...widget.domains.map((domain) {
                              return DropdownMenuItem(
                                value: domain,
                                child: Text(domain, style: const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDomain = value;
                            });
                            _applyFilter();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedEventType,
                          dropdownColor: const Color(0xFF232528),
                          style: const TextStyle(color: Colors.white),
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
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Types', style: TextStyle(color: Colors.white)),
                            ),
                            ...widget.eventTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type, style: const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedEventType = value;
                            });
                            _applyFilter();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<bool>(
                          value: _registrationOpen,
                          dropdownColor: const Color(0xFF232528),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Registration Status',
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
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All Status', style: TextStyle(color: Colors.white)),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Open'),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text('Closed'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _registrationOpen = value;
                            });
                            _applyFilter();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _idController,
                          decoration: const InputDecoration(
                            labelText: 'Event ID',
                            border: OutlineInputBorder(),
                            hintText: 'Enter event ID',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _applyFilter(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
