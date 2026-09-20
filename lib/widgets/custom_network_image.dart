import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? height;
  final double? width;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorPlaceholder();
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final parts = imageUrl.split(',');
        if (parts.length < 2) return _buildErrorPlaceholder();
        String base64String = parts.sublist(1).join(',').replaceAll(RegExp(r'\s+'), '');
        int paddingLength = 4 - (base64String.length % 4);
        if (paddingLength > 0 && paddingLength < 4) {
          base64String += '=' * paddingLength;
        }
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: fit,
          height: height,
          width: width,
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
        );
      } catch (e) {
        return _buildErrorPlaceholder();
      }
    }

    return Image.network(
      ApiService.getFullUrl(imageUrl),
      fit: fit,
      height: height,
      width: width,
      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.indigo.withValues(alpha: 0.1),
      height: height,
      width: width,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      ),
    );
  }
}
