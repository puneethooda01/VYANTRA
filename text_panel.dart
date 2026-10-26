import 'package:flutter/material.dart';

class TextOverlay {
  String text;
  Color color;
  double size;
  int style; // 0 Plain, 1 Bold, 2 Shadow, 3 Highlight
  double start; // seconds
  double dur; // seconds
  bool deleted;
  TextOverlay({
    required this.text,
    required this.color,
    required this.size,
    required this.style,
    required this.start,
    this.dur = 3,
    this.deleted = false,
  });
}

/// Renders a caption the same way in the panel preview and the video preview.
class OverlayText extends StatelessWidget {
  final TextOverlay o;
  const OverlayText(this.o, {super.key});

  @override
  Widget build(BuildContext context) {
    final highlight = o.style == 3;
    final base = TextStyle(
      fontSize: o.size,
      fontWeight: o.style == 0 ? FontWeight.w500 : FontWeight.w800,
      color: highlight ? Colors.black : o.color,
      shadows: o.style == 2
          ? const [Shadow(blurRadius: 6, color: Colors.black, offset: Offset(1, 2))]
          : null,
    );
    final t = Text(o.text, textAlign: TextAlign.center, style: base);
    if (!highlight) return t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: o.color, borderRadius: BorderRadius.circular(4)),
      child: t,
    );
  }
}

Future<TextOverlay?> showTextPanel(BuildContext context,
    {required double start, TextOverlay? existing}) {
  return showModalBottomSheet<TextOverlay>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111114),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _TextPanel(start: start, existing: existing),
    ),
  );
}

class _TextPanel extends StatefulWidget {
  final double start;
  final TextOverlay? existing;
  const _TextPanel({required this.start, this.existing});
  @override
  State<_TextPanel> createState() => _TextPanelState();
}

class _TextPanelState extends State<_TextPanel> {
  static const accent = Color(0xFFB9C6D4);
  static const swatches = [
    Colors.white,
    Color(0xFFFFD84D),
    Color(0xFFFF5C7A),
    Color(0xFFB9C6D4),
    Color(0xFF7CFF6B),
    Color(0xFF6EA8FF),
    Colors.black,
  ];
  static const styles = ['Plain', 'Bold', 'Shadow', 'Highlight'];

  late final TextEditingController ctrl;
  Color color = Colors.white;
  double size = 24;
  int style = 1;
  double dur = 3;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    ctrl = TextEditingController(text: e?.text ?? 'Your text');
    if (e != null) {
      color = e.color;
      size = e.size;
      style = e.style;
      dur = e.dur;
    }
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  TextOverlay build_() => TextOverlay(
        text: ctrl.text.trim().isEmpty ? ' ' : ctrl.text.trim(),
        color: color,
        size: size,
        style: style,
        start: widget.start,
        dur: dur,
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(widget.existing == null ? 'Add text' : 'Edit text',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
          Container(
            height: 90,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: OverlayText(build_()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1C1C21),
              hintText: 'Type something…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: List.generate(styles.length, (i) {
              final on = i == style;
              return ChoiceChip(
                label: Text(styles[i]),
                selected: on,
                selectedColor: accent.withOpacity(.2),
                labelStyle: TextStyle(color: on ? accent : Colors.white),
                onSelected: (_) => setState(() => style = i),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: swatches.map((c) {
              final on = c == color;
              return GestureDetector(
                onTap: () => setState(() => color = c),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: on ? accent : Colors.white24, width: on ? 3 : 1),
                  ),
                ),
              );
            }).toList(),
          ),
          Row(children: [
            const Icon(Icons.format_size, size: 18, color: Colors.white54),
            Expanded(
              child: Slider(
                value: size,
                min: 14,
                max: 48,
                activeColor: accent,
                onChanged: (v) => setState(() => size = v),
              ),
            ),
            Text('${size.round()}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ]),
          Row(children: [
            const Icon(Icons.timer_outlined, size: 18, color: Colors.white54),
            Expanded(
              child: Slider(
                value: dur,
                min: 1,
                max: 10,
                divisions: 18,
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
              onPressed: () => Navigator.of(context).pop(build_()),
              child: Text(widget.existing == null ? 'Add to timeline' : 'Save changes',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          if (widget.existing != null)
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(build_()..deleted = true),
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
        ]),
      ),
    );
  }
}
