import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Circular avatar: [photoBytes] if set, otherwise [initials].
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.radius,
    required this.initials,
    this.photoBytes,
    this.backgroundColor,
    this.initialsStyle,
  });

  final double radius;
  final String initials;
  final Uint8List? photoBytes;
  final Color? backgroundColor;
  final TextStyle? initialsStyle;

  bool get _hasPhoto => photoBytes != null && photoBytes!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ??
          Theme.of(context).colorScheme.primary,
      backgroundImage: _hasPhoto ? MemoryImage(photoBytes!) : null,
      child: _hasPhoto
          ? null
          : Text(
              initials.isNotEmpty ? initials : '?',
              style: initialsStyle ??
                  TextStyle(
                    fontSize: radius * 0.85,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
    );
  }
}
