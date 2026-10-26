import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'audio_panel.dart';
import 'clip_panel.dart';
import 'effects_panel.dart';
import 'export_page.dart';
import 'filters_panel.dart';
import 'home_page.dart';
import 'text_panel.dart';
import 'video_layer.dart';

void main() => runApp(const VyantraApp());

class VyantraApp extends StatelessWidget {
  const VyantraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Vyantra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(primary: Color(0xFFB9C6D4)),
        ),
        home: const HomePage(),
      );
}

class VClip {
  final double d; // seconds on the timeline
  final Color color;
  final double speed;
  final double volume;
  final AssetEntity? asset; // null = demo clip
  final double srcStart; // seconds into the source video
  VClip(this.d, this.color,
      {this.speed = 1, this.volume = 1, this.asset, this.srcStart = 0});

  VClip copyWith({double? d, double? speed, double? volume, double? srcStart}) => VClip(
        d ?? this.d,
        color,
        speed: speed ?? this.speed,
        volume: volume ?? this.volume,
        asset: asset,
        srcStart: srcStart ?? this.srcStart,
      );
}

class EditorPage extends StatefulWidget {
  final List<AssetEntity> media;
  const EditorPage({super.key, this.media = const []});
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  static const double pps = 60; // pixels per second
  static const accent = Color(0xFFB9C6D4);
  final _sc = ScrollController();
  Timer? _timer;
  bool playing = false;
  bool editMenu = false;
  int selected = -1;
  final captions = <TextOverlay>[];
  final audioClips = <AudioClip>[];
  final effects = <EffectClip>[];
  FilterSettings filter = const FilterSettings();
  final _video = VideoSync();
  late final List<VClip> clips;

  double get total => clips.fold(0.0, (a, c) => a + c.d);
  double get time => _sc.hasClients ? _sc.offset / pps : 0;

  static const _palette = [
    Color(0xFF3A5BA0),
    Color(0xFF7A3E8C),
    Color(0xFF2F7D6B),
    Color(0xFFB8860B),
  ];

  VClip _fromAsset(AssetEntity a, Color color) {
    final secs = a.type == AssetType.video ? (a.duration < 1 ? 1 : a.duration) : 3;
    return VClip(secs.toDouble(), color, asset: a);
  }

  VClip? _clipAt(double t, void Function(double local) setLocal) {
    double acc = 0;
    for (final c in clips) {
      if (t < acc + c.d || identical(c, clips.last)) {
        setLocal(t - acc);
        return c;
      }
      acc += c.d;
    }
    return null;
  }

  void _syncVideo() {
    double local = 0;
    final c = _clipAt(time, (l) => local = l);
    _video.sync(c, local, playing);
  }

  @override
  void initState() {
    super.initState();
    clips = widget.media.isEmpty
        ? [
            VClip(4, _palette[0]),
            VClip(3, _palette[1]),
            VClip(5, _palette[2]),
          ]
        : [
            for (int i = 0; i < widget.media.length; i++)
              _fromAsset(widget.media[i], _palette[i % _palette.length]),
          ];
    _video.onChanged = () {
      if (!mounted) return;
      setState(() {});
      _syncVideo();
    };
    _sc.addListener(() {
      setState(() {});
      _syncVideo();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncVideo());
  }

  @override
  void dispose() {
    _video.dispose();
    _timer?.cancel();
    _sc.dispose();
    super.dispose();
  }

  String fmt(double s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s.floor() % 60).toString().padLeft(2, '0')}';

  void togglePlay() {
    if (playing) {
      _timer?.cancel();
      setState(() => playing = false);
      _syncVideo();
      return;
    }
    setState(() => playing = true);
    _syncVideo();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final max = _sc.position.maxScrollExtent;
      final next = _sc.offset + pps * 0.033;
      if (next >= max) {
        _sc.jumpTo(max);
        _timer?.cancel();
        setState(() => playing = false);
        _video.pauseAll();
      } else {
        _sc.jumpTo(next);
      }
    });
  }

  void split() {
    final t = time;
    double acc = 0;
    for (int i = 0; i < clips.length; i++) {
      final c = clips[i];
      if (t > acc + 0.2 && t < acc + c.d - 0.2) {
        setState(() {
          clips[i] = c.copyWith(d: t - acc);
          clips.insert(
            i + 1,
            c.copyWith(d: acc + c.d - t, srcStart: c.srcStart + (t - acc) * c.speed),
          );
        });
        return;
      }
      acc += c.d;
    }
  }

  Future<void> openFilters() async {
    final before = filter;
    final r = await showFiltersPanel(
      context,
      initial: filter,
      onChanged: (f) => setState(() => filter = f),
    );
    setState(() => filter = r ?? before);
  }

  Future<void> addEffect() async {
    final e = await showEffectsPanel(context, start: time);
    if (e != null) setState(() => effects.add(e));
  }

  Future<void> removeEffect(EffectClip e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C21),
        title: Text('Remove ${effectTypes[e.type].name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => effects.remove(e));
  }

  Future<void> addAudio() async {
    final a = await showAudioPanel(context, start: time);
    if (a != null) setState(() => audioClips.add(a));
  }

  bool _needClip() {
    if (selected >= 0 && selected < clips.length) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tap a clip on the timeline first')),
    );
    return true;
  }

  Future<void> editSpeed() async {
    if (_needClip()) return;
    final c = clips[selected];
    final r = await showSpeedPanel(context, initial: c.speed, baseDur: c.d * c.speed);
    if (r == null) return;
    setState(() => clips[selected] = c.copyWith(d: c.d * c.speed / r, speed: r));
  }

  Future<void> editVolume() async {
    if (_needClip()) return;
    final c = clips[selected];
    final r = await showVolumePanel(context, initial: c.volume);
    if (r == null) return;
    setState(() => clips[selected] = c.copyWith(volume: r));
  }

  Future<void> editText(TextOverlay c) async {
    final r = await showTextPanel(context, start: c.start, existing: c);
    if (r == null) return;
    setState(() {
      final i = captions.indexOf(c);
      if (i < 0) return;
      if (r.deleted) {
        captions.removeAt(i);
      } else {
        captions[i] = r;
      }
    });
  }

  Future<void> addText() async {
    final t = await showTextPanel(context, start: time);
    if (t != null) setState(() => captions.add(t));
  }

  void deleteSelected() {
    if (selected < 0 || clips.length < 2) return;
    setState(() {
      clips.removeAt(selected);
      selected = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _topBar(),
          Expanded(child: _preview()),
          _playbackRow(),
          SizedBox(height: 210, child: _timeline()),
          _bottomBar(),
        ]),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.close), onPressed: () {}),
          const Spacer(),
          const Text('1080P', style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 34),
            ),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ExportPage(duration: total))),
            child: const Text('Export', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  Widget _previewPicture() {
    final c = _clipAt(time, (_) {}) ?? clips.first;
    return _video.view(c);
  }

  Widget _preview() => Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(fit: StackFit.expand, children: [
                applyEffects(
                  filter.apply(
                  _previewPicture(),
                  ),
                  effects
                      .where((e) => time >= e.start && time <= e.start + e.dur)
                      .toList(),
                  time,
                ),
                ...captions
                    .where((c) => time >= c.start && time <= c.start + c.dur)
                    .map((c) => Positioned(
                          left: 8,
                          right: 8,
                          bottom: 60,
                          child: Center(child: OverlayText(c)),
                        )),
              ]),
            ),
          ),
        ),
      );

  Widget _playbackRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          Text('${fmt(time)} / ${fmt(total)}',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const Spacer(),
          IconButton(
            iconSize: 34,
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            onPressed: togglePlay,
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.undo, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.redo, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.fullscreen, size: 20), onPressed: () {}),
        ]),
      );

  Widget _timeline() => LayoutBuilder(builder: (context, cons) {
        final pad = cons.maxWidth / 2;
        final w = total * pps;
        return Stack(children: [
          SingleChildScrollView(
            controller: _sc,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: SizedBox(
              width: w,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ruler(),
                const SizedBox(height: 6),
                _videoTrack(),
                const SizedBox(height: 6),
                _audioTrack(w),
                const SizedBox(height: 6),
                _textTrack(),
                const SizedBox(height: 6),
                _effectTrack(),
              ]),
            ),
          ),
          Positioned(
            left: pad - 1,
            top: 0,
            bottom: 0,
            child: IgnorePointer(child: Container(width: 2, color: Colors.white)),
          ),
        ]);
      });

  Widget _ruler() => SizedBox(
        height: 22,
        child: Row(
          children: List.generate(
            (total / 2).ceil(),
            (i) => SizedBox(
              width: pps * 2,
              child: Text('${i * 2}s',
                  style: const TextStyle(fontSize: 10, color: Colors.white54)),
            ),
          ),
        ),
      );

  Widget _videoTrack() => Row(
        children: List.generate(clips.length, (i) {
          final c = clips[i];
          final sel = i == selected;
          return GestureDetector(
            onTap: () => setState(() => selected = sel ? -1 : i),
            child: Container(
              width: c.d * pps - 2,
              height: 56,
              margin: const EdgeInsets.only(right: 2),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: c.color,
                border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2),
              ),
              child: Stack(fit: StackFit.expand, children: [
                if (c.asset != null) AssetThumb(c.asset!, size: 160),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      '${c.d.toStringAsFixed(1)}s'
                      '${c.speed != 1 ? '  ${c.speed.toStringAsFixed(2)}x' : ''}'
                      '${c.volume == 0 ? '  🔇' : ''}',
                      style: const TextStyle(
                        fontSize: 10,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          );
        }),
      );

  Widget _audioTrack(double w) => SizedBox(
        height: 28,
        width: w,
        child: Stack(
          children: audioClips
              .map((a) => Positioned(
                    left: a.start * pps,
                    top: 0,
                    child: AudioBlock(clip: a, pps: pps),
                  ))
              .toList(),
        ),
      );

  Widget _textTrack() => SizedBox(
        height: 26,
        width: total * pps,
        child: Stack(
          children: captions
              .map((c) => Positioned(
                    left: c.start * pps,
                    width: c.dur * pps - 2,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => editText(c),
                      onHorizontalDragUpdate: (d) => setState(() {
                        final max = total - c.dur;
                        c.start = (c.start + d.delta.dx / pps)
                            .clamp(0.0, max < 0 ? 0.0 : max)
                            .toDouble();
                      }),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8860B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(c.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ))
              .toList(),
        ),
      );

  Widget _effectTrack() => SizedBox(
        height: 26,
        width: total * pps,
        child: Stack(
          children: effects
              .map((e) => Positioned(
                    left: e.start * pps,
                    width: e.dur * pps - 2,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => removeEffect(e),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B3FA0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(children: [
                          Icon(effectTypes[e.type].icon, size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(effectTypes[e.type].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11)),
                          ),
                        ]),
                      ),
                    ),
                  ))
              .toList(),
        ),
      );

  Widget _bottomBar() {
    final items = editMenu
        ? [
            _Tool(Icons.arrow_back_ios_new, 'Back', () => setState(() => editMenu = false)),
            _Tool(Icons.content_cut, 'Split', split),
            _Tool(Icons.speed, 'Speed', editSpeed),
            _Tool(Icons.volume_up, 'Volume', editVolume),
            _Tool(Icons.animation, 'Animations', () {}),
            _Tool(Icons.delete_outline, 'Delete', deleteSelected),
          ]
        : [
            _Tool(Icons.content_cut, 'Edit', () => setState(() => editMenu = true)),
            _Tool(Icons.music_note, 'Audio', addAudio),
            _Tool(Icons.text_fields, 'Text', addText),
            _Tool(Icons.layers, 'Overlay', () {}),
            _Tool(Icons.auto_awesome, 'Effects', addEffect),
            _Tool(Icons.closed_caption_outlined, 'Captions', () {}),
            _Tool(Icons.filter_vintage_outlined, 'Filters', openFilters),
          ];
    return Container(
      height: 64,
      color: const Color(0xFF0E0E10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items
            .map((t) => InkWell(
                  onTap: t.onTap,
                  child: SizedBox(
                    width: 76,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(t.icon, size: 22),
                      const SizedBox(height: 4),
                      Text(t.label, style: const TextStyle(fontSize: 10)),
                    ]),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _Tool {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _Tool(this.icon, this.label, this.onTap);
}
