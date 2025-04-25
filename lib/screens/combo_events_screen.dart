import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/combo_event_model.dart';
import '../providers/combo_events_provider.dart';
import '../widgets/combo_event_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_dialog.dart';
import '../widgets/combo_event_filter.dart';
import '../widgets/animated_background.dart';
import 'combo_event_form_screen.dart';

class ComboEventsScreen extends StatefulWidget {
  const ComboEventsScreen({super.key});

  @override
  State<ComboEventsScreen> createState() => _ComboEventsScreenState();
}

class _ComboEventsScreenState extends State<ComboEventsScreen> {
  ComboEventFilter? _currentFilter;
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
    Future.microtask(
      () => context.read<ComboEventsProvider>().fetchCombos(),
    );
  }

  List<ComboEvent> _getFilteredCombos(List<ComboEvent> combos) {
    if (_currentFilter == null) return combos;

    return combos.where((combo) {
      final comboMap = combo.toJson();
      return _currentFilter!.matches(comboMap);
    }).toList();
  }

  void _handleFilterChanged(ComboEventFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
  }

  Future<void> _editCombo(ComboEvent combo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComboEventFormScreen(combo: combo),
      ),
    );

    if (result == true && mounted) {
      await context.read<ComboEventsProvider>().fetchCombos();
    }
  }

  Future<void> _deleteCombo(ComboEvent combo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Combo Event'),
        content: Text('Are you sure you want to delete ${combo.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await context.read<ComboEventsProvider>().deleteCombo(combo.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Combo event deleted successfully')),
        );
      }
    }
  }

  Future<void> _toggleRegistrationStatus(ComboEvent combo) async {
    final success = await context
        .read<ComboEventsProvider>()
        .toggleRegistrationStatus(combo.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration ${!combo.registrationOpen ? 'opened' : 'closed'} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<ComboEventsProvider>().error ??
                'Failed to update registration status',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        // style: TextStyle(color: colour),
        
        // foregroundColor: ,
        iconTheme: const IconThemeData(
          color: Colors.white
        ),
        backgroundColor: const Color(0xFF1A1C1E),
        title: const Text(
          'Combo Events',
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
              builder: (context) => const ComboEventFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Combo Event',
      ),
      body: AnimatedGradientBackground(
        child: Consumer<ComboEventsProvider>(
          builder: (context, comboProvider, child) {
            if (comboProvider.isLoading) {
              return const LoadingIndicator();
            }

            if (comboProvider.error != null) {
              return ErrorDialog(
                message: comboProvider.error!,
                onRetry: () => comboProvider.fetchCombos(),
              );
            }

            final allCombos = comboProvider.combos;
            final filteredCombos = _getFilteredCombos(allCombos);

            return Column(
              children: [
                ComboEventFilterWidget(
                  onFilterChanged: _handleFilterChanged,
                  domains: _domains,
                ),
                if (_currentFilter?.hasActiveFilters == true) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Active Filters:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              if (_currentFilter?.domain != null)
                                Chip(
                                  backgroundColor: const Color(0xFF232528),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  label: Text(
                                    'Domain: ${_currentFilter!.domain}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  deleteIconColor: Colors.white70,
                                  onDeleted: () {
                                    setState(() {
                                      _currentFilter = ComboEventFilter(
                                        registrationOpen:
                                            _currentFilter?.registrationOpen,
                                        id: _currentFilter?.id,
                                      );
                                    });
                                  },
                                ),
                              if (_currentFilter?.registrationOpen != null)
                                Chip(
                                  backgroundColor: const Color(0xFF232528),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  label: Text(
                                    'Status: ${_currentFilter!.registrationOpen! ? 'Open' : 'Closed'}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  deleteIconColor: Colors.white70,
                                  onDeleted: () {
                                    setState(() {
                                      _currentFilter = ComboEventFilter(
                                        domain: _currentFilter?.domain,
                                        id: _currentFilter?.id,
                                      );
                                    });
                                  },
                                ),
                              if (_currentFilter?.id != null)
                                Chip(
                                  backgroundColor: const Color(0xFF232528),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  label: Text(
                                    'ID: ${_currentFilter!.id}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  deleteIconColor: Colors.white70,
                                  onDeleted: () {
                                    setState(() {
                                      _currentFilter = ComboEventFilter(
                                        domain: _currentFilter?.domain,
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
                  child: filteredCombos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No combo events found matching your filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${allCombos.length} combo events available',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.5),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF232528),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(1),
                          itemCount: filteredCombos.length,
                          itemBuilder: (context, index) {
                            final combo = filteredCombos[index];
                            return ComboEventCard(
                              combo: combo,
                              onEdit: () => _editCombo(combo),
                              onDelete: () => _deleteCombo(combo),
                              onToggleRegistration: () =>
                                  _toggleRegistrationStatus(combo),
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
