import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rd_provider.dart';
import 'custom_snackbar.dart';

class RdDetailsWidget extends StatefulWidget {
  final String tid;
  final Function(bool) onPaymentToggled;

  const RdDetailsWidget({
    super.key,
    required this.tid,
    required this.onPaymentToggled,
  });

  @override
  State<RdDetailsWidget> createState() => _RdDetailsWidgetState();
}

class _RdDetailsWidgetState extends State<RdDetailsWidget> {
  @override
  void initState() {
    super.initState();
    // Schedule the fetch to happen after the initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDetails();
    });
  }

  Future<void> _fetchDetails() async {
    if (!mounted) return;

    try {
      final provider = context.read<RdProvider>();
      final details = await provider.getTeamByTid(widget.tid);

      if (!mounted) return;

      if (details == null) {
        CustomSnackbar.show(
          context,
          'No team found with TID: ${widget.tid}',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      CustomSnackbar.show(
        context,
        'Error fetching details: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<void> _togglePayment() async {
    if (!mounted) return;

    try {
      final provider = context.read<RdProvider>();
      final success = await provider.togglePaymentStatus(widget.tid);

      if (!mounted) return;

      if (success) {
        final isPaid = provider.currentTeam?['paid'] ?? false;
        widget.onPaymentToggled(isPaid);
        CustomSnackbar.show(
          context,
          'Payment status updated successfully',
        );
      } else if (provider.error != null) {
        CustomSnackbar.show(
          context,
          provider.error!,
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      CustomSnackbar.show(
        context,
        'Error updating payment status: ${e.toString()}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RdProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final details = provider.currentTeam;
        if (details == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'No team found with TID: ${widget.tid}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Validate required fields
        if (details['tid'] == null || details['teamName'] == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Invalid team data received',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Extract data with null safety
        final tid = details['tid'] ?? 'N/A';
        final teamName = details['teamName'] ?? 'N/A';
        final eventName = details['eventName'] ?? 'N/A';
        final contacts =
            List<Map<String, dynamic>>.from(details['contacts'] ?? []);
        final gidList = List<String>.from(details['gidList'] ?? []);
        final hasPaid = details['paid'] ?? false;
        final hasPlayed = details['hasPlayed'] ?? false;
        final registeredAt = details['registeredAt'] ?? 'N/A';
        final updatedAt = details['updatedAt'];
        final position = details['position'] ?? 'NONE';
        final qualified = details['qualified'] ?? false;

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                  'TID: $tid',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Team Name: $teamName'),
                Text('Event Name: $eventName'),
                Text('Has Played: ${hasPlayed ? 'Yes' : 'No'}'),
                const SizedBox(height: 16),
                Text('Team Members:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...contacts.map((contact) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  contact['name']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    contact['number']?.toString() ?? 'N/A'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                if (gidList.isNotEmpty) ...[
                  Text('GID List:',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  ...gidList.map<Widget>((gid) => Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.confirmation_number, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              gid,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Status: ${hasPaid ? 'Paid' : 'Pending'}',
                      style: TextStyle(
                        color: hasPaid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (provider.isLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Switch(
                        value: hasPaid,
                        onChanged: (_) => _togglePayment(),
                        activeColor: Colors.green,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Registered At: $registeredAt'),
                if (updatedAt != null) Text('Updated At: $updatedAt'),
              ],
            ),
          ),
        );
      },
    );
  }
}
