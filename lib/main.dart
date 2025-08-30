import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
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
  double progress = 0;

  @override
  void initState() {
    super.initState();
    loadCurrentVersion();
  }

  Future<void> loadCurrentVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        currentVersion = packageInfo.version;
      });
    } catch (e, st) {
      print("❌ Versiyani olishda xato: $e");
      print(st);
    }
  }

  Future<void> checkUpdate() async {
    try {
      var response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/uzb-coder/versiya/master/versiya.json'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        latestVersion = data['version'];
        apkUrl = data['apk_url'];

        print("📥 JSON yuklandi: versiya=$latestVersion, url=$apkUrl");

        if (latestVersion != currentVersion) {
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
        print("❌ JSON yuklanmadi. Status code: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('❌ Yangilanishni tekshirib bo‘lmadi')));
      }
    } catch (e, st) {
      print("❌ checkUpdate() xato: $e");
      print(st);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Xato: ${e.toString()}')));
    }
  }

  Future<void> downloadAndUpdate(String url) async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      String filePath = '${tempDir.path}/update.apk';

      Dio dio = Dio();

      setState(() {
        progress = 0;
      });

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              progress = received / total;
            });
            print("📊 Yuklanmoqda: $received / $total");
          }
        },
      );

      setState(() {
        progress = 1;
      });

      print("✅ APK yuklab olindi: $filePath");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Yuklab olindi, o‘rnatish ochilmoqda...')),
      );

      // 🔹 APK ni ochish (FileProvider orqali content:// URI bo‘ladi)
      await OpenFilex.open(filePath);
    } catch (e, st) {
      print("❌ downloadAndUpdate() xato: $e");
      print(st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Yuklab olishda xato: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📲 Bu 3 versiya boladi'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return const AlertDialog(
                    title: Text("Salom alaykum"),
                  );
                },
              );
            },
            icon: const Icon(Icons.access_alarms_sharp),
          )
        ],

        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '📱 Joriy versiya: $currentVersion',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              // Progress indikator
              if (progress > 0 && progress < 1)
                Column(
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 10),
                    Text('${(progress * 100).toStringAsFixed(0)}% yuklanyapti...'),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: checkUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.system_update),
                  label: const Text(
                    'Yangilanishni tekshirish',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
