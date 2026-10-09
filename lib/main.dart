import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdhkarStore.init();
  runApp(const AdhkarApp());
}

class Dhikr {
  Dhikr({required this.id, required this.category, required this.text, required this.reference, required this.target, this.count = 0, this.favorite = false});
  final String id;
  final String category;
  final String text;
  final String reference;
  final int target;
  int count;
  bool favorite;
  Map<String, dynamic> toJson() => {'id': id, 'count': count, 'favorite': favorite};
}

final dhikrCatalog = <Dhikr>[
  Dhikr(id: 'morning-1', category: 'أذكار الصباح', text: 'أصبحنا وأصبح الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير. رب أسألك خير ما في هذا اليوم وخير ما بعده، وأعوذ بك من شر ما في هذا اليوم وشر ما بعده. رب أعوذ بك من الكسل وسوء الكبر، رب أعوذ بك من عذاب في النار وعذاب في القبر.', reference: 'صحيح مسلم (2723)', target: 1),
  Dhikr(id: 'morning-2', category: 'أذكار الصباح والمساء', text: 'رضيت بالله ربًا، وبالإسلام دينًا، وبمحمد صلى الله عليه وسلم نبيًا.', reference: 'أصل الذكر: صحيح مسلم (1884)؛ ورواية ثلاث مرات: أبو داود والترمذي والنسائي وأحمد', target: 3),
  Dhikr(id: 'evening-1', category: 'أذكار المساء', text: 'أمسينا وأمسى الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير. رب أسألك خير ما في هذه الليلة وخير ما بعدها، وأعوذ بك من شر ما في هذه الليلة وشر ما بعدها. رب أعوذ بك من الكسل وسوء الكبر، رب أعوذ بك من عذاب في النار وعذاب في القبر.', reference: 'صحيح مسلم (2723)', target: 1),
  Dhikr(id: 'sleep-1', category: 'أذكار النوم', text: 'باسمك اللهم أموت وأحيا.', reference: 'صحيح البخاري (6324)', target: 1),
  Dhikr(id: 'after-prayer-1', category: 'بعد الصلاة', text: 'أستغفر الله، أستغفر الله، أستغفر الله.', reference: 'صحيح مسلم (591)؛ بعد السلام من الصلاة', target: 3),
  Dhikr(id: 'general-1', category: 'أذكار متنوعة', text: 'سبحان الله وبحمده، سبحان الله العظيم.', reference: 'متفق عليه: البخاري (6682) ومسلم (2694)؛ العدد هنا مفتوح', target: 1),
  Dhikr(id: 'morning-3', category: 'أذكار الصباح والمساء', text: 'سبحان الله وبحمده.', reference: 'صحيح مسلم (2692)؛ مائة مرة صباحًا ومساءً', target: 100),
];

class AdhkarStore {
  static late SharedPreferences prefs;
  static const progressKey = 'adhkar_progress';
  static const themeKey = 'adhkar_dark';
  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(progressKey);
    if (raw == null) return;
    final saved = jsonDecode(raw) as Map<String, dynamic>;
    for (final item in dhikrCatalog) {
      final data = saved[item.id] as Map<String, dynamic>?;
      if (data != null) {
        item.count = data['count'] as int? ?? 0;
        item.favorite = data['favorite'] as bool? ?? false;
      }
    }
  }
  static Future<void> save() async => prefs.setString(progressKey, jsonEncode({for (final d in dhikrCatalog) d.id: d.toJson()}));
}

class AdhkarApp extends StatefulWidget {
  const AdhkarApp({super.key});
  @override State<AdhkarApp> createState() => _AdhkarAppState();
}
class _AdhkarAppState extends State<AdhkarApp> {
  bool dark = AdhkarStore.prefs.getBool(AdhkarStore.themeKey) ?? false;
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'اذكار', theme: AdhkarTheme.light, darkTheme: AdhkarTheme.dark,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: HomePage(onTheme: () { setState(() => dark = !dark); AdhkarStore.prefs.setBool(AdhkarStore.themeKey, dark); }),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onTheme});
  final VoidCallback onTheme;
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab = 0;
  String category = 'الكل';
  String search = '';
  final categories = const ['الكل', 'أذكار الصباح', 'أذكار المساء', 'أذكار الصباح والمساء', 'أذكار النوم', 'بعد الصلاة', 'أذكار متنوعة'];
  List<Dhikr> get visible => dhikrCatalog.where((d) => (category == 'الكل' || d.category == category) && (search.isEmpty || d.text.contains(search) || d.category.contains(search))).toList();
  int get completed => dhikrCatalog.where((d) => d.count >= d.target).length;
  void refresh() { setState(() {}); AdhkarStore.save(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('رفيق الأذكار', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: widget.onTheme, icon: const Icon(Icons.brightness_6_outlined))]),
    body: IndexedStack(index: tab, children: [_home(), _favorites(), _settings()]),
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'), NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'المفضلة'), NavigationDestination(icon: Icon(Icons.tune_outlined), label: 'الإعدادات')]),
  );
  Widget _home() => ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: [
    _hero(), const SizedBox(height: 18), TextField(onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث في الأذكار', filled: true, border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(18))))),
    const SizedBox(height: 14), SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: categories.map((c) => Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(c), selected: category == c, onSelected: (_) => setState(() => category = c)))).toList())),
    const SizedBox(height: 18), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('وردك اليومي', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), Text('$completed/${dhikrCatalog.length}', style: const TextStyle(color: AdhkarTheme.primary, fontWeight: FontWeight.bold))]),
    const SizedBox(height: 10), ...visible.map(_dhikrCard),
  ]);
  Widget _hero() { final progress = completed / dhikrCatalog.length; return Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF146B5A), Color(0xFF2C9A80)]), borderRadius: BorderRadius.circular(28)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('طمأنينة تبدأ بذكر', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(progress >= 1 ? 'أتممت وردك اليوم' : 'أكمل وردك اليوم بخطوات هادئة', style: const TextStyle(color: Colors.white70)), const SizedBox(height: 16), LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white24, color: Colors.white)])), const SizedBox(width: 18), SizedBox(width: 70, height: 70, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: progress, color: Colors.white, backgroundColor: Colors.white24, strokeWidth: 7), Text('${(progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))])); }
  Widget _dhikrCard(Dhikr d) { final done = d.count >= d.target; return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(d.category, style: const TextStyle(color: AdhkarTheme.primary, fontWeight: FontWeight.bold))), IconButton(onPressed: () { d.favorite = !d.favorite; refresh(); }, icon: Icon(d.favorite ? Icons.favorite : Icons.favorite_border, color: d.favorite ? Colors.redAccent : null))]), Text(d.text, style: const TextStyle(fontSize: 18, height: 1.8, fontWeight: FontWeight.w600)), const SizedBox(height: 8), Text(d.reference, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 14), Row(children: [Expanded(child: LinearProgressIndicator(value: d.count / d.target, minHeight: 7, color: done ? AdhkarTheme.secondary : AdhkarTheme.primary)), const SizedBox(width: 12), Text('${d.count}/${d.target}', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8), IconButton(onPressed: () { if (d.count < d.target) d.count++; else d.count = 0; refresh(); }, icon: Icon(done ? Icons.check_circle : Icons.add_circle, color: done ? AdhkarTheme.secondary : AdhkarTheme.primary, size: 32))])]))); }
  Widget _favorites() { final items = dhikrCatalog.where((d) => d.favorite).toList(); return items.isEmpty ? const Center(child: Text('لم تضف أذكارًا إلى المفضلة بعد')) : ListView(padding: const EdgeInsets.all(18), children: [Text('أذكاري المفضلة', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 16), ...items.map(_dhikrCard)]); }
  Widget _settings() => ListView(padding: const EdgeInsets.all(18), children: [Text('الإعدادات', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 14), Card(child: Column(children: [ListTile(leading: const Icon(Icons.dark_mode_outlined), title: const Text('الوضع الداكن'), trailing: Switch(value: Theme.of(context).brightness == Brightness.dark, onChanged: (_) => widget.onTheme())), const Divider(height: 1), ListTile(leading: const Icon(Icons.restart_alt), title: const Text('تصفير التقدم'), onTap: () { for (final d in dhikrCatalog) d.count = 0; refresh(); })]))]);
}