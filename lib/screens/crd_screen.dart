import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crd_provider.dart';
import '../providers/events_provider.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/base_screen.dart';

class CrdScreen extends StatefulWidget {
  const CrdScreen({super.key});

  @override
  State<CrdScreen> createState() => _CrdScreenState();
}

class _CrdScreenState extends State<CrdScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch events and teams when the screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().fetchEvents();
      final selectedEventId = context.read<CrdProvider>().selectedEventId;
      if (selectedEventId != null) {
        context.read<CrdProvider>().fetchPrelimsTeams(selectedEventId);
        context.read<CrdProvider>().fetchFinalsTeams(selectedEventId);
      }
    });
  }

  Widget _buildTeamCard(Map<String, dynamic> team, bool isFinals) {
    return Card(
      elevation: 4,
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
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
            const SizedBox(height: 12),
            Text(
              'TID: ${team['tid']}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Event: ${team['eventName']}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              'Contacts:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            ...(team['contacts'] as List).map((contact) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                  child: Text(
                    '${contact['name']} - ${contact['number']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )),
            const SizedBox(height: 12),
            Text(
              'GIDs: ${(team['gidList'] as List).join(', ')}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              'Registered At: ${team['registeredAt']}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Updated At: ${team['updatedAt']}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Paid: ${team['paid'] ? 'Yes' : 'No'}',
              style: TextStyle(
                color: team['paid'] ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Has Played',
                      style: TextStyle(color: Colors.white),
                    ),
                    Switch(
                      value: team['hasPlayed'] ?? false,
                      activeColor: Colors.green,
                      onChanged: (value) async {
                        final provider = context.read<CrdProvider>();
                        final success =
                            await provider.toggleHasPlayed(team['tid']);
                        if (!success && mounted) {
                          CustomSnackbar.show(
                            context,
                            team['qualified'] ?? false
                                ? 'Remove team from qualification first'
                                : 'Failed to update has played status',
                            isError: true,
                          );
                        }
                      },
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Qualified',
                      style: TextStyle(color: Colors.white),
                    ),
                    Switch(
                      value: team['qualified'] ?? false,
                      activeColor: Colors.green,
                      onChanged: (value) async {
                        final provider = context.read<CrdProvider>();
                        final success =
                            await provider.toggleQualified(team['tid']);
                        if (!success && mounted) {
                          CustomSnackbar.show(
                            context,
                            'Team can\'t qualify until they have played',
                            isError: true,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (isFinals) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: team['position'] ?? 'NONE',
                dropdownColor: Colors.grey[850],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Position',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'NONE',
                    child: Text('None', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'FIRST',
                    child: Text('1st', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'SECOND',
                    child: Text('2nd', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'THIRD',
                    child: Text('3rd', style: TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (String? value) async {
                  if (value != null) {
                    final provider = context.read<CrdProvider>();
                    final success =
                        await provider.updatePosition(team['tid'], value);
                    if (!success && mounted) {
                      CustomSnackbar.show(
                        context,
                        'Failed to update position',
                        isError: true,
                      );
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamList(List<Map<String, dynamic>>? teams, bool isFinals) {
    if (teams == null || teams.isEmpty) {
      return Center(
        child: Text(
          'No ${isFinals ? 'Finals' : 'Prelims'} teams found',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    final filteredTeams = teams.where((team) {
      final hasPlayed = team['hasPlayed'] ?? false;
      final qualified = team['qualified'] ?? false;

      if (isFinals) {
        return hasPlayed && qualified;
      } else {
        return true;
      }
    }).toList();

    if (filteredTeams.isEmpty) {
      return Center(
        child: Text(
          'No ${isFinals ? 'Finals' : 'Prelims'} teams found',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTeams.length,
      itemBuilder: (context, index) {
        final team = filteredTeams[index];
        return _buildTeamCard(team, isFinals);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'CRD Management',
      body: Consumer2<CrdProvider, EventsProvider>(
        builder: (context, crdProvider, eventsProvider, child) {
          if (eventsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          if (eventsProvider.error != null) {
            return Center(
              child: Text(
                'Error loading events: ${eventsProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final events = eventsProvider.events;
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'No events available',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Event Selection Dropdown
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Colors.grey[850],
                  ),
                  child: DropdownButtonFormField<int>(
                    value: crdProvider.selectedEventId,
                    dropdownColor: Colors.grey[850],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Select Event',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
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
                        crdProvider.setSelectedEventId(value);
                        crdProvider.fetchPrelimsTeams(value);
                        crdProvider.fetchFinalsTeams(value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (crdProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      crdProvider.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TabBar(
                            tabs: const [
                              Tab(text: 'Prelims'),
                              Tab(text: 'Finals'),
                            ],
                            indicator: BoxDecoration(
                              // color: const Color(0xFF1A1C1E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey[400],
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Prelims Tab
                              crdProvider.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    )
                                  : _buildTeamList(
                                      crdProvider.prelimsTeams, false),
                              // Finals Tab
                              crdProvider.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    )
                                  : _buildTeamList(
                                      crdProvider.finalsTeams, true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
