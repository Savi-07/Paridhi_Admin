import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contact_query_provider.dart';
import '../models/contact_query.dart';
import '../widgets/base_screen.dart';

class ContactQueriesScreen extends StatefulWidget {
  const ContactQueriesScreen({super.key});

  @override
  State<ContactQueriesScreen> createState() => _ContactQueriesScreenState();
}

class _ContactQueriesScreenState extends State<ContactQueriesScreen> {
  bool _showResolved = false;
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showResolved = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactQueryProvider>().fetchQueries(resolved: false);
    });
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  void _showResolveDialog(ContactQuery query) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232528),
        title: Row(
          children: [
            const Icon(Icons.message, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Resolve Query',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Query Details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'From: ${query.name}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Email: ${query.email}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Contact: ${query.contact}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Query',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      query.query,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Response\n(Minimum 10 characters)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _responseController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter your response here...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _responseController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_responseController.text.isNotEmpty) {
                await context.read<ContactQueryProvider>().resolveQuery(
                      query.id,
                      _responseController.text,
                      'Admin', // Replace with actual admin name
                    );
                _responseController.clear();
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Contact Queries',
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Unresolved',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: _showResolved,
                    onChanged: (value) {
                      setState(() {
                        _showResolved = value;
                      });
                      context.read<ContactQueryProvider>().fetchQueries(
                            resolved: _showResolved,
                          );
                    },
                    activeColor: Colors.green,
                  ),
                  const Text(
                    'Resolved',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<ContactQueryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          style: TextStyle(color: Colors.red.shade300),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (provider.queries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No queries found',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.queries.length,
                  itemBuilder: (context, index) {
                    final query = provider.queries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.white.withOpacity(0.1),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          query.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              query.query,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Contact: ${query.contact}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            Text(
                              'Email: ${query.email}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        trailing: query.resolved
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : TextButton(
                                onPressed: () => _showResolveDialog(query),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.blue.withOpacity(0.2),
                                ),
                                child: const Text(
                                  'Resolve',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
