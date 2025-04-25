import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../providers/gallery_provider.dart';
import '../widgets/custom_snackbar.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _imagePicker = ImagePicker();
  String? _selectedImagePath;
  String? _selectedYear;
  
  // Scroll controller for implementing infinite scroll
  final ScrollController _scrollController = ScrollController();
  
  // List of allowed mime types
  final List<String> _allowedMimeTypes = [
    "image/jpeg",
    "image/png", 
    "image/jpg", 
    "image/gif", 
    "image/webp", 
    "image/svg+xml",
    "image/heic",
    "image/heif",
    "image/tiff",
    "image/bmp"
  ];

  // Check if the file has a valid mime type
  bool _isValidImageType(String filePath) {
    final mimeType = lookupMimeType(filePath);
    return mimeType != null && _allowedMimeTypes.contains(mimeType);
  }

  List<String> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(
      currentYear - 2018 + 1,
      (index) => (currentYear - index).toString(),
    );
  }

  @override
  void initState() {
    super.initState();
    
    // Add scroll listener for infinite scrolling
    _scrollController.addListener(_scrollListener);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().fetchGallery();
    });
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Scroll listener for infinite scrolling
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<GalleryProvider>();
      if (!provider.isLoading && !provider.isLoadingMore && provider.hasMorePages) {
        provider.loadMoreItems();
      }
    }
  }

  Future<void> _updateImage(Map<String, dynamic> item) async {
    final yearController = TextEditingController(text: item['paridhiYear']);
    String? selectedImagePath;

    final success = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Upload Gallery Image',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedYear,
                            decoration: const InputDecoration(
                              labelText: 'Paridhi Year',
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 8),
                            ),
                            items: _years.map((String year) {
                              return DropdownMenuItem<String>(
                                value: year,
                                child: Text(year),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedYear = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a year';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              if (selectedImagePath == null)
                                const Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                )
                              else
                                SizedBox(
                                  height: 200,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(selectedImagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final XFile? image =
                                      await _imagePicker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1920,
                                    maxHeight: 1080,
                                    imageQuality: 85,
                                  );

                                  if (image != null) {
                                    // Check if the selected image has a valid mime type
                                    if (_isValidImageType(image.path)) {
                                      setState(() {
                                        selectedImagePath = image.path;
                                      });
                                      CustomSnackbar.show(
                                          context, 'Image selected successfully');
                                    } else {
                                      CustomSnackbar.show(
                                          context, 'Invalid image format. Please select a JPG, PNG, GIF, WEBP, SVG, HEIC, HEIF, TIFF or BMP image.',
                                          isError: true);
                                    }
                                  } else {
                                    CustomSnackbar.show(
                                        context, 'No image selected',
                                        isError: true);
                                  }
                                },
                                icon: const Icon(Icons.image),
                                label: Text(selectedImagePath == null
                                    ? 'Select Image'
                                    : 'Change Image'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        CustomSnackbar.show(context, 'Upload cancelled');
                        Navigator.pop(context, false);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedYear == null) {
                          CustomSnackbar.show(
                            context,
                            'Please select a year',
                            isError: true,
                          );
                          return;
                        }
                        if (selectedImagePath == null) {
                          CustomSnackbar.show(
                            context,
                            'Please select an image',
                            isError: true,
                          );
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Upload',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
    );

    if (success == true && selectedImagePath != null) {
      try {
        // Get file extension and determine content type
        final filename = selectedImagePath!.split('/').last;
        final extension = filename.split('.').last.toLowerCase();
        final contentType = _getContentTypeFromExtension(extension);
        
        if (contentType == null) {
          CustomSnackbar.show(
            context, 
            'Unsupported file format. Please use JPEG, PNG, GIF, WEBP, SVG, HEIC, HEIF, TIFF, or BMP.',
            isError: true
          );
          return;
        }
        
        final updateSuccess = await context.read<GalleryProvider>().updateImage(
              item['id'],
              yearController.text,
              selectedImagePath,
              contentType: contentType,
            );

        if (updateSuccess && mounted) {
          // Refresh the gallery list after successful update
          await context.read<GalleryProvider>().fetchGallery();
          CustomSnackbar.show(context, 'Image updated successfully');
        } else {
          final error = context.read<GalleryProvider>().error;
          CustomSnackbar.show(
            context,
            error ?? 'Failed to update image',
            isError: true,
          );
        }
      } catch (e) {
        CustomSnackbar.show(
          context,
          'Error updating image: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteImage(String id) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => navigator.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Deleting image...')),
      );

      final success = await context.read<GalleryProvider>().deleteImage(id);

      if (!mounted) return;

      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Image deleted successfully')),
        );
        await context.read<GalleryProvider>().fetchGallery();
      } else {
        final error = context.read<GalleryProvider>().error;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to delete image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error deleting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add a helper function to determine MediaType from file extension
  MediaType? _getContentTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C1E),
        title: const Text(
          'Gallery',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1C1E), Color(0xFF2C3E50)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<GalleryProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.galleryItems.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (provider.error != null && provider.galleryItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${provider.error}',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.fetchGallery(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: provider.galleryItems.length + (provider.hasMorePages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.galleryItems.length) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final item = provider.galleryItems[index];
                return Card(
                  color: Colors.white.withOpacity(0.1),
                  child: InkWell(
                    onTap: () => _showImageDialog(context, item),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['imageDetails']?['secureUrl'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => _updateImage(item),
                                icon: const Icon(Icons.edit),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _confirmDelete(context, item),
                                icon: const Icon(Icons.delete),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
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
                              'Year ${item['batchYear'] ?? 'Unknown'}',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddImageDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showImageDialog(BuildContext context, Map<String, dynamic> item) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF232528),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                'Year ${item['batchYear'] ?? 'Unknown'}',
                style: const TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: Image.network(
                item['imageDetails']?['secureUrl'] ?? '',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddImageDialog() async {
    final yearController = TextEditingController();
    String? selectedImagePath;

    final success = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xFF232528),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Upload Gallery Image',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedYear,
                      dropdownColor: const Color(0xFF232528),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Paridhi Year',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      items: _years.map((String year) {
                        return DropdownMenuItem<String>(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedYear = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a year';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (selectedImagePath == null)
                          const Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Colors.white70,
                          )
                        else
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(selectedImagePath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? image = await _imagePicker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1920,
                              maxHeight: 1080,
                              imageQuality: 85,
                            );

                            if (image != null) {
                              if (_isValidImageType(image.path)) {
                                setState(() {
                                  selectedImagePath = image.path;
                                });
                                CustomSnackbar.show(
                                    context, 'Image selected successfully');
                              } else {
                                CustomSnackbar.show(
                                    context,
                                    'Invalid image format. Please select a JPG, PNG, GIF, WEBP, SVG, HEIC, HEIF, TIFF or BMP image.',
                                    isError: true);
                              }
                            } else {
                              CustomSnackbar.show(context, 'No image selected',
                                  isError: true);
                            }
                          },
                          icon: const Icon(Icons.image, color: Colors.white),
                          label: Text(
                            selectedImagePath == null ? 'Select Image' : 'Change Image',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          CustomSnackbar.show(context, 'Upload cancelled');
                          Navigator.pop(context, false);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedYear == null) {
                            CustomSnackbar.show(
                              context,
                              'Please select a year',
                              isError: true,
                            );
                            return;
                          }
                          if (selectedImagePath == null) {
                            CustomSnackbar.show(
                              context,
                              'Please select an image',
                              isError: true,
                            );
                            return;
                          }
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Upload'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (success == true &&
        selectedImagePath != null &&
        _selectedYear != null) {
      try {
        CustomSnackbar.show(context, 'Uploading image...');
        
        // Get file extension and determine content type
        final filename = selectedImagePath!.split('/').last;
        final extension = filename.split('.').last.toLowerCase();
        final contentType = _getContentTypeFromExtension(extension);
        
        if (contentType == null) {
          CustomSnackbar.show(
            context, 
            'Unsupported file format. Please use JPEG, PNG, GIF, WEBP, SVG, HEIC, HEIF, TIFF, or BMP.',
            isError: true
          );
          return;
        }
        
        final uploadSuccess =
            await context.read<GalleryProvider>().uploadImage(
                  _selectedYear!,
                  selectedImagePath!,
                  contentType: contentType,
                );

        if (uploadSuccess && mounted) {
          CustomSnackbar.show(context, 'Image uploaded successfully');
        } else {
          final error = context.read<GalleryProvider>().error;
          CustomSnackbar.show(
            context,
            error ?? 'Failed to upload image',
            isError: true,
          );
        }
      } catch (e) {
        CustomSnackbar.show(
          context,
          'Error uploading image: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> item) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF232528),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Delete Image',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to delete this image?',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Deleting image...')),
        );

        final success = await context.read<GalleryProvider>().deleteImage(item['id']);

        if (!mounted) return;

        if (success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Image deleted successfully')),
          );
          await context.read<GalleryProvider>().fetchGallery();
        } else {
          final error = context.read<GalleryProvider>().error;
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to delete image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error deleting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
