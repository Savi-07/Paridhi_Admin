import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paridhi_admin/widgets/animated_background.dart';
import '../providers/mrd_provider.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/mrd_details_widget.dart';

class MrdScreen extends StatefulWidget {
  const MrdScreen({super.key});

  @override
  State<MrdScreen> createState() => _MrdScreenState();
}

class _MrdScreenState extends State<MrdScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isEmailLocked = false;
  String? _selectedGid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _isEmailLocked = false;
      _selectedGid = null;
    });
  }

  Future<void> _searchMrdByEmail() async {
    final email = _searchController.text;
    if (email.isEmpty) {
      CustomSnackbar.show(
        context,
        'Please enter an email to search',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedGid = null;
    });

    try {
      final provider = context.read<MrdProvider>();
      final results = await provider.getMrdByEmail(email);

      setState(() {
        _searchResults = results;
        _isLoading = false;
        _isEmailLocked = true;
      });

      if (results.isEmpty) {
        CustomSnackbar.show(
          context,
          'User has not registered in any event',
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });

      if (e.toString().contains('Error') || e.toString().contains('failed')) {
        CustomSnackbar.show(
          context,
          '$email has not created profile',
          isError: true,
        );
      } else {
        CustomSnackbar.show(
          context,
          e.toString(),
          isError: true,
        );
      }
    }
  }

  void _onGidTap(String gid) {
    setState(() {
      _selectedGid = _selectedGid == gid ? null : gid;
    });
  }

  void _onPaymentToggled(String gid, bool newStatus) {
    setState(() {
      final index = _searchResults.indexWhere((result) => result['gid'] == gid);
      if (index != -1) {
        _searchResults[index]['hasPaid'] = newStatus;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: textColor,
        backgroundColor: const Color(0xFF1A1C1E),
        title: const Text(
          'MRD Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedGradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Box
              TextField(
                style: TextStyle(color: textColor),
                controller: _searchController,
                readOnly: _isEmailLocked,
                decoration: InputDecoration(
                  hintText: 'Enter email to search',
                  hintStyle: const TextStyle(color: Colors.white70),
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
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isEmailLocked)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: _clearSearch,
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white70),
                          onPressed: _searchMrdByEmail,
                        ),
                    ],
                  ),
                ),
                onSubmitted: (_) {
                  if (!_isEmailLocked) _searchMrdByEmail();
                },
              ),

              const SizedBox(height: 16),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (!_isLoading && _searchResults.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: Center(
                    child: Text('No results found', style: TextStyle(color: textColor)),
                  ),
                ),

              if (!_isLoading && _searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      final isSelected = _selectedGid == result['gid'];

                      return Column(
                        children: [
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            color: result['hasPaid']
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            child: ListTile(
                              title: Text('GID: ${result['gid']}', style: TextStyle(color: textColor)),
                              subtitle: Text('Email: ${result['email']}', style: TextStyle(color: textColor.withOpacity(0.8))),
                              trailing: result['hasPaid']
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : const Icon(Icons.pending, color: Colors.orange),
                              onTap: () => _onGidTap(result['gid']),
                            ),
                          ),
                          if (isSelected)
                            MrdDetailsWidget(
                              gid: result['gid'],
                              onPaymentToggled: (newStatus) =>
                                  _onPaymentToggled(result['gid'], newStatus),
                            ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
