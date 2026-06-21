import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget gambar jaringan dengan batas waktu (timeout) otomatis.
///
/// Jika gambar tidak berhasil dimuat dalam [timeoutDuration] (default 30 detik),
/// widget akan langsung menampilkan [errorWidget] alih-alih terus menampilkan
/// indikator loading tanpa batas.
class TimedCachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String) placeholder;
  final Widget Function(BuildContext, String, dynamic) errorWidget;
  final Duration timeoutDuration;

  const TimedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    required this.placeholder,
    required this.errorWidget,
    this.timeoutDuration = const Duration(seconds: 30),
  });

  @override
  State<TimedCachedImage> createState() => _TimedCachedImageState();
}

class _TimedCachedImageState extends State<TimedCachedImage> {
  Timer? _timer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer(widget.timeoutDuration, () {
      if (mounted && !_timedOut) {
        setState(() => _timedOut = true);
      }
    });
  }

  void _onImageLoaded() {
    // Gambar berhasil dimuat — batalkan timer agar tidak memicu timeout
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Jika sudah timeout, langsung tampilkan errorWidget
    if (_timedOut) {
      return widget.errorWidget(context, widget.imageUrl, 'Timeout');
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: widget.placeholder,
      errorWidget: (ctx, url, error) {
        // Jika ada error dari CachedNetworkImage sendiri, batalkan timer
        _timer?.cancel();
        return widget.errorWidget(ctx, url, error);
      },
      imageBuilder: (ctx, imageProvider) {
        // Gambar berhasil dimuat, batalkan timer
        _onImageLoaded();
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: widget.fit,
            ),
          ),
        );
      },
    );
  }
}
