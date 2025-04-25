import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rd_provider.dart';
import '../providers/events_provider.dart';
import '../widgets/rd_details_widget.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/base_screen.dart';

class RdScreen extends StatefulWidget {
  const RdScreen({super.key});

  @override
  State<RdScreen> createState() => _RdScreenState();
}

class _RdScreenState extends State<RdScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _searchResult;
  bool _isLoading = false;
  bool _isTidLocked = false;
  String? _selectedTid;
  int? _selectedEventId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().fetchEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResult = null;
      _isTidLocked = false;
      _selectedTid = null;
    });
  }

  Future<void> _searchTeamByTid() async {
    final tid = _searchController.text;
    if (tid.isEmpty) {
      CustomSnackbar.show(
        context,
        'Please enter a TID to search',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedTid = null;
    });

    try {
      final provider = context.read<RdProvider>();
      final result = await provider.getTeamByTid(tid);

      setState(() {
        _searchResult = result;
        _isLoading = false;
        _isTidLocked = true;
        _selectedTid = tid;
      });
    } catch (e) {
      setState(() {
        _searchResult = null;
        _isLoading = false;
      });

      if (mounted) {
        CustomSnackbar.show(
          context,
          'Team not found or error occurred: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _onPaymentToggled(bool newStatus) {
    setState(() {
      if (_searchResult != null) {
        _searchResult!['hasPaid'] = newStatus;
      }
    });
  }

  Widget _buildTeamsByEventList(List<Map<String, dynamic>>? teams) {
    if (teams == null || teams.isEmpty) {
      return const Center(
        child: Text(
          'No teams found for this event',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return Card(
          color: Colors.white.withOpacity(0.1),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team: ${team['teamName']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'TID: ${team['tid']}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Event: ${team['eventName']}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contacts:',
                  style: TextStyle(color: Colors.white),
                ),
                ...(team['contacts'] as List).map((contact) => Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        '${contact['name']} - ${contact['number']}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    )),
                const SizedBox(height: 8),
                Text(
                  'GIDs: ${(team['gidList'] as List).join(', ')}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Registered At: ${team['registeredAt']}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                Text(
                  'Updated At: ${team['updatedAt']}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Status: ${team['paid'] ? 'Paid' : 'Pending'}',
                      style: TextStyle(
                        color: team['paid'] ? Colors.green : Colors.red.shade300,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: team['paid'] ?? false,
                      onChanged: (value) async {
                        final provider = context.read<RdProvider>();
                        final success =
                            await provider.togglePaymentStatus(team['tid']);
                        if (success) {
                          setState(() {
                            team['paid'] = value;
                          });
                        }
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'RD Management',
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: 'Search by TID'),
          Tab(text: 'Teams by Event'),
        ],
      ),
      body: Consumer2<RdProvider, EventsProvider>(
        builder: (context, rdProvider, eventsProvider, child) {
          if (eventsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (eventsProvider.error != null) {
            return Center(
              child: Text(
                'Error loading events: ${eventsProvider.error}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            );
          }

          final events = eventsProvider.events;
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'No events available',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Search by TID Tab
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Colors.white.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          controller: _searchController,
                          readOnly: _isTidLocked,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter TID to search',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isTidLocked)
                                  IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white),
                                    onPressed: _clearSearch,
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.search, color: Colors.white),
                                    onPressed: _searchTeamByTid,
                                  ),
                              ],
                            ),
                          ),
                          onSubmitted: (_) {
                            if (!_isTidLocked) {
                              _searchTeamByTid();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (rdProvider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          rdProvider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_selectedTid != null)
                      Expanded(
                        child: RdDetailsWidget(
                          tid: _selectedTid!,
                          onPaymentToggled: _onPaymentToggled,
                        ),
                      )
                    else
                      const Expanded(
                        child: Center(
                          child: Text('Enter a TID to search'),
                        ),
                      ),
                  ],
                ),
              ),

              // Teams by Event Tab
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: DropdownButtonFormField<int>(
                          value: _selectedEventId,
                          dropdownColor: const Color(0xFF232528),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Select Event',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          items: events.map((event) {
                            return DropdownMenuItem<int>(
                              value: event.id,
                              child: Text(
                                event.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (int? value) {
                            if (value != null) {
                              setState(() {
                                _selectedEventId = value;
                              });
                              rdProvider.getTeamsByEvent(value);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedEventId == null)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Select an event to view teams',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else if (rdProvider.isLoading)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Expanded(
                        child: _buildTeamsByEventList(rdProvider.teamsByEvent),
                      ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
