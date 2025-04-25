import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_mrd.dart';
import '../widgets/base_screen.dart';

class UserMRD extends StatefulWidget {
  const UserMRD({super.key});

  @override
  State<UserMRD> createState() => _UserMRDState();
}

class _UserMRDState extends State<UserMRD> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _collegeController = TextEditingController();
  final _rollNoController = TextEditingController();
  String _selectedYear = 'FIRST';
  String _selectedDepartment = 'CSE';
  bool _isRegistered = false;
  Map<String, dynamic>? _registrationResponse;

  final List<String> _yearOptions = [
    'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'PASSOUT', 'ALUMNI', 'OTHER', 'NOT_APPLICABLE'
  ];

  final List<String> _departmentOptions = [
    'EE', 'BBA', 'CE', 'OTHERS', 'ECE', 'MCA', 'MBA', 'LLM', 'DS', 'BSC', 
    'MCOM', 'CSE', 'AIDS', 'ME', 'CYS', 'BCOM', 'BCA', 'LLB', 'AIML', 'IT', 
    'MA', 'MSC', 'BA', 'CSBS'
  ];

  @override
  void dispose() {
    _contactController.dispose();
    _emailController.dispose();
    _collegeController.dispose();
    _rollNoController.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF232528),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Profile Created Successfully!',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'MRD Registration Complete',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                'GID: ${_registrationResponse?['gid']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile Details:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...['name', 'email', 'contact', 'college', 'year', 'department', 'rollNo'].map((field) => 
                SelectableText(
                  '$field: ${_registrationResponse?[field]}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              Text(
                'Has Paid: ${_registrationResponse?['hasPaid'] ? 'Yes' : 'No'}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Registered At: ${_registrationResponse?['registeredAt']}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _isRegistered = false;
                _formKey.currentState?.reset();
                _contactController.clear();
                _emailController.clear();
                _collegeController.clear();
                _rollNoController.clear();
                _selectedYear = 'FIRST';
                _selectedDepartment = 'CSE';
              });
            },
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final userMrdProvider = Provider.of<UserMrd>(context, listen: false);
      
      final response = await userMrdProvider.register(
        _emailController.text.trim(),
        _contactController.text.trim(),
        _collegeController.text.trim(),
        _selectedYear,
        _selectedDepartment,
        _rollNoController.text.trim(),
      );
      
      if (response != null) {
        setState(() {
          _isRegistered = true;
          _registrationResponse = response;
        });
        _showSuccessDialog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userMrdProvider = Provider.of<UserMrd>(context);
    final isLoading = userMrdProvider.isLoading;
    final error = userMrdProvider.error;

    return BaseScreen(
      title: 'Profile Creation',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 24),
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                ),
              
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _contactController,
                label: 'Contact',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a contact number';
                  }
                  if (value.length != 10 || !RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _collegeController,
                label: 'College',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a college name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildDropdown(
                value: _selectedYear,
                label: 'Year',
                items: _yearOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedYear = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              _buildDropdown(
                value: _selectedDepartment,
                label: 'Department',
                items: _departmentOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _rollNoController,
                label: 'Roll Number',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a roll number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            errorStyle: TextStyle(color: Colors.red.shade300),
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF232528),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            errorStyle: TextStyle(color: Colors.red.shade300),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

