import 'package:flutter/material.dart';

class AdaptiveEventImage extends StatefulWidget {
  final String? imageUrl;
  final double defaultAspectRatio;

  const AdaptiveEventImage({
    super.key,
    required this.imageUrl,
    this.defaultAspectRatio = 16 / 9,
  });

  @override
  State<AdaptiveEventImage> createState() => _AdaptiveEventImageState();
}

class _AdaptiveEventImageState extends State<AdaptiveEventImage> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveImageAspectRatio();
  }

  @override
  void didUpdateWidget(covariant AdaptiveEventImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _aspectRatio = null;
      _resolveImageAspectRatio();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return AspectRatio(
        aspectRatio: widget.defaultAspectRatio.clamp(0.6, 2.2).toDouble(),
        child: _buildFallback(),
      );
    }

    final rawAspectRatio = _aspectRatio ?? widget.defaultAspectRatio;
    final clampedAspectRatio = rawAspectRatio.clamp(0.6, 2.2).toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AspectRatio(
        aspectRatio: clampedAspectRatio,
        child: Container(
          color: const Color(0xFFF8FAFC),
          alignment: Alignment.center,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (_, __, ___) => _buildFallback(),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF94A3B8),
        size: 44,
      ),
    );
  }

  void _resolveImageAspectRatio() {
    final imageUrl = widget.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      _removeImageListener();
      return;
    }

    _removeImageListener();

    final provider = NetworkImage(imageUrl);
    final stream = provider.resolve(const ImageConfiguration());

    final listener = ImageStreamListener((ImageInfo info, bool _) {
      if (!mounted) return;

      final width = info.image.width;
      final height = info.image.height;
      if (width <= 0 || height <= 0) return;

      final ratio = width / height;
      setState(() {
        _aspectRatio = ratio;
      });
    }, onError: (Object _, StackTrace? __) {});

    _imageStream = stream;
    _imageListener = listener;
    stream.addListener(listener);
  }

  void _removeImageListener() {
    final stream = _imageStream;
    final listener = _imageListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _imageStream = null;
    _imageListener = null;
  }
}
