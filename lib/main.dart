import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auto Update Demo',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String currentVersion = '';
  String latestVersion = '';
  String apkUrl = '';

  @override
  void initState() {
    super.initState();
    loadCurrentVersion();
  }

  Future<void> loadCurrentVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      currentVersion = packageInfo.version;
    });
  }

  Future<void> checkUpdate() async {
    try {
      // GitHub’dagi versiya.json ni olish
      var response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/uzb-coder/versiya/master/versiya.json'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        latestVersion = data['version'];
        apkUrl = data['apk_url'];

        if (latestVersion != currentVersion) {
          // Dialog chiqarish
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Yangilanish mavjud'),
              content: Text(
                  'Yangi versiya $latestVersion mavjud. Yuklab olishni xohlaysizmi?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    downloadAndUpdate(apkUrl);
                  },
                  child: const Text('Ha'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Yo‘q'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ Sizning versiyangiz yangilangan')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('❌ Yangilanishni tekshirib bo‘lmadi')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Xato: ${e.toString()}')));
    }
  }

  Future<void> downloadAndUpdate(String url) async {
    try {
      // APK ni yuklab olish
      var response = await http.get(Uri.parse(url));
      Directory tempDir = await getTemporaryDirectory();
      File file = File('${tempDir.path}/update.apk');
      await file.writeAsBytes(response.bodyBytes);

      // O‘rnatish oynasini ochish
      await OpenFilex.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Yuklab olishda xato: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bu dastur birinchi versiyasi')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📱 Joriy versiya: $currentVersion'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: checkUpdate,
              child: const Text('Yangilanishni tekshirish'),
            ),
          ],
        ),
      ),
    );
  }
}
