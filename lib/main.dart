import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    checkUpdateFromGitHub();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }

  // ================= UPDATE CHECK =================

  Future<void> checkUpdateFromGitHub() async {
    const owner = 'uzb-coder'; // 👈 GitHub username
    const repo = 'example'; // 👈 Repo nomi

    final url = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/releases/latest',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      // ✅ GitHub API da oxirgi release tag shunday olinadi:
      final latestTag = data['tag_name']; // masalan: "v1.0.0"
      final latestVersion = latestTag.replaceAll('v', '');

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      if (latestVersion != currentVersion) {
        final asset = data['assets'][0];
        final downloadUrl = asset['browser_download_url'];

        showUpdateDialog(latestVersion, downloadUrl);
      }
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  // ================= DIALOG =================

  void showUpdateDialog(String version, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Yangi versiya mavjud"),
        content: Text("Yangi versiya: $version"),
        actions: [
          TextButton(
            onPressed: () {
              startUpdate(url);
            },
            child: const Text("Yangilash"),
          ),
        ],
      ),
    );
  }

  // ================= DOWNLOAD =================

  Future<void> startUpdate(String url) async {
    Navigator.pop(context);

    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/update.zip';

    final response = await http.get(Uri.parse(url));
    await File(zipPath).writeAsBytes(response.bodyBytes);

    await runUpdater(zipPath);
  }

  // ================= RUN UPDATER =================

  Future<void> runUpdater(String zipPath) async {
    final exePath = Platform.resolvedExecutable;
    final appDir = File(exePath).parent.path;

    final updaterPath = '$appDir/updater.exe';

    await Process.start(updaterPath, [zipPath, appDir], runInShell: true);

    exit(0); // Flutter app yopiladi
  }
}

// ================= UI =================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Flutter GitHub Auto Update",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
