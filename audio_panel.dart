import 'dart:async';
import 'package:flutter/material.dart';

class AudioClip {
  final String name;
  final double start; // seconds
  final double dur; // seconds
  AudioClip({required this.name, required this.start, required this.dur});
}

/// Green waveform block used on the timeline.
class AudioBlock extends StatelessWidget {
  final AudioClip clip;
  final double pps;
  const AudioBlock({super.key, required this.clip, required this.pps});

  @override
  Widget build(BuildContext context) {
    final w = clip.dur * pps - 2;
    return Container(
      width: w,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF1E4D3A),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(
            (w / 4).floor(),
            (i) => Container(
              width: 2,
              height: 4.0 + (i * 37 % 17),
              margin: const EdgeInsets.only(right: 2),
              color: const Color(0xFF58E0A0),
            ),
          ),
        ),
        Positioned(
          left: 6,
          top: 0,
          bottom: 0,
          child: Center(
            child: Text(clip.name,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

Future<AudioClip?> showAudioPanel(BuildContext context, {required double start}) {
  return showModalBottomSheet<AudioClip>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111114),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.6,
      child: _AudioPanel(start: start),
    ),
  );
}

class _Sound {
  final String name;
  final String artist;
  final int seconds;
  const _Sound(this.name, this.artist, this.seconds);
}

class _AudioPanel extends StatefulWidget {
  final double start;
  const _AudioPanel({required this.start});
  @override
  State<_AudioPanel> createState() => _AudioPanelState();
}

class _AudioPanelState extends State<_AudioPanel> {
  static const accent = Color(0xFFB9C6D4);

  // Placeholder library. Replace with real audio files / an API.
  static const trending = [
    _Sound('Sunrise Drive', 'Neon Tides', 6),
    _Sound('Lo-fi Window', 'Soft Rain', 8),
    _Sound('City Pulse', 'Metro Kid', 5),
    _Sound('Golden Hour', 'Amber Lane', 7),
    _Sound('Epic Rise', 'Northern Brass', 9),
    _Sound('Quiet Steps', 'Paper Moon', 4),
  ];
  static const saved = [
    _Sound('Weekend Mood', 'You saved this', 6),
    _Sound('Intro Sting', 'You saved this', 3),
  ];

  int tab = 0;
  int picked = -1;
  int previewing = -1;

  bool recording = false;
  int recSeconds = 0;
  Timer? _rec;

  @override
  void dispose() {
    _rec?.cancel();
    super.dispose();
  }

  void toggleRecord() {
    if (recording) {
      _rec?.cancel();
      final secs = recSeconds < 1 ? 1 : recSeconds;
      Navigator.of(context).pop(
        AudioClip(name: 'Voiceover', start: widget.start, dur: secs.toDouble()),
      );
      return;
    }
    setState(() {
      recording = true;
      recSeconds = 0;
    });
    _rec = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => recSeconds++));
  }

  @override
  Widget build(BuildContext context) {
    final list = tab == 0 ? trending : saved;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
        child: Row(children: [
          const Text('Audio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
      ),
      _tabs(),
      Expanded(child: tab == 2 ? _voiceover() : _soundList(list)),
    ]);
  }

  Widget _tabs() {
    const labels = ['Trending', 'Saved', 'Voiceover'];
    return Row(
      children: List.generate(labels.length, (i) {
        final on = i == tab;
        return Expanded(
          child: InkWell(
            onTap: () => setState(() {
              tab = i;
              picked = -1;
              previewing = -1;
            }),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(children: [
                Text(labels[i],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: on ? Colors.white : Colors.white54)),
                const SizedBox(height: 6),
                Container(height: 2, width: 24, color: on ? accent : Colors.transparent),
              ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _soundList(List<_Sound> list) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final s = list[i];
          final on = i == picked;
          final playing = i == previewing;
          return ListTile(
            onTap: () => setState(() => picked = i),
            leading: GestureDetector(
              onTap: () => setState(() => previewing = playing ? -1 : i),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E4D3A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(playing ? Icons.pause : Icons.play_arrow, color: accent),
              ),
            ),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${s.artist} · 00:0${s.seconds}',
                style: const TextStyle(fontSize: 12, color: Colors.white54)),
            trailing: on
                ? FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(64, 34),
                    ),
                    onPressed: () => Navigator.of(context).pop(
                      AudioClip(
                          name: s.name, start: widget.start, dur: s.seconds.toDouble()),
                    ),
                    child: const Text('Use', style: TextStyle(fontWeight: FontWeight.w800)),
                  )
                : null,
          );
        },
      );

  Widget _voiceover() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            recording
                ? '00:${recSeconds.toString().padLeft(2, '0')}'
                : 'Tap to start recording',
            style: TextStyle(
              fontSize: recording ? 28 : 14,
              fontWeight: FontWeight.w700,
              color: recording ? Colors.redAccent : Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: toggleRecord,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              padding: const EdgeInsets.all(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: recording ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: recording ? BorderRadius.circular(8) : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(recording ? 'Tap to stop and add' : '',
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      );
}
