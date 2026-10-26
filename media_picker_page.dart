import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'main.dart';
import 'video_layer.dart';

class MediaPickerPage extends StatefulWidget {
  const MediaPickerPage({super.key});
  @override
  State<MediaPickerPage> createState() => _MediaPickerPageState();
}

class _MediaPickerPageState extends State<MediaPickerPage> {
  static const accent = Color(0xFFB9C6D4);

  List<AssetEntity> items = [];
  final selected = <AssetEntity>[]; // in the order they were tapped
  int filter = 0; // 0 All, 1 Video, 2 Photo
  bool loading = true;
  bool denied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      if (mounted) {
        setState(() {
          loading = false;
          denied = true;
        });
      }
      return;
    }
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common,
    );
    final list = paths.isEmpty
        ? <AssetEntity>[]
        : await paths.first.getAssetListPaged(page: 0, size: 200);
    if (!mounted) return;
    setState(() {
      items = list;
      loading = false;
    });
  }

  List<AssetEntity> get visible => items.where((a) {
        if (filter == 1) return a.type == AssetType.video;
        if (filter == 2) return a.type == AssetType.image;
        return true;
      }).toList();

  int orderOf(AssetEntity a) => selected.indexWhere((x) => x.id == a.id);

  void toggle(AssetEntity a) => setState(() {
        final i = orderOf(a);
        i >= 0 ? selected.removeAt(i) : selected.add(a);
      });

  void add() => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => EditorPage(media: List.of(selected))),
      );

  String dur(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _topBar(),
          _tabs(),
          Expanded(child: _body()),
          _bottomBar(),
        ]),
      ),
    );
  }

  Widget _body() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (denied) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Allow access to your photos and videos'),
          TextButton(
            onPressed: PhotoManager.openSetting,
            child: const Text('Open settings'),
          ),
        ]),
      );
    }
    final list = visible;
    if (list.isEmpty) return const Center(child: Text('Nothing here yet'));
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: list.length,
      itemBuilder: (_, k) => _tile(list[k]),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          const Text('Recent', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          const SizedBox(width: 48),
        ]),
      );

  Widget _tabs() {
    const labels = ['All', 'Video', 'Photo'];
    return SizedBox(
      height: 40,
      child: Row(
        children: List.generate(labels.length, (i) {
          final on = i == filter;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => filter = i),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: on ? Colors.white : Colors.white54,
                    )),
                const SizedBox(height: 6),
                Container(height: 2, width: 24, color: on ? accent : Colors.transparent),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _tile(AssetEntity a) {
    final order = orderOf(a);
    final on = order >= 0;
    return GestureDetector(
      onTap: () => toggle(a),
      child: Stack(fit: StackFit.expand, children: [
        AssetThumb(a, size: 240),
        if (on) Container(color: Colors.black45),
        if (a.type == AssetType.video)
          Positioned(
            left: 5,
            bottom: 4,
            child: Text(dur(a.duration),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        Positioned(
          right: 5,
          top: 5,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? accent : Colors.black26,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: on
                ? Text('${order + 1}',
                    style: const TextStyle(
                        color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800))
                : null,
          ),
        ),
      ]),
    );
  }

  Widget _bottomBar() {
    final n = selected.length;
    return Container(
      height: 64,
      color: const Color(0xFF0E0E10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Text(n == 0 ? 'Select clips' : '$n selected',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: n == 0 ? Colors.white12 : accent,
            foregroundColor: n == 0 ? Colors.white38 : Colors.black,
            minimumSize: const Size(96, 40),
          ),
          onPressed: n == 0 ? null : add,
          child: Text(n == 0 ? 'Add' : 'Add ($n)',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
