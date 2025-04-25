import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../providers/team_photo_provider.dart';
import '../models/team_photo.dart';
import '../widgets/base_screen.dart';
import 'dart:io';

class TeamPosterScreen extends StatefulWidget {
  const TeamPosterScreen({super.key});

  @override
  State<TeamPosterScreen> createState() => _TeamPosterScreenState();
}

class _TeamPosterScreenState extends State<TeamPosterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  XFile? _selectedImage;
  TeamCategory? _selectedCategory;
  TeamCategory? _filterCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamPhotoProvider>().fetchAllPhotos(category: TeamCategory.MEGATRONS.name);
      _filterCategory = TeamCategory.MEGATRONS;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _uploadPhoto(BuildContext context, {TeamPhoto? photo}) async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (photo == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Close dialog immediately
    Navigator.of(context).pop();

    try {
      if (photo == null) {
        await context.read<TeamPhotoProvider>().createPhoto(
              category: _selectedCategory!.name,
              photo: _selectedImage!,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await context.read<TeamPhotoProvider>().updatePhoto(
              id: photo.id,
              category: _selectedCategory!.name,
              photo: _selectedImage!,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      setState(() {
        _selectedImage = null;
        _selectedCategory = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPhotoDialog(BuildContext context, {TeamPhoto? photo}) {
    if (photo != null) {
      _selectedCategory = TeamCategory.fromName(photo.category);
    } else {
      _selectedCategory = null;
    }
    _selectedImage = null;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF232528),
          title: Text(
            photo == null ? 'Add Team Photo' : 'Edit Team Photo',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.white.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DropdownButtonFormField<TeamCategory>(
                        value: _selectedCategory ?? TeamCategory.DEVELOPERS,
                        dropdownColor: const Color(0xFF232528),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        items: TeamCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedImage != null) ...[
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.error_outline, color: Colors.red),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (photo != null) ...[
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photo.secureUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.error_outline, color: Colors.red),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton.icon(
                    onPressed: () => _pickImage().then((_) => setState(() {})),
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: Text(
                      _selectedImage != null ? 'Change Image' : 'Select Image',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _uploadPhoto(context, photo: photo),
                      icon: const Icon(Icons.upload, color: Colors.white),
                      label: Text(
                        photo != null ? 'Update Photo' : 'Submit Photo',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _selectedImage = null;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TeamPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF232528),
        title: const Text(
          'Delete Photo',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete the photo for ${photo.category}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade300,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<TeamPhotoProvider>().deletePhoto(photo.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Team Posters',
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<TeamCategory>(
                value: _filterCategory,
                dropdownColor: const Color(0xFF232528),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Filter by Category',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                items: TeamCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _filterCategory = value);
                    context
                        .read<TeamPhotoProvider>()
                        .fetchAllPhotos(category: value.name);
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Consumer<TeamPhotoProvider>(
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

                if (provider.photos.isEmpty) {
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
                          'No photos found',
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
                  itemCount: provider.photos.length,
                  itemBuilder: (context, index) {
                    final photo = provider.photos[index];
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      child: InkWell(
                        onTap: () => _showPhotoDialog(context, photo: photo),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                photo.secureUrl,
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
                                onPressed: () => _confirmDelete(context, photo),
                                icon: const Icon(Icons.delete),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
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
        onPressed: () => _showPhotoDialog(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
