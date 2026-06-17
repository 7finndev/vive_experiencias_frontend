import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SponsorLogo extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onTap;

  const SponsorLogo(this.imageUrl, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, 
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (_, _) => const Padding(
            padding: EdgeInsets.all(10.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (_, _, _) => const Icon(Icons.broken_image, color: Colors.grey, size: 20),
        ),
      ),
    );
  }
}