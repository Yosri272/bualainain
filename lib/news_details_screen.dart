import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'widgets/custom_bottom_nav.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class NewsDetailsScreen extends StatelessWidget {
  const NewsDetailsScreen({super.key});

  static const Color textColor = Color(0xff53617F);

  @override
  Widget build(BuildContext context) {
    final newsId = ModalRoute.of(context)?.settings.arguments as String?;
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _header(),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/news',
                          (route) => false,
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new,
                        size: 15,
                        color: textColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'العودة',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 26),

            Expanded(
              child: newsId == null
                  ? const Center(child: Text('لم يتم العثور على الخبر'))
                  : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('news')
                    .doc(newsId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Text('الخبر غير موجود'),
                    );
                  }

                  final data =
                  snapshot.data!.data() as Map<String, dynamic>;
                  final Timestamp? createdAt = data['createdAt'];
                  final String formattedDate = createdAt != null
                      ? DateFormat('dd.MM.yyyy').format(createdAt.toDate())
                      : '';
                  final categoryName = data['categoryName'] ?? '';
                  final city = data['city'] ?? '';
                  final title = data['title'] ?? '';
                  final content = data['content'] ?? '';

                  // =========================
                  // نفس منطق دعم الفيديو/الصورة المستخدم في NewsScreen
                  // يدعم الأخبار الجديدة (mediaType/mediaUrl) والقديمة
                  // (imageUrl/videoUrl)
                  // =========================
                  final String videoUrl =
                  (data['videoUrl'] ?? '').toString().trim();
                  final String imageUrl =
                  (data['imageUrl'] ?? '').toString().trim();
                  final String savedMediaType =
                  (data['mediaType'] ?? '').toString().trim().toLowerCase();
                  final bool isVideo =
                      savedMediaType == 'video' || videoUrl.isNotEmpty;
                  final String mediaUrl = (data['mediaUrl'] ??
                      (isVideo ? videoUrl : imageUrl))
                      .toString()
                      .trim();
                  final String thumbnailUrl =
                  (data['thumbnailUrl'] ?? '').toString().trim();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 248,
                            width: double.infinity,
                            child: isVideo
                                ? _NewsVideoPlayer(
                              videoUrl: mediaUrl,
                              thumbnailUrl: thumbnailUrl,
                            )
                                : (mediaUrl.isNotEmpty
                                ? Image.network(
                              mediaUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Image.asset(
                                  'assets/images/news.png',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                                : Image.asset(
                              'assets/images/news.png',
                              fit: BoxFit.cover,
                            )),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          '$categoryName | $city | $formattedDate',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xff9A9A9A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          title,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 22),

                        Text(
                          content,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xff222222),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.9,
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),

            const CustomBottomNav(selectedIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/header_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// مشغل فيديو الخبر: بيعرض صورة مصغرة (thumbnail) مع زرار بلاي في النص،
/// ولما يتضغط بيبدأ يحمّل الفيديو ويشغله بعناصر تحكم بسيطة (play/pause).
class _NewsVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;

  const _NewsVideoPlayer({
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  @override
  State<_NewsVideoPlayer> createState() => _NewsVideoPlayerState();
}

class _NewsVideoPlayerState extends State<_NewsVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitializing = false;
  bool _hasError = false;
  bool _started = false;

  Future<void> _startPlayback() async {
    if (widget.videoUrl.trim().isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    setState(() {
      _started = true;
      _isInitializing = true;
      _hasError = false;
    });

    try {
      final controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });

      controller.play();
      controller.setLooping(false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // قبل ما المستخدم يدوس بلاي: نعرض الصورة المصغرة مع زرار التشغيل
    if (!_started) {
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.thumbnailUrl.isNotEmpty
              ? Image.network(
            widget.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Image.asset('assets/images/news.png', fit: BoxFit.cover);
            },
          )
              : Image.asset('assets/images/news.png', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.25)),
          Center(
            child: InkWell(
              onTap: _startPlayback,
              borderRadius: BorderRadius.circular(50),
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        ],
      );
    }

    if (_hasError) {
      return Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            const Text(
              'تعذر تشغيل الفيديو',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _startPlayback,
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_isInitializing || _controller == null) {
      return Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white),
      );
    }

    final controller = _controller!;

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),

        // زرار play/pause في المنتصف
        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
            borderRadius: BorderRadius.circular(50),
            child: AnimatedOpacity(
              opacity: controller.value.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
        ),

        // شريط تقدّم بسيط أسفل الفيديو
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            colors: const VideoProgressColors(
              playedColor: Colors.white,
              bufferedColor: Colors.white38,
              backgroundColor: Colors.white12,
            ),
          ),
        ),
      ],
    );
  }
}