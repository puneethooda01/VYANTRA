import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'main.dart' show VClip;

/// Cached thumbnail of a gallery item.
class AssetThumb extends StatefulWidget {
  final AssetEntity asset;
  final int size;
  final BoxFit fit;
  const AssetThumb(this.asset, {super.key, this.size = 200, this.fit = BoxFit.cover});
  @override
  State<AssetThumb> createState() => _AssetThumbState();
}

class _AssetThumbState extends State<AssetThumb> {
  late final Future<Uint8List?> _f =
      widget.asset.thumbnailDataWithSize(ThumbnailSize.square(widget.size));

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
        future: _f,
        builder: (_, snap) {
          final d = snap.data;
          if (d == null) return const ColoredBox(color: Color(0xFF1C1C21));
          return Image.memory(d, fit: widget.fit, gaplessPlayback: true);
        },
      );
}

/// Keeps one VideoPlayerController per gallery video and keeps the
/// active one in step with the editor playhead.
class VideoSync {
  final Map<String, VideoPlayerController> _ctrls = {};
  final Set<String> _loading = {};
  VoidCallback? onChanged;
  String? _activeId;

  Future<void> _load(AssetEntity a) async {
    if (_ctrls.containsKey(a.id) || _loading.contains(a.id)) return;
    _loading.add(a.id);
    try {
      final file = await a.file;
      if (file == null) return;
      final c = VideoPlayerController.file(file);
      await c.initialize();
      _ctrls[a.id] = c;
      onChanged?.call();
    } finally {
      _loading.remove(a.id);
    }
  }

  /// [local] = seconds from the start of [clip] on the timeline.
  void sync(VClip? clip, double local, bool playing) {
    final a = clip?.asset;
    final isVideo = a != null && a.type == AssetType.video;
    if (_activeId != null && _activeId != (isVideo ? a.id : null)) {
      _ctrls[_activeId]?.pause();
    }
    _activeId = isVideo ? a.id : null;
    if (!isVideo) return;

    _load(a);
    final c = _ctrls[a.id];
    if (c == null) return;

    final src = clip!.srcStart + local * clip.speed;
    final target = Duration(milliseconds: (src * 1000).round());
    final drift = (c.value.position - target).inMilliseconds.abs();

    final vol = clip.volume.clamp(0.0, 1.0).toDouble();
    if (c.value.volume != vol) c.setVolume(vol);

    if (playing) {
      if (c.value.playbackSpeed != clip.speed) c.setPlaybackSpeed(clip.speed);
      if (drift > 350) c.seekTo(target);
      if (!c.value.isPlaying) c.play();
    } else {
      if (c.value.isPlaying) c.pause();
      if (drift > 60) c.seekTo(target);
    }
  }

  void pauseAll() {
    for (final c in _ctrls.values) {
      if (c.value.isPlaying) c.pause();
    }
  }

  /// The picture for [clip]: live video, a still, or the demo gradient.
  Widget view(VClip clip) {
    final a = clip.asset;
    if (a == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [clip.color, Colors.black],
          ),
        ),
        alignment: Alignment.center,
        child: const Text('Your video here',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      );
    }
    if (a.type == AssetType.video) {
      final c = _ctrls[a.id];
      if (c != null && c.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: c.value.size.width,
            height: c.value.size.height,
            child: VideoPlayer(c),
          ),
        );
      }
      return AssetThumb(a, size: 600);
    }
    return AssetThumb(a, size: 900);
  }

  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _ctrls.clear();
  }
}
