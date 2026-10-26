import 'package:flutter/material.dart';
import 'main.dart';
import 'media_picker_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _Project {
  final String name;
  final String duration;
  final String date;
  final Color color;
  const _Project(this.name, this.duration, this.date, this.color);
}

class _HomePageState extends State<HomePage> {
  static const accent = Color(0xFFB9C6D4);
  int tab = 0;

  final projects = const [
    _Project('Apex Penthouse reel', '00:12', 'Today', Color(0xFF3A5BA0)),
    _Project('Weekend vlog', '01:04', 'Yesterday', Color(0xFF7A3E8C)),
    _Project('Product teaser', '00:30', 'Oct 21', Color(0xFF2F7D6B)),
    _Project('Travel montage', '02:15', 'Oct 18', Color(0xFFB8860B)),
    _Project('Birthday clip', '00:45', 'Oct 12', Color(0xFFA03A4B)),
    _Project('Tutorial intro', '00:20', 'Oct 3', Color(0xFF3A8CA0)),
  ];

  void openPicker() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const MediaPickerPage()));

  void openEditor() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const EditorPage()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _newProject()),
          SliverToBoxAdapter(child: _quickTools()),
          SliverToBoxAdapter(child: _sectionTitle('Projects')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: projects.length,
              itemBuilder: (_, i) => _projectCard(projects[i]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0E0E10),
        indicatorColor: Colors.transparent,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.content_cut), label: 'Edit'),
          NavigationDestination(icon: Icon(Icons.dashboard_customize_outlined), label: 'Templates'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Me'),
        ],
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/logo.png', width: 34, height: 34, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFF8E9BAA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(r),
            child: const Text('VYANTRA',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: Colors.white)),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ]),
      );

  Widget _newProject() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: openPicker,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF232A31), Color(0xFF0F1318)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: accent.withOpacity(.35)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(color: accent, shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.black, size: 30),
              ),
              const SizedBox(width: 14),
              const Text('New project',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );

  Widget _quickTools() {
    const tools = [
      [Icons.auto_fix_high, 'Auto cut'],
      [Icons.closed_caption_outlined, 'Auto captions'],
      [Icons.movie_filter_outlined, 'Script to video'],
      [Icons.hd_outlined, 'Enhance'],
      [Icons.crop_outlined, 'Resize'],
    ];
    return SizedBox(
      height: 84,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => Container(
          width: 96,
          decoration: BoxDecoration(
            color: const Color(0xFF17171A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(tools[i][0] as IconData, size: 22, color: accent),
            const SizedBox(height: 6),
            Text(tools[i][1] as String, style: const TextStyle(fontSize: 11)),
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Row(children: [
          Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          const Icon(Icons.more_horiz, color: Colors.white54),
        ]),
      );

  Widget _projectCard(_Project p) => GestureDetector(
        onTap: openEditor,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [p.color, Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(p.duration, style: const TextStyle(fontSize: 10)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(p.date, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ]),
      );
}
