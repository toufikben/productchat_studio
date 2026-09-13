import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _picker = ImagePicker();
  String? _imagePath;
  String? _error;

  Future<void> _pickImage() async {
    setState(() => _error = null);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 95,
      );
      if (!mounted || image == null) return;
      setState(() => _imagePath = image.path);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to select image: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ProductChat Studio')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _imagePath == null
                    ? const Center(
                        child: Text('Select a product image to begin Smart Analysis'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(File(_imagePath!), fit: BoxFit.contain),
                      ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              Semantics(
                button: true,
                label: _imagePath == null ? 'Select product image' : 'Change image',
                child: FilledButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: Text(_imagePath == null ? 'Select product image' : 'Change image'),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: 'Open editor',
                child: FilledButton(
                  onPressed: _imagePath == null
                      ? null
                      : () => context.push('/editor?imagePath=${Uri.encodeComponent(_imagePath!)}'),
                  child: const Text('Open editor'),
                ),
              ),
            ],
          ),
        ),
      );
}
