import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../viewmodels/profile_view_model.dart';

/// Bottom sheet: choose gallery, camera, or remove photo.
Future<void> showProfilePhotoOptions(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAndApply(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAndApply(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove profile picture'),
              onTap: () {
                Navigator.pop(ctx);
                if (context.mounted) {
                  context.read<ProfileViewModel>().clearProfilePhoto();
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _pickAndApply(BuildContext context, ImageSource source) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: source,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 88,
  );
  if (file == null || !context.mounted) return;

  final bytes = await file.readAsBytes();
  if (!context.mounted) return;

  context.read<ProfileViewModel>().setProfilePhotoBytes(bytes);
}
