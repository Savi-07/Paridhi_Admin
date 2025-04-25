import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../providers/domain_poster_provider.dart';
import '../models/domain_poster.dart';
import '../models/domain_type.dart' as domain;
import '../widgets/base_screen.dart';
import 'dart:io';

class DomainPostersScreen extends StatefulWidget {
  const DomainPostersScreen({super.key});

  @override
  State<DomainPostersScreen> createState() => _DomainPostersScreenState();
}

class _DomainPostersScreenState extends State<DomainPostersScreen> {
  final _formKey = GlobalKey<FormState>();
  domain.DomainType? _selectedDomain;
  domain.DomainType? _filterDomain;
  final _imagePicker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DomainPosterProvider>().fetchAllPosters();
    });
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _uploadPoster(BuildContext context,
      {DomainPoster? existingPoster}) async {
    if (_selectedDomain == null && existingPoster == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a domain')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (!mounted) return;

    // Close dialog immediately
    Navigator.of(context).pop();

    final provider = context.read<DomainPosterProvider>();
    final bytes = await _selectedImage!.readAsBytes();
    final filename = _selectedImage!.name;

    // Get file extension and determine content type
    final extension = filename.split('.').last.toLowerCase();
    final contentType = _getContentTypeFromExtension(extension);
    
    if (contentType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unsupported file format. Please use JPEG, PNG, GIF, WEBP, SVG, HEIC, HEIF, TIFF, or BMP.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final posterFile = MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: contentType,
    );

    final domainName = existingPoster?.domainName ?? _selectedDomain!.name;

    try {
      bool success;
      if (existingPoster != null) {
        success = await provider.updatePoster(
            existingPoster.id, domainName, posterFile);
      } else {
        success = await provider.createPoster(domainName, posterFile);
      }

      if (!mounted) return;

      if (success) {
        _selectedImage = null;
        await provider.fetchAllPosters(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingPoster != null
                ? 'Poster updated successfully'
                : 'Poster created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Handle failure case
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to process poster'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('400')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'A poster for ${domainName} already exists. Please choose a different domain or update the existing poster.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process poster: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPosterDialog(BuildContext context, {DomainPoster? poster}) async {
    _selectedDomain = poster != null
        ? domain.DomainType.values.firstWhere(
            (d) => d.name == poster.domainName,
          )
        : null;
    _selectedImage = null;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF232528),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  poster == null ? 'Add New Poster' : 'Edit Poster',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<domain.DomainType>(
                  value: _selectedDomain,
                  dropdownColor: const Color(0xFF232528),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Select Domain',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                  items: domain.DomainType.values.map((domain) {
                    return DropdownMenuItem(
                      value: domain,
                      child: Text(
                        domain.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a domain';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _selectedDomain = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.upload, color: Colors.white70),
                  label: Text(
                    _selectedImage != null
                        ? 'Change Image'
                        : poster != null
                            ? 'Change Poster Image'
                            : 'Upload Poster Image',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Selected: ${_selectedImage!.name}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_selectedImage == null && poster == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select an image'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          _handleSubmit(context, poster);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(poster == null ? 'Add' : 'Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, DomainPoster poster) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Poster'),
        content: Text(
            'Are you sure you want to delete the poster for ${poster.domainName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<DomainPosterProvider>();
      final success = await provider.deletePoster(poster.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Poster deleted successfully'
              : 'Failed to delete poster'),
        ),
      );
    }
  }

  Future<void> _handleSubmit(BuildContext context, DomainPoster? poster) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null && poster == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      await _uploadPoster(context, existingPoster: poster);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Domain Posters',
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<domain.DomainType?>(
                value: _filterDomain,
                dropdownColor: const Color(0xFF232528),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Filter by Domain',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.filter_list, color: Colors.white70),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Domains', style: TextStyle(color: Colors.white)),
                  ),
                  ...domain.DomainType.values.map((domain) {
                    return DropdownMenuItem(
                      value: domain,
                      child: Text(domain.displayName, style: const TextStyle(color: Colors.white)),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterDomain = value;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: Consumer<DomainPosterProvider>(
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

                final filteredPosters = _filterDomain != null
                    ? provider.posters
                        .where((poster) =>
                            poster.domainName == _filterDomain!.name)
                        .toList()
                    : provider.posters;

                if (filteredPosters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 64,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterDomain != null
                              ? 'No posters available for ${_filterDomain!.displayName}'
                              : 'No posters available',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredPosters.length,
                  itemBuilder: (context, index) {
                    final poster = filteredPosters[index];
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      child: InkWell(
                        onTap: () => _showPosterDialog(context, poster: poster),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                poster.posterDetails.secureUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton(
                                onPressed: () => _confirmDelete(context, poster),
                                icon: const Icon(Icons.delete),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  poster.domainName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPosterDialog(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  MediaType? _getContentTypeFromExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'svg':
        return MediaType('image', 'svg+xml');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      case 'tiff':
      case 'tif':
        return MediaType('image', 'tiff');
      case 'bmp':
        return MediaType('image', 'bmp');
      default:
        return null;
    }
  }
}
