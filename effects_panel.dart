import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

class EffectType {
  final String name;
  final IconData icon;
  const EffectType(this.name, this.icon);
}

const effectTypes = [
  EffectType('Blur', Icons.blur_on),
  EffectType('Shake', Icons.vibration),
  EffectType('Glitch', Icons.tv),
  EffectType('Vignette', Icons.vignette),
  EffectType('Flash', Icons.flash_on),
];

class EffectClip {
  final int type; // index into effectTypes
  final double start; // seconds
  final double dur; // seconds
  final double intensity; // 0..1
  const EffectClip({
    required this.type,
    required this.start,
    this.dur = 3,
    this.intensity = 0.6,
  });
}

/// Wraps [child] with every effect in [active], using [t] (seconds) for motion.
Widget applyEffects(Widget child, List<EffectClip> active, double t) {
  Widget w = child;
  for (final e in active) {
    final i = e.intensity;
    switch (e.type) {
      case 0: // Blur
        final s = 0.1 + i * 12;
        w = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: s, sigmaY: s), child: w);
        break;
      case 1: // Shake
        w = Transform.translate(
          offset: Offset(math.sin(t * 45) * i * 10, math.cos(t * 53) * i * 10),
          child: w,
        );
        break;
      case 2: // Glitch
        final k = math.sin(t * 30) >= 0 ? 1.0 : -1.0;
        w = Stack(fit: StackFit.expand, children: [
          w,
          Opacity(
            opacity: 0.45 * i + 0.1,
            child: Transform.translate(
              offset: Offset(-7 * i * k, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Color(0xFFFF0000), BlendMode.modulate),
                child: w,
              ),
            ),
          ),
          Opacity(
            opacity: 0.45 * i + 0.1,
            child: Transform.translate(
              offset: Offset(7 * i * k, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Color(0xFF00FFFF), BlendMode.modulate),
                child: w,
              ),
            ),
          ),
        ]);
        break;
      case 3: // Vignette
        w = Stack(fit: StackFit.expand, children: [
          w,
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.95,
                  colors: [Colors.transparent, Colors.black.withOpacity(i * 0.9)],
                  stops: const [0.45, 1],
                ),
              ),
            ),
          ),
        ]);
        break;
      case 4: // Flash
        final a = (math.sin(t * 9).abs() * i * 0.7).clamp(0.0, 1.0);
        w = Stack(fit: StackFit.expand, children: [
          w,
          IgnorePointer(child: ColoredBox(color: Colors.white.withOpacity(a))),
        ]);
        break;
    }
  }
  return w;
}

Future<EffectClip?> showEffectsPanel(BuildContext context, {required double start}) {
  return showModalBottomSheet<EffectClip>(
    context: context,
    backgroundColor: const Color(0xFF111114),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _EffectsPanel(start: start),
  );
}

class _EffectsPanel extends StatefulWidget {
  final double start;
  const _EffectsPanel({required this.start});
  @override
  State<_EffectsPanel> createState() => _EffectsPanelState();
}

class _EffectsPanelState extends State<_EffectsPanel> {
  static const accent = Color(0xFFB9C6D4);
  int type = 0;
  double intensity = 0.6;
  double dur = 3;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('Effects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: effectTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final on = i == type;
                return GestureDetector(
                  onTap: () => setState(() => type = i),
                  child: Container(
                    width: 74,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C21),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: on ? accent : Colors.transparent, width: 2),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(effectTypes[i].icon, color: on ? accent : Colors.white70),
                      const SizedBox(height: 6),
                      Text(effectTypes[i].name,
                          style: TextStyle(fontSize: 11, color: on ? accent : Colors.white70)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            const SizedBox(
              width: 70,
              child: Text('Intensity', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ),
            Expanded(
              child: Slider(
                value: intensity,
                activeColor: accent,
                onChanged: (v) => setState(() => intensity = v),
              ),
            ),
            Text('${(intensity * 100).round()}',
                style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ]),
          Row(children: [
            const SizedBox(
              width: 70,
              child: Text('Duration', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ),
            Expanded(
              child: Slider(
                value: dur,
                min: 1,
                max: 8,
                divisions: 14,
                activeColor: accent,
                onChanged: (v) => setState(() => dur = v),
              ),
            ),
            Text('${dur.toStringAsFixed(1)}s',
                style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ]),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
              ),
              onPressed: () => Navigator.of(context).pop(
                EffectClip(type: type, start: widget.start, dur: dur, intensity: intensity),
              ),
              child: const Text('Add to timeline',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}
