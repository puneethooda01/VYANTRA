import 'dart:async';
import 'package:flutter/material.dart';

class ExportPage extends StatefulWidget {
  final double duration; // seconds
  const ExportPage({super.key, this.duration = 12});
  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  static const accent = Color(0xFFB9C6D4);
  static const resLabels = ['480p', '720p', '1080p', '2K', '4K'];
  static const resMbps = [2.0, 5.0, 10.0, 20.0, 45.0];
  static const fpsOptions = [24, 25, 30, 50, 60];

  int res = 2;
  int fps = 2;
  double quality = 0.5; // 0 lower, 1 higher
  double progress = 0;
  bool exporting = false;
  bool done = false;
  Timer? _timer;

  double get sizeMb {
    final mbps = resMbps[res] * (fpsOptions[fps] / 30) * (0.6 + quality * 0.8);
    return mbps * widget.duration / 8;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startExport() {
    setState(() {
      exporting = true;
      progress = 0;
    });
    // Simulated progress. Replace with real encoding (e.g. ffmpeg_kit_flutter).
    _timer = Timer.periodic(const Duration(milliseconds: 60), (t) {
      final next = progress + 0.012 + (progress > .8 ? 0 : 0.006);
      if (next >= 1) {
        t.cancel();
        setState(() {
          progress = 1;
          exporting = false;
          done = true;
        });
      } else {
        setState(() => progress = next);
      }
    });
  }

  void cancelExport() {
    _timer?.cancel();
    setState(() {
      exporting = false;
      progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !exporting,
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            _topBar(),
            Expanded(
              child: done ? _doneView() : (exporting ? _progressView() : _settingsView()),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: exporting ? null : () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          const Text('Export', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          const SizedBox(width: 48),
        ]),
      );

  Widget _thumb({double h = 200}) => Center(
        child: Container(
          height: h,
          width: h * 9 / 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [Color(0xFF3A5BA0), Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.play_circle_outline, size: 36, color: Colors.white70),
        ),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Text(t, style: const TextStyle(fontSize: 13, color: Colors.white70)),
      );

  Widget _chips(List<String> labels, int sel, ValueChanged<int> onSel) => SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final on = i == sel;
            return GestureDetector(
              onTap: () => onSel(i),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: on ? accent.withOpacity(.15) : const Color(0xFF17171A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? accent : Colors.transparent),
                ),
                child: Text(labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: on ? accent : Colors.white,
                    )),
              ),
            );
          },
        ),
      );

  Widget _settingsView() => Column(children: [
        Expanded(
          child: ListView(children: [
            const SizedBox(height: 8),
            _thumb(),
            _label('Resolution'),
            _chips(resLabels, res, (i) => setState(() => res = i)),
            _label('Frame rate'),
            _chips(fpsOptions.map((f) => '$f fps').toList(), fps,
                (i) => setState(() => fps = i)),
            _label('Quality'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                const SizedBox(width: 8),
                const Text('Lower', style: TextStyle(fontSize: 12, color: Colors.white54)),
                Expanded(
                  child: Slider(
                    value: quality,
                    activeColor: accent,
                    onChanged: (v) => setState(() => quality = v),
                  ),
                ),
                const Text('Higher', style: TextStyle(fontSize: 12, color: Colors.white54)),
                const SizedBox(width: 8),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Estimated size: ~${sizeMb.toStringAsFixed(1)} MB',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: startExport,
              child: const Text('Export',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ]);

  Widget _progressView() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _thumb(h: 240),
          const SizedBox(height: 28),
          Text('${(progress * 100).floor()}%',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Exporting… keep the app open',
              style: TextStyle(fontSize: 13, color: Colors.white54)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: accent,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
          TextButton(onPressed: cancelExport, child: const Text('Cancel')),
        ],
      );

  Widget _doneView() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: accent, size: 56),
          const SizedBox(height: 12),
          const Text('Saved to gallery',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${resLabels[res]} · ${fpsOptions[fps]} fps · ~${sizeMb.toStringAsFixed(1)} MB',
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 24),
          _thumb(h: 220),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
              ),
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
        ],
      );
}
