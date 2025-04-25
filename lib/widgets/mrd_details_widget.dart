import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mrd_provider.dart';
import 'custom_snackbar.dart';

class MrdDetailsWidget extends StatefulWidget {
  final String gid;
  final Function(bool) onPaymentToggled;

  const MrdDetailsWidget({
    super.key,
    required this.gid,
    required this.onPaymentToggled,
  });

  @override
  State<MrdDetailsWidget> createState() => _MrdDetailsWidgetState();
}

class _MrdDetailsWidgetState extends State<MrdDetailsWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _details;
  bool _isUpdatingPayment = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<MrdProvider>();
      final details = await provider.getMrdByGid(widget.gid);
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackbar.show(
          context,
          'Error fetching details: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _togglePayment() async {
    if (_isUpdatingPayment) return;

    setState(() {
      _isUpdatingPayment = true;
    });

    try {
      final provider = context.read<MrdProvider>();
      final updatedDetails = await provider.togglePaymentStatus(widget.gid);
      setState(() {
        _details = updatedDetails;
        _isUpdatingPayment = false;
      });
      if (mounted) {
        widget.onPaymentToggled(updatedDetails['hasPaid']);
        CustomSnackbar.show(
          context,
          'Payment status updated successfully',
        );
      }
    } catch (e) {
      setState(() {
        _isUpdatingPayment = false;
      });
      if (mounted) {
        CustomSnackbar.show(
          context,
          'Error updating payment status: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_details == null) {
      return const Center(child: Text('No details available'));
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              'GID: ${_details!['gid']}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Name: ${_details!['name']}'),
            Text('Email: ${_details!['email']}'),
            Text('Contact: ${_details!['contact'] ?? 'N/A'}'),
            Text('College: ${_details!['college'] ?? 'N/A'}'),
            Text('Year: ${_details!['year'] ?? 'N/A'}'),
            Text('Department: ${_details!['department'] ?? 'N/A'}'),
            Text('Roll No: ${_details!['rollNo'] ?? 'N/A'}'),
            Text('Registered At: ${_details!['registeredAt']}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Status: ${_details!['hasPaid'] ? 'Paid' : 'Pending'}',
                  style: TextStyle(
                    color: _details!['hasPaid'] ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _details!['hasPaid'],
                  onChanged: (_) => _togglePayment(),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
