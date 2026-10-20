import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Editorial Profile Avatar supporting progressive blur, verification ring, and graceful fallback.
class MantraProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final String? name;
  final double radius;
  final bool isBlurred;
  final double blurSigma;
  final bool isVerified;
  final VoidCallback? onTap;
  final Color? borderColor;

  const MantraProfileAvatar({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.name,
    this.radius = 28,
    this.isBlurred = false,
    this.blurSigma = 12.0,
    this.isVerified = false,
    this.onTap,
    this.borderColor,
  });

  String get _initials {
    if (name == null || name!.trim().isEmpty) return 'M';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double diameter = radius * 2;

    Widget imageContent;

    if (assetPath != null && assetPath!.isNotEmpty) {
      imageContent = Image.asset(
        assetPath!,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageContent = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _buildFallback(),
      );
    } else {
      imageContent = _buildFallback();
    }

    if (isBlurred) {
      imageContent = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: imageContent,
      );
    }

    Widget avatar = ClipOval(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: imageContent,
      ),
    );

    // Border and Trust Ring
    avatar = Container(
      width: diameter + 4,
      height: diameter + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isVerified
              ? AppColors.trust
              : (borderColor ?? AppColors.border),
          width: isVerified ? 2.0 : 1.2,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: avatar,
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildFallback() {
    return Container(
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.lora(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}
