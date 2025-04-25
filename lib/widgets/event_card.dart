import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../providers/events_provider.dart';
import 'package:provider/provider.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final Function() onEdit;
  final Function() onDelete;

  const EventCard({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isExpanded = false;

  Future<void> _showEventDetails(BuildContext context) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF232528),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.event.imageDetails?.secureUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  widget.event.imageDetails!.secureUrl,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.event.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                widget.event.registrationOpen
                                    ? 'Open'
                                    : 'Closed',
                                style: TextStyle(
                                  color: widget.event.registrationOpen
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  widget.event.registrationOpen
                                      ? Icons.lock_open
                                      : Icons.lock_outline,
                                  color: widget.event.registrationOpen
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                onPressed: () async {
                                  try {
                                    final success = await context
                                        .read<EventsProvider>()
                                        .toggleRegistrationStatus(
                                            widget.event.id);

                                    if (success && context.mounted) {
                                      // Show success message with the new state
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Registration ${!widget.event.registrationOpen ? 'opened' : 'closed'} successfully',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      // Close the dialog
                                      Navigator.pop(context, true);
                                      // Refresh the events list
                                      context
                                          .read<EventsProvider>()
                                          .fetchEvents();
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              context
                                                      .read<EventsProvider>()
                                                      .error ??
                                                  'Failed to update registration status',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Error: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Id', widget.event.id.toString()),
                      _buildDetailRow('Domain', widget.event.domain),
                      _buildDetailRow('Event Type', widget.event.eventType),
                      _buildDetailRow(
                        'Event Date',
                        DateFormat('MMM dd, yyyy')
                            .format(widget.event.eventDate),
                      ),
                      _buildDetailRow('Venue', widget.event.venue),
                      _buildDetailRow(
                          'Min Players', widget.event.minPlayers.toString()),
                      _buildDetailRow(
                          'Max Players', widget.event.maxPlayers.toString()),
                      _buildDetailRow('Registration Fee',
                          '₹${widget.event.registrationFee}'),
                      _buildDetailRow(
                          'Prize Pool', '₹${widget.event.prizePool}'),
                      if (widget.event.ruleBook.isNotEmpty)
                        _buildDetailRow('Rule Book', widget.event.ruleBook),
                      const SizedBox(height: 16),
                      const Text(
                        'Description:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.event.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (widget.event.coordinatorDetails.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Coordinator Details:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.event.coordinatorDetails
                            .map((coordinator) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    coordinator,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                )),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onEdit();
                    },
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    label: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDelete();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF232528),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showEventDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.event.imageDetails?.secureUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.event.imageDetails!.secureUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.event.domain,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(widget.event.eventDate),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.event.registrationOpen
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.event.registrationOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        color: widget.event.registrationOpen
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
