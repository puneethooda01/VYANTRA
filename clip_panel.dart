import 'package:flutter/material.dart';

const _accent = Color(0xFFB9C6D4);

ShapeBorder get _sheetShape => const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    );

/// Returns the new speed (0.25 to 4.0), or null if cancelled.
Future<double?> showSpeedPanel(
  BuildContext context, {
  required double initial,
  required double baseDur, // clip length at 1x, in seconds
}) {
  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: const Color(0xFF111114),
    shape: _sheetShape,
    builder: (_) => _SpeedPanel(initial: initial, baseDur: baseDur),
  );
}

/// Returns the new volume (0.0 to 2.0), or null if cancelled.
Future<double?> showVolumePanel(BuildContext context, {required double initial}) {
  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: const Color(0xFF111114),
    shape: _sheetShape,
    builder: (_) => _VolumePanel(initial: initial),
  );
}

Widget _header(BuildContext context, String title, VoidCallback onDone) => Row(children: [
      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
      Expanded(
        child: Center(
          child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
      IconButton(icon: const Icon(Icons.check, color: _accent), onPressed: onDone),
    ]);

class _SpeedPanel extends StatefulWidget {
  final double initial;
  final double baseDur;
  const _SpeedPanel({required this.initial, required this.baseDur});
  @override
  State<_SpeedPanel> createState() => _SpeedPanelState();
}

class _SpeedPanelState extends State<_SpeedPanel> {
  static const quick = [0.5, 1.0, 2.0, 3.0];
  late double speed = widget.initial;

  @override
  Widget build(BuildContext context) {
    final newDur = widget.baseDur / speed;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _header(context, 'Speed', () => Navigator.of(context).pop(speed)),
          const SizedBox(height: 8),
          Text('${speed.toStringAsFixed(2)}x',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          Text(
            'Clip length: ${widget.baseDur.toStringAsFixed(1)}s → ${newDur.toStringAsFixed(1)}s',
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          Slider(
            value: speed,
            min: 0.25,
            max: 4,
            divisions: 75,
            activeColor: _accent,
            onChanged: (v) => setState(() => speed = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: quick.map((q) {
              final on = (speed - q).abs() < 0.01;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('${q}x'),
                  selected: on,
                  selectedColor: _accent.withOpacity(.2),
                  labelStyle: TextStyle(color: on ? _accent : Colors.white),
                  onSelected: (_) => setState(() => speed = q),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }
}

class _VolumePanel extends StatefulWidget {
  final double initial;
  const _VolumePanel({required this.initial});
  @override
  State<_VolumePanel> createState() => _VolumePanelState();
}

class _VolumePanelState extends State<_VolumePanel> {
  late double volume = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _header(context, 'Volume', () => Navigator.of(context).pop(volume)),
          const SizedBox(height: 8),
          Row(children: [
            IconButton(
              icon: Icon(volume == 0 ? Icons.volume_off : Icons.volume_up,
                  color: volume == 0 ? Colors.redAccent : Colors.white),
              onPressed: () => setState(() => volume = volume == 0 ? 1 : 0),
            ),
            Expanded(
              child: Slider(
                value: volume,
                min: 0,
                max: 2,
                divisions: 40,
                activeColor: _accent,
                onChanged: (v) => setState(() => volume = v),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text('${(volume * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ),
          ]),
          const Text('Above 100% boosts the original sound',
              style: TextStyle(fontSize: 11, color: Colors.white38)),
        ]),
      ),
    );
  }
}
