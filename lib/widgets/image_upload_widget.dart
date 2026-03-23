import 'dart:io';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/image_picker_helper.dart';

class ImageUploadWidget extends StatefulWidget {
  final String? initialImageUrl;
  final Function(String imageUrl) onImageUploaded;
  final String userId;
  final bool isRecipeImage;
  final double height;
  final double width;

  const ImageUploadWidget({
    super.key,
    this.initialImageUrl,
    required this.onImageUploaded,
    required this.userId,
    this.isRecipeImage = true,
    this.height = 200,
    this.width = double.infinity,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final StorageService _storageService = StorageService();
  String? _imageUrl;
  bool _isUploading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final file = await ImagePickerHelper.showImageSourceDialog(context);
      
      if (file == null) return;

      setState(() {
        _selectedImage = file;
        _isUploading = true;
      });

      String downloadUrl;
      if (widget.isRecipeImage) {
        downloadUrl = await _storageService.uploadRecipeImage(file, widget.userId);
      } else {
        downloadUrl = await _storageService.uploadProfilePicture(file, widget.userId);
      }

      setState(() {
        _imageUrl = downloadUrl;
        _isUploading = false;
      });

      widget.onImageUploaded(downloadUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _removeImage() async {
    if (_imageUrl != null) {
      try {
        await _storageService.deleteImageByUrl(_imageUrl!);
        setState(() {
          _imageUrl = null;
          _selectedImage = null;
        });
        widget.onImageUploaded('');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image removed successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing image: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 2),
      ),
      child: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading image...'),
                ],
              ),
            )
          : _imageUrl != null || _selectedImage != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                );
                              },
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _pickAndUploadImage,
                            icon: const Icon(Icons.edit),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _pickAndUploadImage,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to upload image',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
