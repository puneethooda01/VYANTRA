import 'package:flutter/material.dart';

const _identity = <double>[
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

/// Applies matrix [a] after matrix [b] (4x5 color matrices).
List<double> _mul(List<double> a, List<double> b) {
  final r = List<double>.filled(20, 0);
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 5; j++) {
      double v = 0;
      for (int k = 0; k < 4; k++) {
        v += a[i * 5 + k] * b[k * 5 + j];
      }
      if (j == 4) v += a[i * 5 + 4];
      r[i * 5 + j] = v;
    }
  }
  return r;
}

List<double> _saturation(double s) {
  final sr = (1 - s) * 0.2126, sg = (1 - s) * 0.7152, sb = (1 - s) * 0.0722;
  return [
    sr + s, sg, sb, 0, 0,
    sr, sg + s, sb, 0, 0,
    sr, sg, sb + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

List<double> _contrast(double c) {
  final t = 128 * (1 - c);
  return [
    c, 0, 0, 0, t,
    0, c, 0, 0, t,
    0, 0, c, 0, t,
    0, 0, 0, 1, 0,
  ];
}

List<double> _brightness(double b) {
  final o = b * 80;
  return [
    1, 0, 0, 0, o,
    0, 1, 0, 0, o,
    0, 0, 1, 0, o,
    0, 0, 0, 1, 0,
  ];
}

List<double> _tint(double r, double g, double b) => [
      r, 0, 0, 0, 0,
      0, g, 0, 0, 0,
      0, 0, b, 0, 0,
      0, 0, 0, 1, 0,
    ];

class FilterPreset {
  final String name;
  final Color swatch;
  final List<double> matrix;
  const FilterPreset(this.name, this.swatch, this.matrix);
}

final presets = <FilterPreset>[
  const FilterPreset('Original', Color(0xFF5A5A62), _identity),
  FilterPreset('Vivid', const Color(0xFFFF5C7A), _mul(_contrast(1.1), _saturation(1.5))),
  FilterPreset('Warm', const Color(0xFFFFA64D), _tint(1.1, 1.0, 0.85)),
  FilterPreset('Cool', const Color(0xFF6EA8FF), _tint(0.9, 1.0, 1.12)),
  FilterPreset('B&W', const Color(0xFFBBBBBB), _saturation(0)),
  FilterPreset('Fade', const Color(0xFFCDB8A8), _mul(_brightness(0.15), _contrast(0.85))),
  FilterPreset('Cinema', const Color(0xFF2E8C8C),
      _mul(_tint(0.95, 1.0, 1.08), _mul(_contrast(1.2), _saturation(0.85)))),
];

class FilterSettings {
  final int preset;
  final double brightness; // -1..1
  final double contrast; // -1..1
  final double saturation; // -1..1

  const FilterSettings({
    this.preset = 0,
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
  });

  FilterSettings copyWith({int? preset, double? brightness, double? contrast, double? saturation}) =>
      FilterSettings(
        preset: preset ?? this.preset,
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
      );

  bool get isDefault =>
      preset == 0 && brightness == 0 && contrast == 0 && saturation == 0;

  List<double> get matrix {
    var m = presets[preset].matrix;
    m = _mul(_saturation(1 + saturation), m);
    m = _mul(_contrast(1 + contrast * 0.5), m);
    m = _mul(_brightness(brightness), m);
    return m;
  }

  Widget apply(Widget child) => isDefault
      ? child
      : ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: child);
}

/// Opens the panel. [onChanged] fires live so the editor preview updates.
/// Returns the final settings, or null if the person cancelled.
Future<FilterSettings?> showFiltersPanel(
  BuildContext context, {
  required FilterSettings initial,
  required ValueChanged<FilterSettings> onChanged,
}) {
  return showModalBottomSheet<FilterSettings>(
    context: context,
    barrierColor: Colors.transparent,
    backgroundColor: const Color(0xFF111114),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _FiltersPanel(initial: initial, onChanged: onChanged),
  );
}

class _FiltersPanel extends StatefulWidget {
  final FilterSettings initial;
  final ValueChanged<FilterSettings> onChanged;
  const _FiltersPanel({required this.initial, required this.onChanged});
  @override
  State<_FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<_FiltersPanel> {
  static const accent = Color(0xFFB9C6D4);
  late FilterSettings f = widget.initial;
  int tab = 0;

  void set(FilterSettings n) {
    setState(() => f = n);
    widget.onChanged(n);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 260,
        child: Column(children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(child: _tabs()),
            IconButton(
              icon: const Icon(Icons.check, color: accent),
              onPressed: () => Navigator.of(context).pop(f),
            ),
          ]),
          Expanded(child: tab == 0 ? _filterList() : _adjust()),
        ]),
      ),
    );
  }

  Widget _tabs() {
    const labels = ['Filters', 'Adjust'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(labels.length, (i) {
        final on = i == tab;
        return GestureDetector(
          onTap: () => setState(() => tab = i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(labels[i],
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: on ? Colors.white : Colors.white54)),
              const SizedBox(height: 6),
              Container(height: 2, width: 24, color: on ? accent : Colors.transparent),
            ]),
          ),
        );
      }),
    );
  }

  Widget _filterList() => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = presets[i];
          final on = i == f.preset;
          return GestureDetector(
            onTap: () => set(f.copyWith(preset: i)),
            child: Column(children: [
              Container(
                width: 72,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [p.swatch, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: on ? accent : Colors.transparent, width: 2),
                ),
              ),
              const SizedBox(height: 6),
              Text(p.name,
                  style: TextStyle(fontSize: 11, color: on ? accent : Colors.white70)),
            ]),
          );
        },
      );

  Widget _slider(String label, double v, ValueChanged<double> on) => Row(children: [
        SizedBox(
          width: 84,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ),
        Expanded(
          child: Slider(value: v, min: -1, max: 1, activeColor: accent, onChanged: on),
        ),
        SizedBox(
          width: 32,
          child: Text('${(v * 100).round()}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ),
      ]);

  Widget _adjust() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          _slider('Brightness', f.brightness, (v) => set(f.copyWith(brightness: v))),
          _slider('Contrast', f.contrast, (v) => set(f.copyWith(contrast: v))),
          _slider('Saturation', f.saturation, (v) => set(f.copyWith(saturation: v))),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => set(f.copyWith(brightness: 0, contrast: 0, saturation: 0)),
              child: const Text('Reset'),
            ),
          ),
        ]),
      );
}
